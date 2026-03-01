import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Model cho metadata của ảnh đã xử lý
class ImageMetadata {
  final String originalPath;
  final String compressedPath;
  final String? maHieu;
  final int rotationAngle;
  final int lastModified;
  final int processedAt;

  ImageMetadata({
    required this.originalPath,
    required this.compressedPath,
    this.maHieu,
    this.rotationAngle = 0,
    required this.lastModified,
    required this.processedAt,
  });

  Map<String, dynamic> toJson() => {
        'originalPath': originalPath,
        'compressedPath': compressedPath,
        'maHieu': maHieu,
        'rotationAngle': rotationAngle,
        'lastModified': lastModified,
        'processedAt': processedAt,
      };

  factory ImageMetadata.fromJson(Map<String, dynamic> json) => ImageMetadata(
        originalPath: json['originalPath'],
        compressedPath: json['compressedPath'],
        maHieu: json['maHieu'],
        rotationAngle: json['rotationAngle'] ?? 0,
        lastModified: json['lastModified'],
        processedAt: json['processedAt'],
      );
}

/// Service quản lý metadata và compressed images
/// - Sử dụng naming convention đơn giản: originalName_compressed.jpg
/// - Lưu metadata trong file JSON
/// - Tự động xóa file cũ (không dùng trong ngày)
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  static ImageCacheService get instance => _instance;

  ImageCacheService._internal();

  // Default compression quality (can be exposed to settings later)
  static const int defaultQuality = 85;

  Directory? _compressedDir;
  File? _metadataFile;
  Map<String, ImageMetadata> _metadata = {};

  /// Khởi tạo service và load metadata
  Future<void> init() async {
    try {
      final tempDir = await getTemporaryDirectory();
      _compressedDir =
          Directory(path.join(tempDir.path, 'telegram_compressed'));

      if (!await _compressedDir!.exists()) {
        await _compressedDir!.create(recursive: true);
      }

      _metadataFile = File(path.join(_compressedDir!.path, 'metadata.json'));

      // Load metadata từ file
      await _loadMetadata();

      // Dọn dẹp file cũ
      await _cleanupOldFiles();

      _debugLog('📁 Initialized with ${_metadata.length} cached images');
    } catch (e) {
      _debugLog('⚠️ Error initializing: $e');
    }
  }

  /// Load metadata từ file JSON
  Future<void> _loadMetadata() async {
    try {
      if (_metadataFile == null || !await _metadataFile!.exists()) {
        _metadata = {};
        return;
      }

      final jsonString = await _metadataFile!.readAsString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;

      _metadata = jsonMap.map(
        (key, value) => MapEntry(
          key,
          ImageMetadata.fromJson(value as Map<String, dynamic>),
        ),
      );

      _debugLog('✅ Loaded ${_metadata.length} metadata entries');
    } catch (e) {
      _debugLog('⚠️ Error loading metadata: $e');
      _metadata = {};
    }
  }

  /// Lưu metadata vào file JSON
  Future<void> _saveMetadata() async {
    try {
      if (_metadataFile == null) return;

      final jsonMap = _metadata.map(
        (key, value) => MapEntry(key, value.toJson()),
      );

      final jsonString = jsonEncode(jsonMap);
      await _metadataFile!.writeAsString(jsonString);

      _debugLog('💾 Saved ${_metadata.length} metadata entries');
    } catch (e) {
      _debugLog('⚠️ Error saving metadata: $e');
    }
  }

  /// Tạo key cho metadata từ file path + last modified
  String _generateKey(File file) {
    final filePath = file.absolute.path;
    final lastModified = file.lastModifiedSync().millisecondsSinceEpoch;
    return '$filePath:$lastModified';
  }

  /// Tạo tên file compressed từ file gốc (đơn giản)
  String _getCompressedFileName(File originalFile) {
    final baseName = path.basenameWithoutExtension(originalFile.path);
    return '${baseName}_compressed.jpg';
  }

  /// Kiểm tra xem file gốc đã được xử lý chưa
  /// Returns metadata nếu có, null nếu chưa xử lý hoặc file gốc đã thay đổi
  Future<ImageMetadata?> getMetadata(File originalFile) async {
    if (_compressedDir == null) return null;

    try {
      final key = _generateKey(originalFile);
      final metadata = _metadata[key];

      if (metadata == null) {
        _debugLog('ℹ️ No metadata for: ${path.basename(originalFile.path)}');
        return null;
      }

      // Kiểm tra file compressed còn tồn tại không
      final compressedFile = File(metadata.compressedPath);
      if (!await compressedFile.exists()) {
        _debugLog('⚠️ Compressed file not found, removing metadata');
        _metadata.remove(key);
        await _saveMetadata();
        return null;
      }

      _debugLog('✅ Found metadata: ${metadata.maHieu ?? "no maHieu"}');
      return metadata;
    } catch (e) {
      _debugLog('⚠️ Error getting metadata: $e');
      return null;
    }
  }

  /// Thay thế hàm processAndSave cũ, bây giờ chỉ phụ trách lưu file đã xử lý vào cache
  Future<ImageMetadata> saveToCache({
    required File originalFile,
    required File processedFile,
    required String? maHieu,
    required int rotationAngle,
  }) async {
    if (_compressedDir == null) {
      throw StateError('ImageCacheService not initialized');
    }

    try {
      final compressedFileName = _getCompressedFileName(originalFile);
      final compressedPath =
          path.join(_compressedDir!.path, compressedFileName);

      _debugLog('🗜️ Saving to cache: ${path.basename(originalFile.path)}');

      if (processedFile.absolute.path != compressedPath) {
        await processedFile.copy(compressedPath);
      }

      // Tạo metadata
      final metadata = ImageMetadata(
        originalPath: originalFile.absolute.path,
        compressedPath: compressedPath,
        maHieu: maHieu,
        rotationAngle: rotationAngle,
        lastModified: originalFile.lastModifiedSync().millisecondsSinceEpoch,
        processedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Lưu vào map và file
      final key = _generateKey(originalFile);
      _metadata[key] = metadata;
      await _saveMetadata();

      _debugLog('✅ Saved metadata: ${path.basename(originalFile.path)}');
      return metadata;
    } catch (e) {
      _debugLog('❌ Error processing: $e');
      rethrow;
    }
  }

  /// Xóa file compressed cũ (không dùng trong 7 ngày)
  Future<void> _cleanupOldFiles() async {
    if (_compressedDir == null) return;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);

      final keysToRemove = <String>[];
      int deletedCount = 0;

      for (final entry in _metadata.entries) {
        if (entry.value.processedAt < sevenDaysAgo) {
          // Xóa file compressed
          try {
            final file = File(entry.value.compressedPath);
            if (await file.exists()) {
              await file.delete();
              deletedCount++;
            }
          } catch (e) {
            _debugLog('⚠️ Failed to delete: ${entry.value.compressedPath}');
          }

          keysToRemove.add(entry.key);
        }
      }

      // Xóa metadata của file đã xóa
      for (final key in keysToRemove) {
        _metadata.remove(key);
      }

      if (keysToRemove.isNotEmpty) {
        await _saveMetadata();
        _debugLog('🗑️ Cleaned up $deletedCount old files');
      }
    } catch (e) {
      _debugLog('⚠️ Error cleaning up: $e');
    }
  }

  /// Xóa toàn bộ cache
  Future<void> clearAll() async {
    try {
      _metadata.clear();
      await _saveMetadata();

      if (_compressedDir != null && await _compressedDir!.exists()) {
        await for (final entity in _compressedDir!.list()) {
          if (entity is File && entity.path != _metadataFile?.path) {
            try {
              await entity.delete();
            } catch (e) {
              _debugLog('⚠️ Failed to delete: ${entity.path}');
            }
          }
        }
      }

      _debugLog('✅ Cleared all cache');
    } catch (e) {
      _debugLog('⚠️ Error clearing cache: $e');
    }
  }

  /// Lấy thông tin cache
  Future<CacheInfo> getCacheInfo() async {
    if (_compressedDir == null) {
      return CacheInfo(fileCount: 0, totalSize: 0);
    }

    try {
      int fileCount = 0;
      int totalSize = 0;

      await for (final entity in _compressedDir!.list()) {
        if (entity is File && entity.path != _metadataFile?.path) {
          fileCount++;
          totalSize += await entity.length();
        }
      }

      return CacheInfo(fileCount: fileCount, totalSize: totalSize);
    } catch (e) {
      _debugLog('⚠️ Error getting cache info: $e');
      return CacheInfo(fileCount: 0, totalSize: 0);
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      print('[ImageCacheService] $message');
    }
  }
}

/// Thông tin về cache
class CacheInfo {
  final int fileCount;
  final int totalSize;

  CacheInfo({required this.fileCount, required this.totalSize});

  String get formattedSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024)
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() => 'CacheInfo(files: $fileCount, size: $formattedSize)';
}
