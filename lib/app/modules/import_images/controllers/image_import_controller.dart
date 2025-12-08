import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform, File;
import 'package:phone_auto_portal/app/modules/import_images/models/image_batch_model.dart';
import 'package:phone_auto_portal/app/modules/import_images/models/image_item_model.dart';
import 'package:phone_auto_portal/app/modules/import_images/services/image_batch_service.dart';
import 'package:phone_auto_portal/app/modules/import_images/services/image_processing_service.dart';
import 'package:phone_auto_portal/app/modules/import_images/services/barcode_ocr_service.dart';
import 'package:phone_auto_portal/app/modules/import_images/services/image_upload_service.dart';

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

      Get.snackbar(
        'Thành công',
        'Đã tìm thấy ${batches.length} batch với ${totalImages.value} ảnh từ thư mục',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
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
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Xử lý một batch
  Future<void> _processBatch(int batchIndex) async {
    final batch = batches[batchIndex];

    // Cập nhật status
    batches[batchIndex] = batch.copyWith(status: BatchStatus.processing);
    batches.refresh();

    for (int i = 0; i < batch.images.length; i++) {
      await _processImage(batchIndex, i);
    }

    // Cập nhật batch progress
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
  }

  /// Xử lý một ảnh: Rotate -> OCR -> Upload
  Future<void> _processImage(int batchIndex, int imageIndex) async {
    final batch = batches[batchIndex];
    final image = batch.images[imageIndex];
    List<File> tempFilesToDelete = [];

    try {
      statusMessage.value = 'Đang xử lý ${image.file.path.split('/').last}...';

      // 1. Xoay và compress ảnh
      batch.images[imageIndex] =
          image.copyWith(status: ImageProcessingStatus.rotating);
      batches.refresh();

      final processedResult = await _processingService.processImage(image.file);

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

      // 3. Upload lên Firebase (sử dụng file đã xoay) - Retry 3 lần nếu lỗi
      batch.images[imageIndex] = image.copyWith(
        status: ImageProcessingStatus.uploading,
        maHieu: maHieuResult.maHieu,
      );
      batches.refresh();

      dynamic uploadResult;
      int maxRetries = 3;
      int retryCount = 0;
      bool uploadSuccess = false;

      while (retryCount < maxRetries && !uploadSuccess) {
        try {
          if (retryCount > 0) {
            statusMessage.value =
                'Đang thử upload lại (lần ${retryCount + 1}/$maxRetries)...';
            _debugLog('🔄 Retry upload lần ${retryCount + 1}/$maxRetries');
          }

          uploadResult = await _uploadService.uploadImageWithMetadata(
            imageItem: image.copyWith(
              file: processedResult.file, // ⚠️ QUAN TRỌNG: Upload file đã xoay
              maHieu: maHieuResult.maHieu,
              rotationAngle: processedResult.rotationAngle,
            ),
            batchId: batch.id,
            onProgress: (progress) {
              batch.images[imageIndex] = batch.images[imageIndex].copyWith(
                uploadProgress: progress,
              );
              batches.refresh();
            },
          );

          if (uploadResult.isSuccess) {
            uploadSuccess = true;
            if (retryCount > 0) {
              _debugLog('✅ Upload thành công sau ${retryCount + 1} lần thử');
            }
          } else {
            retryCount++;
            if (retryCount < maxRetries) {
              // Đợi 1-2 giây trước khi retry
              await Future.delayed(Duration(seconds: retryCount));
            }
          }
        } catch (e) {
          retryCount++;
          _debugLog('❌ Upload thất bại lần $retryCount: $e');
          if (retryCount < maxRetries) {
            // Đợi 1-2 giây trước khi retry
            await Future.delayed(Duration(seconds: retryCount));
          }
        }
      }

      if (!uploadSuccess) {
        throw Exception(
            'Upload thất bại sau $maxRetries lần thử: ${uploadResult?.errorMessage ?? 'Lỗi upload'}');
      }

      // 4. Xóa file tạm sau khi upload thành công
      for (var tempFile in tempFilesToDelete) {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
            _debugLog('✅ Đã xóa file tạm: ${tempFile.path}');
          }
        } catch (e) {
          _debugLog('⚠️ Không thể xóa file tạm ${tempFile.path}: $e');
        }
      }

      // 5. Cập nhật thành công
      batch.images[imageIndex] = image.copyWith(
        status: ImageProcessingStatus.completed,
        firebaseUrl: uploadResult.downloadUrl,
        maHieu: maHieuResult.maHieu,
        rotationAngle: processedResult.rotationAngle,
        uploadProgress: 1.0,
      );

      successImages.value++;
    } catch (e) {
      // Xóa file tạm ngay cả khi có lỗi
      for (var tempFile in tempFilesToDelete) {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (deleteError) {
          _debugLog('⚠️ Không thể xóa file tạm: $deleteError');
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
