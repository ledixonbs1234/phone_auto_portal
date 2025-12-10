import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart' as path;
import 'package:phone_auto_portal/app/modules/import_images/models/image_batch_model.dart';
import 'package:phone_auto_portal/app/modules/import_images/models/image_item_model.dart';

// Safe logging function that only prints in debug mode
void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

/// Service để phân loại ảnh theo batch (cách nhau 2 phút)
class ImageBatchService {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Thời gian tolerance để group các ảnh vào cùng 1 batch (mặc định 5 phút)
  /// Có thể thay đổi trong settings
  static const int defaultBatchToleranceMinutes = 5;

  /// Lấy batch tolerance từ settings (1-5 phút)
  int getBatchToleranceMinutes() {
    final storage = GetStorage();
    final value = storage.read<int>('batch_tolerance_minutes');
    if (value == null || value < 1 || value > 5) {
      return defaultBatchToleranceMinutes;
    }
    return value;
  }

  /// Lưu batch tolerance vào settings
  void setBatchToleranceMinutes(int minutes) {
    if (minutes < 1 || minutes > 5) {
      throw ArgumentError('Batch tolerance phải từ 1-5 phút');
    }
    GetStorage().write('batch_tolerance_minutes', minutes);
  }

  /// Lấy danh sách thư mục đã chọn từ settings
  List<String> getSelectedFolders() {
    final storage = GetStorage();
    final folders = storage.read<List<dynamic>>('selected_folders');
    if (folders == null) return [];
    return folders.map((e) => e.toString()).toList();
  }

