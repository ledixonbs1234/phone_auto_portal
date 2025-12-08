import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:phone_auto_portal/app/modules/import_images/models/image_item_model.dart';

// Safe logging function that only prints in debug mode
void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

/// Service upload ảnh lên Firebase Storage và sync metadata với Realtime Database
class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Lấy rootPath giống firebaseManager
  DatabaseReference get rootPath {
    final keyData = GetStorage().read('key') ?? "maychu";
    return _database.child("PORTAL/CHILD/$keyData");
  }

  /// Upload ảnh lên Firebase Storage
  Future<String> uploadImageToStorage(
    File imageFile,
    String batchId,
    String imageId,
    Function(double)? onProgress,
  ) async {
    try {
      // Tạo đường dẫn: images/{date}/{batch_id}/{image_id}.jpg
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final fileName = '$imageId.jpg';
      final storagePath = 'images/$dateStr/$batchId/$fileName';

      // Reference đến file trong Storage
      final storageRef = _storage.ref().child(storagePath);

      // Upload file với metadata
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'batchId': batchId,
            'uploadTime': now.toIso8601String(),
          },
        ),
      );

      // Listen upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Đợi upload hoàn thành
      final snapshot = await uploadTask;

      // Lấy download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Lỗi khi upload ảnh: $e');
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
    required String? maHieu,
    required DateTime timestamp,
  }) async {
    try {
      // Path đơn giản: PORTAL/CHILD/{keyData}/imported_images/{image_id}
      final dbRef = rootPath.child('imported_images').child(imageId);

      await dbRef.set({
        'url': downloadUrl,
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

  /// Workflow hoàn chỉnh: Upload ảnh + metadata
  Future<UploadResult> uploadImageWithMetadata({
    required ImageItem imageItem,
    required String batchId,
    Function(double)? onProgress,
  }) async {
    try {
      // 1. Upload ảnh lên Storage
      final downloadUrl = await uploadImageToStorage(
        imageItem.file,
        batchId,
        imageItem.id,
        onProgress,
      );

      // 2. Lưu metadata vào Database
      await saveImageMetadata(
        batchId: batchId,
        imageId: imageItem.id,
        downloadUrl: downloadUrl,
        maHieu: imageItem.maHieu,
        timestamp: imageItem.timestamp,
      );

      return UploadResult(
        isSuccess: true,
        downloadUrl: downloadUrl,
      );
    } catch (e) {
      return UploadResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Xóa ảnh từ Storage (nếu cần retry)
  Future<void> deleteImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      _debugLog('Lỗi khi xóa ảnh: $e');
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
