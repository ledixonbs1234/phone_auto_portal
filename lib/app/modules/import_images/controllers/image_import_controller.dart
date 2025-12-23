import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform, File;
import 'package:phone_auto_portal/app/modules/import_images/models/image_batch_model.dart';
import 'package:phone_auto_portal/app/modules/import_images/models/image_item_model.dart';
import 'package:phone_auto_portal/app/modules/import_images/services/image_batch_service.dart';
import 'package:phone_auto_portal/app/modules/import_images/services/image_processing_service.dart';
import 'package:phone_auto_portal/app/modules/import_images/services/barcode_ocr_service.dart';
import 'package:phone_auto_portal/app/modules/import_images/services/image_upload_service.dart';
import 'package:phone_auto_portal/data/exceptions/telegram_exceptions.dart';
import 'package:phone_auto_portal/data/image_cache_service.dart';

// Safe logging function that only prints in debug mode
void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

class ImageImportController extends GetxController {
  // Services
  final ImageBatchService _batchService = ImageBatchService();
  final ImageProcessingService _processingService = ImageProcessingService();
  final BarcodeOcrService _ocrService = BarcodeOcrService();
  final ImageUploadService _uploadService = ImageUploadService();

  // Observable state
  final batches = <ImageBatch>[].obs;
  final isLoading = false.obs;
  final statusMessage = ''.obs;
  final totalProgress = 0.0.obs;

  // Statistics
  final totalImages = 0.obs;
  final selectedTotalImages = 0.obs; // Tổng số ảnh của các batch đã chọn
  final processedImages = 0.obs;
  final successImages = 0.obs;
  final errorImages = 0.obs;

  @override
  void onClose() {
    _processingService.dispose();
    _ocrService.dispose();
    super.onClose();
  }