  /// Lấy tất cả ảnh từ các thư mục đã chọn (ngày hôm nay)
  Future<List<File>> getImagesFromFolders({bool recursive = true}) async {
    final folders = getSelectedFolders();

    if (folders.isEmpty) {
      throw Exception('Chưa chọn thư mục nào trong settings');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final List<File> imageFiles = [];
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp'];

    for (var folderPath in folders) {
      final dir = Directory(folderPath);

      _debugLog('🔍 Đang quét thư mục: $folderPath');
      _debugLog('📂 Recursive: $recursive');

      if (!await dir.exists()) {
        _debugLog('❌ Thư mục không tồn tại: $folderPath');
        continue;
      }

      int totalFiles = 0;
      int imageCount = 0;
      int todayImageCount = 0;

      try {
        await for (var entity in dir.list(recursive: recursive)) {
          if (entity is File) {
            totalFiles++;
            final ext = path.extension(entity.path).toLowerCase();

            // Kiểm tra extension
            if (!imageExtensions.contains(ext)) {
              continue;
            }

            imageCount++;

            // Kiểm tra thời gian modified
            try {
              final stat = await entity.stat();
              final modified = stat.modified;

              if (modified.isAfter(today) && modified.isBefore(tomorrow)) {
                imageFiles.add(entity);
                todayImageCount++;
                _debugLog(
                    '✅ Tìm thấy ảnh hôm nay: ${path.basename(entity.path)} - $modified');
              }
            } catch (e) {
              _debugLog(
                  '⚠️ Không đọc được thông tin file: ${entity.path} - $e');
            }
          }
        }

        _debugLog('📊 Kết quả quét $folderPath:');
        _debugLog('   - Tổng file: $totalFiles');
        _debugLog('   - File ảnh: $imageCount');
        _debugLog('   - Ảnh hôm nay: $todayImageCount');
      } catch (e) {
        _debugLog('❌ Lỗi khi đọc thư mục $folderPath: $e');
      }
    }

    _debugLog('🎯 Tổng cộng tìm thấy ${imageFiles.length} ảnh hôm nay');
    return imageFiles;
  }

  /// Chọn nhiều ảnh từ thư viện
  Future<List<XFile>> pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 100, // Giữ quality cao để OCR chính xác
      );
      return images;
    } catch (e) {
      throw Exception('Lỗi khi chọn ảnh: $e');
    }
  }

  /// Lấy thời gian modified của file ảnh
  Future<DateTime> _getImageTimestamp(File file) async {
    try {
      final stat = await file.stat();
      return stat.modified;
    } catch (e) {
      // Fallback về thời gian hiện tại nếu không đọc được
      return DateTime.now();
    }
  }

  /// Lọc ảnh theo ngày hôm nay
  Future<List<File>> filterTodayImages(List<XFile> xFiles) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final List<File> todayFiles = [];

    for (var xFile in xFiles) {
      final file = File(xFile.path);
      final timestamp = await _getImageTimestamp(file);

      // Kiểm tra ảnh có nằm trong ngày hôm nay không
      if (timestamp.isAfter(today) && timestamp.isBefore(tomorrow)) {
        todayFiles.add(file);
      }
    }

    return todayFiles;
  }

  /// Phân loại ảnh thành các batch (so sánh với ảnh cuối cùng, cách nhau X phút)
  /// Logic: Ảnh tiếp theo cách ảnh cuối ≤X phút → cùng batch
  /// Khi kết thúc batch: kiểm tra ảnh cuối +X phút có ảnh nào không
  Future<List<ImageBatch>> createBatches(List<File> files) async {
    if (files.isEmpty) return [];

    // Lấy batch tolerance từ settings
    final batchToleranceMinutes = getBatchToleranceMinutes();
    _debugLog('⏱️ Batch tolerance: $batchToleranceMinutes phút');

    // Tạo danh sách ImageItem với timestamp
    final List<ImageItem> imageItems = [];
    for (var file in files) {
      final timestamp = await _getImageTimestamp(file);
      imageItems.add(ImageItem(
        id: _uuid.v4(),
        file: file,
        timestamp: timestamp,
      ));
    }

    // Sắp xếp theo thời gian
    imageItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Phân loại thành batch
    final List<ImageBatch> batches = [];
    List<ImageItem> currentBatch = [];

    int i = 0;
    while (i < imageItems.length) {
      final currentItem = imageItems[i];

      if (currentBatch.isEmpty) {
        // Bắt đầu batch mới
        currentBatch.add(currentItem);
        i++;
      } else {
        // So sánh với ảnh CUỐI CÙNG trong batch hiện tại
        final lastItemInBatch = currentBatch.last;
        final timeDiff = currentItem.timestamp
            .difference(lastItemInBatch.timestamp)
            .inMinutes;

        if (timeDiff <= batchToleranceMinutes) {
          // Cùng batch (cách nhau ≤ X phút)
          currentBatch.add(currentItem);
          i++;
        } else {
          // Quá X phút → Kiểm tra ảnh cuối + X phút có ảnh nào không
          final lastItemTime = currentBatch.last.timestamp;
          final checkUntil =
              lastItemTime.add(Duration(minutes: batchToleranceMinutes));

          _debugLog(
              '🔍 Batch đang có ${currentBatch.length} ảnh, ảnh cuối: $lastItemTime');
          _debugLog('📅 Kiểm tra khoảng mở rộng đến: $checkUntil');

          // Tìm các ảnh trong khoảng [lastItemTime, lastItemTime + X phút]
          int addedCount = 0;
          while (i < imageItems.length) {
            final nextItem = imageItems[i];
            if (nextItem.timestamp.isBefore(checkUntil) ||
                nextItem.timestamp.isAtSameMomentAs(checkUntil)) {
              // Có ảnh trong khoảng +X phút → thêm vào batch hiện tại
              currentBatch.add(nextItem);
              addedCount++;
              _debugLog(
                  '  ✅ Thêm ảnh: ${path.basename(nextItem.file.path)} - ${nextItem.timestamp}');
              i++;
            } else {
              // Đã quá khoảng +X phút → dừng lại
              _debugLog(
                  '  ❌ Ảnh ${path.basename(nextItem.file.path)} (${nextItem.timestamp}) quá khoảng +$batchToleranceMinutes phút');
              break;
            }
          }

          _debugLog(
              '📦 Hoàn thành batch với ${currentBatch.length} ảnh (thêm $addedCount từ khoảng mở rộng)');

          // Đóng batch hiện tại
          if (currentBatch.isNotEmpty) {
            batches.add(_createBatch(currentBatch));
          }

          // Reset để bắt đầu batch mới
          currentBatch = [];
        }
      }
    }

    // Thêm batch cuối cùng (nếu có)
    if (currentBatch.isNotEmpty) {
      _debugLog('📦 Hoàn thành batch cuối với ${currentBatch.length} ảnh');
      batches.add(_createBatch(currentBatch));
    }

    _debugLog('🎯 Tổng cộng tạo được ${batches.length} batch');
    return batches;
  }

  /// Tạo ImageBatch từ danh sách ImageItem
  ImageBatch _createBatch(List<ImageItem> images) {
    final startTime = images.first.timestamp;
    final endTime = images.last.timestamp;

    return ImageBatch(
      id: _uuid.v4(),
      startTime: startTime,
      endTime: endTime,
      images: images,
    );
  }

  /// Workflow: Lấy ảnh từ thư mục -> Tạo batch
  Future<List<ImageBatch>> loadImagesFromFoldersAndCreateBatches() async {
    try {
      // 1. Lấy ảnh từ các thư mục đã chọn
      final imageFiles = await getImagesFromFolders();

      if (imageFiles.isEmpty) {
        throw Exception('Không có ảnh nào trong các thư mục đã chọn (hôm nay)');
      }

      // 2. Tạo batch
      final batches = await createBatches(imageFiles);

      return batches;
    } catch (e) {
      rethrow;
    }
  }

  /// Workflow hoàn chỉnh: Chọn ảnh -> Lọc theo ngày -> Tạo batch
  Future<List<ImageBatch>> loadAndCreateBatches() async {
    try {
      // 1. Chọn ảnh
      final xFiles = await pickImages();
      if (xFiles.isEmpty) {
        return [];
      }

      // 2. Lọc ảnh hôm nay
      final todayFiles = await filterTodayImages(xFiles);
      if (todayFiles.isEmpty) {
        throw Exception('Không có ảnh nào được chụp hôm nay');
      }

      // 3. Tạo batch
      final batches = await createBatches(todayFiles);

      return batches;
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy tổng số ảnh từ danh sách batch
  int getTotalImagesCount(List<ImageBatch> batches) {
    return batches.fold(0, (sum, batch) => sum + batch.totalImages);
  }

  /// Lấy các batch đã được chọn
  List<ImageBatch> getSelectedBatches(List<ImageBatch> batches) {
    return batches.where((batch) => batch.isSelected).toList();
  }
}
