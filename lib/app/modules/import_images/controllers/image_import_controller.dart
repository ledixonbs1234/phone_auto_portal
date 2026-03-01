import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_auto_portal/app/modules/home/ExtractedData.dart';
import 'package:phone_auto_portal/app/modules/home/GeminiChatService.dart';
import 'dart:io' show Platform, File;
import 'package:phone_auto_portal/app/modules/import_images/models/image_batch_model.dart';
import 'package:phone_auto_portal/app/modules/import_images/models/image_item_model.dart';
import 'package:phone_auto_portal/app/modules/import_images/services/image_batch_service.dart';
import 'package:phone_auto_portal/app/modules/import_images/services/image_processing_service.dart';
import 'package:phone_auto_portal/app/modules/import_images/services/barcode_ocr_service.dart';
import 'package:phone_auto_portal/app/modules/import_images/services/image_upload_service.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';
import 'package:phone_auto_portal/data/image_cache_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';

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
  // final String _geminiApiKey =
  //     'AIzaSyC8C-KzIrDn9QyB35luLR2nbxaXvjHEwmU'; // Key lấy từ HomeController code cũ
  final String _modelId =
      'gemini-3-flash-preview'; // Sử dụng model flash cho nhanh
  late GeminiChatService _geminiService;
// Key mặc định (fallback)
  final String _defaultApiKey = 'AIzaSyC8C-KzIrDn9QyB35luLR2nbxaXvjHEwmU';

  // Observable cho danh sách key và key đang chọn
  final aiKeysList = <AiKeyModel>[].obs;
  final selectedAiKeyName = ''.obs; // Hiển thị tên
  String _currentActiveApiKey = ''; // Lưu giá trị key thực tế
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
  void onInit() {
    super.onInit();
    // Khởi tạo Gemini Service
    _loadSavedAiKey(); // Tải key đã lưu
    _initGeminiService(); // Khởi tạo service
  }

  void _initGeminiService() {
    // Nếu chưa có key nào được chọn, dùng default
    if (_currentActiveApiKey.isEmpty) {
      _currentActiveApiKey = _defaultApiKey;
    }

    final apiUrl = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_modelId:streamGenerateContent?key=$_currentActiveApiKey');
    _geminiService = GeminiChatService(apiUrl: apiUrl.toString());

    _debugLog(
        'Gemini Service initialized with key ending in: ...${_currentActiveApiKey.substring(_currentActiveApiKey.length - 4)}');
  }

  Future<void> fetchAndLoadAiKeys() async {
    final keys = await FirebaseManager().getAiKeys();
    aiKeysList.value = keys;

    // Kiểm tra xem key hiện tại có khớp với cái nào trong list không để hiển thị đúng
    if (aiKeysList.isNotEmpty) {
      final current =
          aiKeysList.firstWhereOrNull((e) => e.key == _currentActiveApiKey);
      if (current != null) {
        selectedAiKeyName.value = current.name;
      }
    }
  }

  // Hàm chọn key mới
  void selectAiKey(AiKeyModel aiKey) {
    _currentActiveApiKey = aiKey.key;
    selectedAiKeyName.value = aiKey.name;

    // Lưu vào storage
    GetStorage().write('selected_ai_api_key', aiKey.key);
    GetStorage().write('selected_ai_key_name', aiKey.name);

    // Khởi tạo lại service với key mới
    _initGeminiService();

    Get.snackbar('Đã đổi AI Key', 'Đang sử dụng key: ${aiKey.name}');
  }

  // Tải key đã lưu từ Storage
  void _loadSavedAiKey() {
    final savedKey = GetStorage().read<String>('selected_ai_api_key');
    final savedName = GetStorage().read<String>('selected_ai_key_name');

    if (savedKey != null && savedKey.isNotEmpty) {
      _currentActiveApiKey = savedKey;
      selectedAiKeyName.value = savedName ?? 'Custom Key';
    } else {
      _currentActiveApiKey = _defaultApiKey;
      selectedAiKeyName.value = 'Mặc định';
    }
  }

  @override
  void onClose() {
    _processingService.dispose();
    _ocrService.dispose();
    super.onClose();
  }

  /// === HÀM MỚI: Xử lý AI cho các ảnh đã chọn ===
  Future<void> processSelectedImagesWithAI() async {
    // 1. Lấy danh sách ảnh từ các batch được chọn
    final selectedImages = <ImageItem>[];
    final selectedImageMap =
        <int, ImageItem>{}; // Map để track vị trí cập nhật lại batch

    // Duyệt qua tất cả batch để tìm ảnh (Logic: Xử lý tất cả ảnh trong batch được tick chọn)
    for (var batch in batches) {
      if (batch.isSelected) {
        selectedImages.addAll(batch.images);
      }
    }

    if (selectedImages.isEmpty) {
      Get.snackbar('Thông báo', 'Vui lòng chọn ít nhất 1 batch để xử lý AI');
      return;
    }

    if (selectedImages.length > 15) {
      Get.snackbar('Cảnh báo',
          'AI chỉ nên xử lý tối đa khoảng 15 ảnh một lần để đảm bảo chính xác. Bạn đã chọn ${selectedImages.length}.');
      // Vẫn cho chạy hoặc return tùy bạn
    }

    try {
      isLoading.value = true;
      statusMessage.value =
          'Đang gửi ${selectedImages.length} ảnh lên AI xử lý...';

      // 2. Chuẩn bị file
      List<File> filesToSend = selectedImages.map((e) => e.file).toList();

      // 3. Gọi Gemini
      List<ExtractedData> results =
          await _geminiService.extractInfoFromImages(filesToSend);

      if (results.isEmpty) {
        Get.snackbar('Lỗi AI', 'Không nhận được dữ liệu phản hồi từ AI');
        return;
      }

      if (results.length != selectedImages.length) {
        Get.snackbar('Cảnh báo',
            'Số lượng kết quả (${results.length}) không khớp số lượng ảnh (${selectedImages.length}). Dữ liệu có thể bị lệch.');
      }

      statusMessage.value = 'Đang cập nhật thông tin...';

      if (results.isNotEmpty) {
        statusMessage.value = 'Đang gửi dữ liệu sang Chrome Extension...';
        FirebaseManager().sendAiOrder(results);

        Get.snackbar(
          'Hoàn thành',
          'Đã gửi ${results.length} đơn hàng lên hệ thống',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Thất bại',
          'Không trích xuất được thông tin nào',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi xử lý AI: $e');
      statusMessage.value = 'Lỗi: $e';
    } finally {
      isLoading.value = false;
      statusMessage.value = '';
    }
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

  // Số lượng batch xử lý đồng thời tối đa
  static const int _maxConcurrentBatches = 2;
  // Số lượng ảnh xử lý đồng thời tối đa trong mỗi batch
  static const int _maxConcurrentImages = 10;

  /// Xử lý và upload các batch đã chọn (song song)
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

      // Xử lý các batch song song (tối đa _maxConcurrentBatches cùng lúc)
      await _runWithConcurrencyLimit(
        items: selectedBatchIndexes,
        maxConcurrent: _maxConcurrentBatches,
        processor: (batchIndex) => _processBatch(batchIndex),
      );

      statusMessage.value =
          'Hoàn thành! Thành công: ${successImages.value}, Lỗi: ${errorImages.value}';

      Get.snackbar(
        'Hoàn thành',
        'Đã xử lý ${processedImages.value} ảnh\nThành công: ${successImages.value}, Lỗi: ${errorImages.value}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Lỗi Upload'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      statusMessage.value = 'Lỗi upload: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Helper: Chạy song song với giới hạn concurrency (pool pattern)
  Future<void> _runWithConcurrencyLimit<T>({
    required List<T> items,
    required int maxConcurrent,
    required Future<void> Function(T item) processor,
  }) async {
    // Chia thành các nhóm, mỗi nhóm chạy song song tối đa maxConcurrent
    for (int start = 0; start < items.length; start += maxConcurrent) {
      final end = (start + maxConcurrent).clamp(0, items.length);
      final chunk = items.sublist(start, end);

      // Chạy song song các item trong chunk, bắt lỗi từng cái
      await Future.wait(
        chunk.map((item) => processor(item).catchError((_) {})),
      );
    }
  }

  /// Xử lý một batch: Process images then upload in concurrent batches
  Future<void> _processBatch(int batchIndex) async {
    final batch = batches[batchIndex];

    // Cập nhật status
    batches[batchIndex] = batch.copyWith(status: BatchStatus.processing);
    batches.refresh();

    // Step 1: Process all images SONG SONG (check cache first, rotate + OCR only if needed)
    final processedImagesList = <ImageItem>[];
    final tempFilesToDelete = <File>[];
    int completedCount = 0;

    // Tạo danh sách index để xử lý song song
    final imageIndexes = List<int>.generate(batch.images.length, (i) => i);

    await _runWithConcurrencyLimit(
      items: imageIndexes,
      maxConcurrent: _maxConcurrentImages,
      processor: (int i) async {
        try {
          final image = batch.images[i];
          final fileName = image.originalFile.path.split('/').last;
          completedCount++;
          final progress = '$completedCount/${batch.images.length}';

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
          } else {
            // ❌ CHƯA CÓ METADATA - Phải rotate, OCR và compress
            statusMessage.value = '[$progress] ⚙️ Chưa xử lý, bắt đầu...';
            _debugLog('❌ No metadata. Processing: ${image.originalFile.path}');

            // BƯỚC 1: Phân tích góc xoay
            statusMessage.value =
                '[$progress] 🔄 Đang kiểm tra góc xoay: $fileName';

            final processedResult =
                await _processingService.processImage(image.originalFile);

            if (!processedResult.isSuccess) {
              throw Exception(
                  processedResult.errorMessage ?? 'Lỗi phân tích góc xoay');
            }

            rotationAngle = processedResult.rotationAngle;

            final fileSize = await image.originalFile.length();
            final isSmallFile = fileSize < 500 * 1024; // < 500KB

            File fileForOcr;

            if (isSmallFile && rotationAngle == 0) {
              // Không nén, không xoay
              fileForOcr = image.originalFile;
            } else {
              statusMessage.value =
                  '[$progress] 🗜️ Đang xử lý góc và dung lượng: $fileName';
              final tempDir = await getTemporaryDirectory();
              final targetPath = path.join(tempDir.path,
                  '${DateTime.now().millisecondsSinceEpoch}_${i}_temp.jpg');

              final savedQuality = GetStorage().read<int>('compress_quality') ??
                  ImageCacheService.defaultQuality;
              final targetQuality = isSmallFile ? 100 : savedQuality;

              final compressedFile =
                  await FlutterImageCompress.compressAndGetFile(
                image.originalFile.absolute.path,
                targetPath,
                quality: targetQuality,
                minWidth: 1920,
                minHeight: 1920,
                rotate: rotationAngle,
                format: CompressFormat.jpeg,
              );

              if (compressedFile == null)
                throw Exception('Lỗi xử lý hình ảnh Native');
              fileForOcr = File(compressedFile.path);
              tempFilesToDelete
                  .add(fileForOcr); // Đánh dấu xóa file tạm sau khi upload
            }

            // BƯỚC 2: OCR để đọc mã hiệu
            batch.images[i] = image.copyWith(
              status: ImageProcessingStatus.readingBarcode,
              rotationAngle: rotationAngle,
            );
            batches.refresh();

            statusMessage.value = '[$progress] 📖 Đang đọc mã hiệu: $fileName';

            final maHieuResult = await _ocrService.readMaHieu(fileForOcr);
            maHieu = maHieuResult.maHieu;

            statusMessage.value = '[$progress] � Đang lưu cache: $fileName';

            // BƯỚC 3: Lưu metadata và file vào cache
            final savedMetadata = await ImageCacheService.instance.saveToCache(
              originalFile: image.originalFile,
              processedFile: fileForOcr,
              maHieu: maHieu,
              rotationAngle: rotationAngle,
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
          processedImagesList.add(processedImage);
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
      },
    );

    // Step 2: Upload all processed images as media groups
    if (processedImagesList.isNotEmpty) {
      try {
        final total = processedImagesList.length;
        statusMessage.value =
            '📤 Chuẩn bị upload $total ảnh lên Firebase Storage...';
        await Future.delayed(const Duration(milliseconds: 300));

        final uploadResult = await _uploadService.uploadImagesInBatches(
          images: processedImagesList,
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
        for (var processedImage in processedImagesList) {
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
        // Firebase Storage đã lưu ảnh, file tạm có thể xóa
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

      // 1. Detect góc xoay và xử lý native
      batch.images[imageIndex] =
          image.copyWith(status: ImageProcessingStatus.rotating);
      batches.refresh();

      final processedResult =
          await _processingService.processImage(image.originalFile);

      if (!processedResult.isSuccess) {
        throw Exception(
            processedResult.errorMessage ?? 'Lỗi phân tích góc xoay');
      }

      final rotationAngle = processedResult.rotationAngle;
      final fileSize = await image.originalFile.length();
      final isSmallFile = fileSize < 500 * 1024; // 500KB

      File fileForOcr;

      if (isSmallFile && rotationAngle == 0) {
        fileForOcr = image.originalFile;
      } else {
        final tempDir = await getTemporaryDirectory();
        final targetPath = path.join(tempDir.path,
            '${DateTime.now().millisecondsSinceEpoch}_retry_${imageIndex}.jpg');

        final savedQuality = GetStorage().read<int>('compress_quality') ??
            ImageCacheService.defaultQuality;
        final targetQuality = isSmallFile ? 100 : savedQuality;

        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          image.originalFile.absolute.path,
          targetPath,
          quality: targetQuality,
          minWidth: 1920,
          minHeight: 1920,
          rotate: rotationAngle,
          format: CompressFormat.jpeg,
        );

        if (compressedFile == null) throw Exception('Lỗi nén ảnh Native');
        fileForOcr = File(compressedFile.path);
        tempFilesToDelete.add(fileForOcr);
      }

      // 2. Đọc mã hiệu
      batch.images[imageIndex] = image.copyWith(
        status: ImageProcessingStatus.readingBarcode,
        rotationAngle: rotationAngle,
      );
      batches.refresh();

      final maHieuResult = await _ocrService.readMaHieu(fileForOcr);

      // 3. Upload (cập nhật file MỚI vào item để upload thực lấy cái đó)
      batch.images[imageIndex] = image.copyWith(
        status: ImageProcessingStatus.uploading,
        maHieu: maHieuResult.maHieu,
      );
      batches.refresh();

      final uploadResult = await _uploadService.uploadImageWithMetadata(
        imageItem: image.copyWith(
          file: fileForOcr, // Upload file đã xử lý
          maHieu: maHieuResult.maHieu,
          rotationAngle: rotationAngle,
        ),
        batchId: batch.id,
      );

      if (!uploadResult.isSuccess) {
        throw Exception(uploadResult.errorMessage ?? 'Lỗi upload');
      }

      // 4. Xóa file rotated tạm sau khi upload thành công
      // Firebase Storage đã lưu ảnh, file tạm có thể xóa
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
        file: fileForOcr, // Cập nhật file rotated mới
        status: ImageProcessingStatus.completed,
        firebaseUrl: uploadResult.downloadUrl,
        maHieu: maHieuResult.maHieu,
        rotationAngle: rotationAngle,
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