  /// Chọn ảnh và tạo batch (từ image picker)
  Future<void> loadImages() async {
    try {
      isLoading.value = true;
      statusMessage.value = 'Đang tải ảnh...';

      // Reset state cũ trước khi load mới
      reset();

      final loadedBatches = await _batchService.loadAndCreateBatches();

      if (loadedBatches.isEmpty) {
        // Đảm bảo xóa hết batch cũ
        batches.clear();
        totalImages.value = 0;

        Get.snackbar(
          'Thông báo',
          'Không có ảnh nào được chọn hoặc không có ảnh hôm nay',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      batches.value = loadedBatches;
      totalImages.value = _batchService.getTotalImagesCount(loadedBatches);

      statusMessage.value =
          'Đã tải ${batches.length} batch (${totalImages.value} ảnh)';

      Get.snackbar(
        'Thành công',
        'Đã tải ${batches.length} batch với ${totalImages.value} ảnh',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Reset khi có lỗi để tránh giữ state cũ
      batches.clear();
      totalImages.value = 0;

      statusMessage.value = 'Lỗi: $e';
      Get.snackbar(
        'Lỗi',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Lấy ảnh từ thư mục đã chọn và tạo batch
  Future<void> loadImagesFromFolders() async {
    try {
      isLoading.value = true;
      statusMessage.value = 'Đang kiểm tra quyền truy cập...';

      // Request storage permission trên Android
      if (Platform.isAndroid) {
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission) {
          Get.snackbar(
            'Cần quyền truy cập',
            'Vui lòng cấp quyền truy cập ảnh để tiếp tục',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
          return;
        }
      }

      statusMessage.value = 'Đang quét thư mục...';

      // Reset state cũ trước khi load mới
      reset();

      final loadedBatches =
          await _batchService.loadImagesFromFoldersAndCreateBatches();

      if (loadedBatches.isEmpty) {
        // Đảm bảo xóa hết batch cũ
        batches.clear();
        totalImages.value = 0;

        Get.snackbar(
          'Thông báo',
          'Không có ảnh nào trong thư mục đã chọn',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      batches.value = loadedBatches;
      totalImages.value = _batchService.getTotalImagesCount(loadedBatches);

      statusMessage.value =
          'Đã tải ${batches.length} batch (${totalImages.value} ảnh)';
    } catch (e) {
      // Reset khi có lỗi để tránh giữ state cũ
      batches.clear();
      totalImages.value = 0;

      statusMessage.value = 'Lỗi: $e';
      Get.snackbar(
        'Lỗi',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Request storage permission cho Android
  Future<bool> _requestStoragePermission() async {
    try {
      // Android 13+ (API 33+) cần quyền READ_MEDIA_IMAGES
      if (await Permission.photos.isGranted) {
        return true;
      }

      // Kiểm tra quyền storage cũ cho Android < 13
      if (await Permission.storage.isGranted) {
        return true;
      }

      // Request quyền mới (Android 13+)
      var status = await Permission.photos.request();
      if (status.isGranted) {
        return true;
      }

      // Fallback: request quyền cũ (Android < 13)
      status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }

      // Nếu bị permanently denied, mở settings
      if (status.isPermanentlyDenied) {
        final opened = await openAppSettings();
        if (opened) {
          Get.snackbar(
            'Hướng dẫn',
            'Vui lòng bật quyền truy cập ảnh trong Settings rồi thử lại',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
        }
      }

      return false;
    } catch (e) {
      _debugLog('Lỗi khi request permission: $e');
      return false;
    }
  }

  /// Toggle chọn batch
  void toggleBatchSelection(int index) {
    if (index >= 0 && index < batches.length) {
      batches[index] = batches[index].copyWith(
        isSelected: !batches[index].isSelected,
      );
      batches.refresh();
    }
  }

  /// Chọn tất cả batch
  void selectAllBatches() {
    batches.value =
        batches.map((batch) => batch.copyWith(isSelected: true)).toList();
  }

  /// Bỏ chọn tất cả batch
  void deselectAllBatches() {
    batches.value =
        batches.map((batch) => batch.copyWith(isSelected: false)).toList();
  }

  /// Xử lý và upload các batch đã chọn
  Future<void> processSelectedBatches() async {
    final selectedBatchIndexes = <int>[];

    // Lưu index thay vì object để tránh lỗi indexOf
    for (int i = 0; i < batches.length; i++) {
      if (batches[i].isSelected) {
        selectedBatchIndexes.add(i);
      }
    }

    if (selectedBatchIndexes.isEmpty) {
      Get.snackbar(
        'Thông báo',
        'Vui lòng chọn ít nhất 1 batch để xử lý',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      processedImages.value = 0;
      successImages.value = 0;
      errorImages.value = 0;

      // Tính tổng số ảnh của các batch đã chọn
      selectedTotalImages.value = selectedBatchIndexes.fold<int>(
        0,
        (sum, index) => sum + batches[index].totalImages,
      );

      // Xóa tất cả ảnh cũ trước khi upload batch mới
      statusMessage.value = 'Đang xóa ảnh cũ...';
      await _uploadService.clearOldImages();

      for (var batchIndex in selectedBatchIndexes) {
        await _processBatch(batchIndex);
      }

      statusMessage.value =
          'Hoàn thành! Thành công: ${successImages.value}, Lỗi: ${errorImages.value}';

      Get.snackbar(
        'Hoàn thành',
        'Đã xử lý ${processedImages.value} ảnh\nThành công: ${successImages.value}, Lỗi: ${errorImages.value}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } on TelegramConfigMissingException catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Lỗi Cấu Hình'),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      statusMessage.value = 'Thiếu cấu hình Telegram';
    } on TelegramBatchUploadFailedException catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Upload Thất Bại'),
          content: Text('${e.message}\n\nTất cả thay đổi đã được hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      statusMessage.value = 'Upload thất bại và đã rollback';
    } on TelegramInvalidTokenException catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Lỗi Token'),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      statusMessage.value = 'Token Telegram không hợp lệ';
    } on TelegramChatNotFoundException catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Lỗi Chat'),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      statusMessage.value = 'Không tìm thấy chat Telegram';
    } on TelegramFileTooLargeException catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('File Quá Lớn'),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      statusMessage.value = 'File ảnh quá lớn';
    } on TelegramApiException catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Lỗi Telegram API'),
          content: Text('${e.message}\n\nStatus: ${e.statusCode}'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      statusMessage.value = 'Lỗi Telegram API';
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      statusMessage.value = 'Lỗi: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Xử lý một batch: Process images then upload in concurrent batches
  Future<void> _processBatch(int batchIndex) async {
    final batch = batches[batchIndex];

    // Cập nhật status
    batches[batchIndex] = batch.copyWith(status: BatchStatus.processing);
    batches.refresh();

    // Step 1: Process all images (check cache first, rotate + OCR only if needed)
    final processedImages = <ImageItem>[];
    final tempFilesToDelete = <File>[];

    for (int i = 0; i < batch.images.length; i++) {
      try {
        final image = batch.images[i];
        final fileName = image.originalFile.path.split('/').last;
        final progress = '${i + 1}/${batch.images.length}';

        // BƯỚC 0: Kiểm tra cache TRƯỚC KHI rotate
        statusMessage.value = '[$progress] 🔍 Kiểm tra cache: $fileName';

        batch.images[i] =
            image.copyWith(status: ImageProcessingStatus.rotating);
        batches.refresh();

        final cachedCompressed =
            await ImageCacheService.instance.getMetadata(image.originalFile);

        File processedFile;
        int rotationAngle = 0;
        String? maHieu;

        if (cachedCompressed != null) {
          // ✅ CÓ METADATA - Dùng file compressed và mã hiệu đã lưu
          statusMessage.value =
              '[$progress] ✅ Tìm thấy: ${cachedCompressed.maHieu ?? "no maHieu"}';
          _debugLog('✅ Metadata found! MaHieu: ${cachedCompressed.maHieu}');

          processedFile = File(cachedCompressed.compressedPath);
          maHieu = cachedCompressed.maHieu;
          rotationAngle = 0; // Already rotated

          // Delay nhỏ để user thấy message
          await Future.delayed(const Duration(milliseconds: 200));
        } else {
          // ❌ CHƯA CÓ METADATA - Phải rotate, OCR và compress
          statusMessage.value = '[$progress] ⚙️ Chưa xử lý, bắt đầu...';
          _debugLog('❌ No metadata. Processing: ${image.originalFile.path}');

          // BƯỚC 1: Rotate
          statusMessage.value = '[$progress] 🔄 Đang xoay ảnh: $fileName';

          final processedResult =
              await _processingService.processImage(image.originalFile);

          if (!processedResult.isSuccess) {
            throw Exception(processedResult.errorMessage ?? 'Lỗi xử lý ảnh');
          }

          final rotatedFile = processedResult.file;
          rotationAngle = processedResult.rotationAngle;

          // Lưu file rotated để xóa SAU
          tempFilesToDelete.addAll(processedResult.tempFiles);

          // BƯỚC 2: OCR để đọc mã hiệu
          batch.images[i] = image.copyWith(
            status: ImageProcessingStatus.readingBarcode,
            rotationAngle: rotationAngle,
          );
          batches.refresh();

          statusMessage.value = '[$progress] 📖 Đang đọc mã hiệu: $fileName';

          final maHieuResult = await _ocrService.readMaHieu(rotatedFile);
          maHieu = maHieuResult.maHieu;

          statusMessage.value = '[$progress] 🗜️ Đang nén và lưu: $fileName';

          // BƯỚC 3: Compress và lưu metadata
          final savedQuality = GetStorage().read<int>('compress_quality') ?? ImageCacheService.defaultQuality;
          final savedMetadata = await ImageCacheService.instance.processAndSave(
            originalFile: image.originalFile,
            rotatedFile: rotatedFile,
            maHieu: maHieu,
            rotationAngle: rotationAngle,
            quality: savedQuality,
          );

          processedFile = File(savedMetadata.compressedPath);
        }

        // Update image với kết quả (dù có metadata hay không)
        final processedImage = image.copyWith(
          file: processedFile,
          maHieu: maHieu,
          rotationAngle: rotationAngle,
          status: ImageProcessingStatus.uploading,
        );

        batch.images[i] = processedImage;
        processedImages.add(processedImage);
        batches.refresh();

        this.processedImages.value++;
      } catch (e) {
        batch.images[i] = batch.images[i].copyWith(
          status: ImageProcessingStatus.error,
          errorMessage: e.toString(),
        );
        errorImages.value++;
        batches.refresh();
      }
    }

    // Step 2: Upload all processed images as media groups
    if (processedImages.isNotEmpty) {
      try {
        final total = processedImages.length;
        statusMessage.value = '📤 Chuẩn bị upload $total ảnh lên Telegram...';
        await Future.delayed(const Duration(milliseconds: 300));

        final uploadResult = await _uploadService.uploadImagesInBatches(
          images: processedImages,
          batchId: batch.id,
          onProgress: (current, total, status) {
            // Callback từ upload service để cập nhật progress
            statusMessage.value = '📤 $status ($current/$total)';
          },
        );

        // Update success count
        successImages.value += uploadResult.successCount;
        errorImages.value += uploadResult.failCount;

        statusMessage.value =
            '✅ Hoàn thành upload ${uploadResult.successCount}/$total ảnh';
        await Future.delayed(const Duration(milliseconds: 500));

        // Update all images status to completed
        for (var processedImage in processedImages) {
          final index =
              batch.images.indexWhere((img) => img.id == processedImage.id);
          if (index != -1) {
            batch.images[index] = batch.images[index].copyWith(
              status: ImageProcessingStatus.completed,
              uploadProgress: 1.0,
            );
          }
        }

        batches.refresh();
      } catch (e) {
        // Upload failed - re-throw to propagate error to processSelectedBatches
        rethrow;
      } finally {
        // QUAN TRỌNG: Xóa file rotated tạm trong finally
        // Step 3: Cleanup temp rotated files SAU KHI UPLOAD XONG
        // TelegramService đã tạo cache compressed từ file rotated này rồi
        if (tempFilesToDelete.isNotEmpty) {
          statusMessage.value =
              '🗑️ Dọn dẹp ${tempFilesToDelete.length} file tạm...';
          _debugLog(
              '🗑️ Cleaning up ${tempFilesToDelete.length} temp rotated files...');

          for (var tempFile in tempFilesToDelete) {
            try {
              if (await tempFile.exists()) {
                await tempFile.delete();
                _debugLog('✅ Đã xóa file rotated tạm: ${tempFile.path}');
              }
            } catch (deleteError) {
              _debugLog('⚠️ Không thể xóa file rotated tạm: $deleteError');
            }
          }

          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    }

    // Cập nhật batch progress
    statusMessage.value = '📊 Cập nhật thông tin batch...';
    final updatedBatch = batches[batchIndex];
    updatedBatch.updateProgress();
    batches[batchIndex] = updatedBatch;
    batches.refresh();

    // Upload batch metadata
    await _uploadService.uploadBatchMetadata(
      batchId: updatedBatch.id,
      startTime: updatedBatch.startTime,
      endTime: updatedBatch.endTime,
      totalImages: updatedBatch.totalImages,
      processedImages: updatedBatch.processedCount,
    );

    statusMessage.value = '✅ Hoàn tất xử lý batch!';
  }

  /// Xử lý một ảnh: Rotate -> OCR -> Upload (for retry functionality)
  Future<void> _processImage(int batchIndex, int imageIndex) async {
    final batch = batches[batchIndex];
    final image = batch.images[imageIndex];
    List<File> tempFilesToDelete = [];

    try {
      statusMessage.value =
          'Đang xử lý ${image.originalFile.path.split('/').last}...';

      // 1. Xoay và compress ảnh (LUÔN dùng originalFile)
      batch.images[imageIndex] =
          image.copyWith(status: ImageProcessingStatus.rotating);
      batches.refresh();

      final processedResult =
          await _processingService.processImage(image.originalFile);

      if (!processedResult.isSuccess) {
        throw Exception(processedResult.errorMessage ?? 'Lỗi xử lý ảnh');
      }

      // Lưu danh sách file tạm để xóa sau
      tempFilesToDelete = processedResult.tempFiles;

      // 2. Đọc mã hiệu
      batch.images[imageIndex] = image.copyWith(
        status: ImageProcessingStatus.readingBarcode,
        rotationAngle: processedResult.rotationAngle,
      );
      batches.refresh();

      final maHieuResult = await _ocrService.readMaHieu(processedResult.file);

      // 3. Upload lên Telegram (no progress callback, indeterminate progress)
      batch.images[imageIndex] = image.copyWith(
        status: ImageProcessingStatus.uploading,
        maHieu: maHieuResult.maHieu,
      );
      batches.refresh();

      final uploadResult = await _uploadService.uploadImageWithMetadata(
        imageItem: image.copyWith(
          file: processedResult.file, // Upload file đã xoay MỚI
          maHieu: maHieuResult.maHieu,
          rotationAngle: processedResult.rotationAngle,
        ),
        batchId: batch.id,
      );

      if (!uploadResult.isSuccess) {
        throw Exception(uploadResult.errorMessage ?? 'Lỗi upload');
      }

      // 4. Xóa file rotated tạm sau khi upload thành công
      // TelegramService đã tạo cache compressed từ file rotated này rồi
      for (var tempFile in tempFilesToDelete) {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
            _debugLog('✅ Đã xóa file rotated tạm: ${tempFile.path}');
          }
        } catch (e) {
          _debugLog('⚠️ Không thể xóa file rotated tạm ${tempFile.path}: $e');
        }
      }

      // 5. Cập nhật thành công
      batch.images[imageIndex] = image.copyWith(
        file: processedResult.file, // Cập nhật file rotated mới
        status: ImageProcessingStatus.completed,
        firebaseUrl: uploadResult.downloadUrl,
        maHieu: maHieuResult.maHieu,
        rotationAngle: processedResult.rotationAngle,
        uploadProgress: 1.0,
      );

      successImages.value++;
    } catch (e) {
      // Xóa file rotated tạm ngay cả khi có lỗi
      for (var tempFile in tempFilesToDelete) {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (deleteError) {
          _debugLog('⚠️ Không thể xóa file rotated tạm: $deleteError');
        }
      }

      // Cập nhật lỗi
      batch.images[imageIndex] = image.copyWith(
        status: ImageProcessingStatus.error,
        errorMessage: e.toString(),
      );

      errorImages.value++;
    } finally {
      processedImages.value++;
      totalProgress.value = selectedTotalImages.value > 0
          ? processedImages.value / selectedTotalImages.value
          : 0.0;

      batches[batchIndex] = batch;
      batches.refresh();
    }
  }

  /// Retry ảnh lỗi trong batch
  Future<void> retryErrorImages(ImageBatch batch) async {
    // Tìm index của batch trong list
    final batchIndex = batches.indexWhere((b) => b.id == batch.id);
    if (batchIndex == -1) {
      Get.snackbar('Lỗi', 'Không tìm thấy batch');
      return;
    }

    final errorIndexes = <int>[];

    for (int i = 0; i < batches[batchIndex].images.length; i++) {
      if (batches[batchIndex].images[i].hasError) {
        errorIndexes.add(i);
      }
    }

    if (errorIndexes.isEmpty) {
      Get.snackbar('Thông báo', 'Không có ảnh lỗi để retry');
      return;
    }

    isLoading.value = true;

    for (var index in errorIndexes) {
      await _processImage(batchIndex, index);
    }

    isLoading.value = false;
  }

  /// Xóa batch
  void deleteBatch(int index) {
    if (index >= 0 && index < batches.length) {
      batches.removeAt(index);
      totalImages.value = _batchService.getTotalImagesCount(batches);
    }
  }

  /// Reset tất cả
  void reset() {
    batches.clear();
    totalImages.value = 0;
    selectedTotalImages.value = 0;
    processedImages.value = 0;
    successImages.value = 0;
    errorImages.value = 0;
    totalProgress.value = 0.0;
    statusMessage.value = '';
  }
}
