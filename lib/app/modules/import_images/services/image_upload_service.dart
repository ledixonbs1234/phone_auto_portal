import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:phone_auto_portal/app/modules/import_images/models/image_item_model.dart';
import 'package:phone_auto_portal/data/telegram_service.dart';
import 'package:phone_auto_portal/data/exceptions/telegram_exceptions.dart';

// Safe logging function that only prints in debug mode
void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

/// Service upload ảnh lên Telegram Bot API và sync metadata với Realtime Database
class ImageUploadService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Lấy rootPath giống firebaseManager
  DatabaseReference get rootPath {
    final keyData = GetStorage().read('key') ?? "maychu";
    return _database.child("PORTAL/CHILD/$keyData");
  }

  /// Upload nhiều ảnh lên Telegram Bot API dùng Media Group
  ///
  /// LUỒNG HOẠT ĐỘNG:
  /// 1️⃣ CHIA NHÓM: Chia ảnh thành các nhóm nhỏ (tối đa 10 ảnh/nhóm theo giới hạn Telegram)
  /// 2️⃣ UPLOAD VỚI RETRY: Cho mỗi nhóm:
  ///    - Upload lên Telegram (tối đa 3 lần thử nếu lỗi)
  ///    - Chờ exponential backoff trước mỗi lần retry (1s, 2s, 3s)
  ///    - Gọi callback [onProgress] để cập nhật UI
  /// 3️⃣ LƯU METADATA: Sau khi upload thành công, lưu metadata vào Firebase Realtime DB:
  ///    - URL ảnh, thumbnailUrl, mã hiệu, timestamp...
  ///    - Lưu imageId vào danh sách [successfulImageIds] để tracking
  /// 4️⃣ ROLLBACK NẾU LỖI: Nếu upload toàn bộ thất bại:
  ///    - Xóa metadata của tất cả ảnh đã upload thành công
  ///    - Ném exception [TelegramBatchUploadFailedException]
  ///    - Điều này đảm bảo data integrity (không có ảnh orphan)
  ///
  /// RETRY MECHANISM:
  /// - Mỗi nhóm ảnh có tối đa 3 lần thử
  /// - Nếu lần thứ 3 vẫn lỗi → fail toàn bộ batch (không tiếp tục nhóm tiếp theo)
  /// - Exponential backoff: delay = số lần retry hiện tại (1s, 2s, 3s)
  ///
  /// TRACKING:
  /// - [successfulImageIds]: Danh sách ID ảnh đã upload thành công (dùng cho rollback)
  /// - [onProgress]: Callback để UI theo dõi tiến độ upload từng nhóm
  ///
  /// RETURN:
  /// - [BatchUploadResult]: Chứa số ảnh thành công/thất bại
  ///
  /// THROWS:
  /// - [TelegramBatchUploadFailedException]: Nếu upload thất bại + rollback xong
  Future<BatchUploadResult> uploadImagesInBatches({
    required List<ImageItem> images,
    required String batchId,
    Function(int current, int total, String status)? onProgress,
  }) async {
    // Theo dõi ID ảnh đã upload thành công để rollback nếu cần
    final List<String> successfulImageIds = [];
    int successCount = 0;
    int failCount = 0;
    const maxRetries = 3;
    const maxImagesPerGroup = 10; // Giới hạn Media Group của Telegram

    try {
      // 1️⃣ CHIA NHÓM: Split images into groups of 10 (Telegram Media Group limit)
      for (int groupStart = 0;
          groupStart < images.length;
          groupStart += maxImagesPerGroup) {
        final groupEnd =
            (groupStart + maxImagesPerGroup).clamp(0, images.length);
        final imageGroup = images.sublist(groupStart, groupEnd);
        final groupNumber = (groupStart ~/ maxImagesPerGroup) + 1;
        final totalGroups = (images.length / maxImagesPerGroup).ceil();

        _debugLog(
            '📤 Uploading media group $groupNumber/$totalGroups: ${imageGroup.length} images (${groupStart + 1}-$groupEnd of ${images.length})');

        onProgress?.call(groupStart, images.length,
            'Đang upload nhóm $groupNumber/$totalGroups');

        bool uploadSuccess = false;
        int retryCount = 0;
        List<Map<String, String>>? downloadUrls;
        Exception? lastException;

        // 2️⃣ RETRY LOOP: Thử upload nhóm này tối đa 3 lần
        while (retryCount < maxRetries && !uploadSuccess) {
          try {
            // Nếu này không phải lần đầu, chờ exponential backoff
            if (retryCount > 0) {
              _debugLog(
                  '🔄 Retry ${retryCount}/$maxRetries for media group $groupNumber');
              onProgress?.call(groupStart, images.length,
                  'Thử lại lần $retryCount nhóm $groupNumber/$totalGroups');
              // Exponential backoff: chờ (retryCount) giây
              await Future.delayed(Duration(seconds: retryCount));
            }

            // 🚀 Upload nhóm ảnh lên Telegram
            onProgress?.call(groupStart, images.length,
                'Upload nhóm $groupNumber/$totalGroups (${imageGroup.length} ảnh)');

            downloadUrls =
                await TelegramService.instance.uploadMediaGroup(imageGroup);

            // 💾 LƯU METADATA: Lưu thông tin mỗi ảnh vào Firebase Realtime DB
            onProgress?.call(groupStart, images.length,
                'Lưu metadata nhóm $groupNumber/$totalGroups');

            for (int i = 0; i < imageGroup.length; i++) {
              final imageItem = imageGroup[i];
              final urlMap = downloadUrls[i];

              // Lưu metadata vào database
              await saveImageMetadata(
                batchId: batchId,
                imageId: imageItem.id,
                downloadUrl: urlMap['downloadUrl']!,
                thumbnailUrl: urlMap['thumbnailUrl']!,
                maHieu: imageItem.maHieu,
                timestamp: imageItem.timestamp,
              );

              // Ghi nhận ảnh đã upload thành công (để rollback sau nếu cần)
              successfulImageIds.add(imageItem.id);
              successCount++;
              _debugLog('✅ Uploaded image: ${imageItem.id}');
            }

            uploadSuccess = true;
            _debugLog(
                '✅ Media group $groupNumber/$totalGroups uploaded successfully');

            onProgress?.call(groupEnd, images.length,
                'Hoàn thành nhóm $groupNumber/$totalGroups');
          } catch (e) {
            retryCount++;
            lastException = e is Exception ? e : Exception(e.toString());
            _debugLog(
                '❌ Media group upload failed (attempt $retryCount/$maxRetries): $e');

            // Nếu vượt quá số lần retry → fail toàn bộ batch
            if (retryCount >= maxRetries) {
              failCount += imageGroup.length;
              _debugLog('❌ Max retries reached for media group');
              throw lastException;
            }
          }
        }
      }

      // ✅ TẤT CẢ UPLOAD THÀNH CÔNG
      return BatchUploadResult(
        isSuccess: true,
        successCount: successCount,
        failCount: 0,
        totalCount: images.length,
      );
    } catch (e) {
      // ❌ UPLOAD THẤT BẠI → ROLLBACK
      _debugLog(
          '❌ Batch upload failed. Rolling back ${successfulImageIds.length} uploaded images...');

      // 🔙 XÓA METADATA của tất cả ảnh đã upload (rollback to maintain data integrity)
      await _rollbackUploadedImages(successfulImageIds);

      // ⚠️ Ném exception với danh sách ảnh đã được rollback
      throw TelegramBatchUploadFailedException(
        message:
            'Upload thất bại sau $maxRetries lần thử. Đã dừng xử lý và xóa ${successfulImageIds.length} ảnh đã upload.',
        successfulImageIds: successfulImageIds,
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Rollback uploaded images by deleting their metadata from database
  Future<void> _rollbackUploadedImages(List<String> imageIds) async {
    for (final imageId in imageIds) {
      try {
        await rootPath.child('imported_images').child(imageId).remove();
        _debugLog('🗑️ Rolled back image: $imageId');
      } catch (e) {
        // Silently ignore rollback errors
        _debugLog('⚠️ Failed to rollback image $imageId: $e');
      }
    }
  }

  /// Xóa tất cả ảnh cũ trong Realtime Database
  Future<void> clearOldImages() async {
    try {
      final dbRef = rootPath.child('imported_images');
      await dbRef.remove();
      _debugLog('🗑️ Đã xóa tất cả ảnh cũ trên Realtime Database');
    } catch (e) {
      _debugLog('⚠️ Lỗi khi xóa ảnh cũ: $e');
    }
  }

  /// Lưu metadata vào Realtime Database (không chia batch, path đơn giản)
  Future<void> saveImageMetadata({
    required String batchId,
    required String imageId,
    required String downloadUrl,
    required String thumbnailUrl,
    required String? maHieu,
    required DateTime timestamp,
  }) async {
    try {
      // Path đơn giản: PORTAL/CHILD/{keyData}/imported_images/{image_id}
      final dbRef = rootPath.child('imported_images').child(imageId);

      await dbRef.set({
        'url': downloadUrl,
        'thumbnailUrl': thumbnailUrl,
        'maHieu': maHieu ?? '',
        'timestamp': timestamp.millisecondsSinceEpoch,
        'processed': maHieu != null,
        'uploadedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Lỗi khi lưu metadata: $e');
    }
  }

  /// Cập nhật mã hiệu sau khi đọc được
  Future<void> updateMaHieu({
    required String batchId,
    required String imageId,
    required String maHieu,
    required DateTime timestamp,
  }) async {
    try {
      final dbRef = rootPath.child('imported_images').child(imageId);

      await dbRef.update({
        'maHieu': maHieu,
        'processed': true,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      _debugLog('Lỗi khi cập nhật mã hiệu: $e');
    }
  }

  /// Upload batch metadata (tổng hợp thông tin batch)
  Future<void> uploadBatchMetadata({
    required String batchId,
    required DateTime startTime,
    required DateTime endTime,
    required int totalImages,
    required int processedImages,
  }) async {
    try {
      // Lưu thông tin tổng quan của lần upload
      final dbRef = rootPath.child('imported_images_summary');

      await dbRef.set({
        'lastUploadTime': DateTime.now().millisecondsSinceEpoch,
        'totalImages': totalImages,
        'processedImages': processedImages,
        'status': processedImages == totalImages ? 'completed' : 'processing',
      });
    } catch (e) {
      _debugLog('Lỗi khi upload batch metadata: $e');
    }
  }

  /// Workflow hoàn chỉnh: Upload ảnh + metadata (kept for backward compatibility)
  Future<UploadResult> uploadImageWithMetadata({
    required ImageItem imageItem,
    required String batchId,
    Function(double)? onProgress,
  }) async {
    try {
      // Upload to Telegram (truyền ImageItem để dùng originalFile làm cache key)
      final urlMap = await TelegramService.instance.uploadImage(imageItem);

      // Save metadata to database
      await saveImageMetadata(
        batchId: batchId,
        imageId: imageItem.id,
        downloadUrl: urlMap['downloadUrl']!,
        thumbnailUrl: urlMap['thumbnailUrl']!,
        maHieu: imageItem.maHieu,
        timestamp: imageItem.timestamp,
      );

      return UploadResult(
        isSuccess: true,
        downloadUrl: urlMap['downloadUrl']!,
      );
    } catch (e) {
      return UploadResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Xóa ảnh metadata từ Database (Telegram URLs không cần xóa khỏi storage)
  Future<void> deleteImage(String imageId) async {
    try {
      await rootPath.child('imported_images').child(imageId).remove();
    } catch (e) {
      _debugLog('Lỗi khi xóa metadata ảnh: $e');
    }
  }

  /// Lấy danh sách ảnh đã upload theo ngày
  Future<List<Map<String, dynamic>>> getUploadedImages(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final snapshot =
          await _database.child('imported_images').child(dateStr).get();

      if (!snapshot.exists) {
        return [];
      }

      final List<Map<String, dynamic>> images = [];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((batchId, batchData) {
        final batch = batchData as Map<dynamic, dynamic>;
        batch.forEach((imageId, imageData) {
          images.add({
            'batchId': batchId,
            'imageId': imageId,
            ...Map<String, dynamic>.from(imageData as Map),
          });
        });
      });

      return images;
    } catch (e) {
      _debugLog('Lỗi khi lấy danh sách ảnh: $e');
      return [];
    }
  }
}

/// Kết quả upload
class UploadResult {
  final bool isSuccess;
  final String? downloadUrl;
  final String? errorMessage;

  UploadResult({
    required this.isSuccess,
    this.downloadUrl,
    this.errorMessage,
  });
}

/// Kết quả batch upload
class BatchUploadResult {
  final bool isSuccess;
  final int successCount;
  final int failCount;
  final int totalCount;

  BatchUploadResult({
    required this.isSuccess,
    required this.successCount,
    required this.failCount,
    required this.totalCount,
  });
}
