import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart' as path;

import 'image_cache_service.dart';
import '../app/modules/import_images/models/image_item_model.dart';

/// Singleton service for uploading images to Firebase Storage
/// Thay thế TelegramService — upload trực tiếp lên Firebase Storage
class FirebaseStorageService {
  static final FirebaseStorageService _instance =
      FirebaseStorageService._internal();
  static FirebaseStorageService get instance => _instance;

  FirebaseStorageService._internal();

  void _debugLog(String message) {
    if (kDebugMode) {
      print('[FirebaseStorageService] $message');
    }
  }

  // Firebase Storage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Storage path prefix dựa trên keyData (giống firebaseManager)
  String get _storagePath {
    final keyData = GetStorage().read('key') ?? 'maychu';
    return 'imported_images/$keyData';
  }

  /// Initialize service (init ImageCacheService)
  Future<void> init() async {
    try {
      await ImageCacheService.instance.init();
      _debugLog('FirebaseStorageService initialized');
    } catch (e) {
      print('FirebaseStorageService init error (silently ignored): $e');
    }
  }

  /// Upload single image to Firebase Storage
  ///
  /// Accepts File or ImageItem
  /// Returns: {downloadUrl: String, thumbnailUrl: String}
  Future<Map<String, String>> uploadImage(dynamic imageInput) async {
    File fileToUpload;

    if (imageInput is ImageItem) {
      fileToUpload = imageInput.file;
      _debugLog('📤 Uploading ImageItem: ${path.basename(fileToUpload.path)}');
    } else if (imageInput is File) {
      fileToUpload = imageInput;
      _debugLog('📤 Uploading File: ${path.basename(fileToUpload.path)}');
    } else {
      throw ArgumentError('imageInput must be File or ImageItem');
    }

    return await _uploadWithRetry(fileToUpload);
  }

  /// Upload multiple images to Firebase Storage (thay thế Media Group)
  ///
  /// Upload song song nhiều ảnh, trả về List URL maps theo đúng thứ tự input
  Future<List<Map<String, String>>> uploadMediaGroup(
      List<dynamic> imageInputs) async {
    if (imageInputs.isEmpty) {
      throw ArgumentError('imageInputs cannot be empty');
    }

    // Extract files to upload
    final filesToUpload = <File>[];
    for (final input in imageInputs) {
      if (input is ImageItem) {
        filesToUpload.add(input.file);
      } else if (input is File) {
        filesToUpload.add(input);
      } else {
        throw ArgumentError('Each input must be File or ImageItem');
      }
    }

    // Upload song song tất cả files
    final futures =
        filesToUpload.map((file) => _uploadWithRetry(file)).toList();
    return await Future.wait(futures);
  }

  /// Upload file lên Firebase Storage với retry logic
  /// Returns: {downloadUrl: String, thumbnailUrl: String}
  Future<Map<String, String>> _uploadWithRetry(File fileToUpload) async {
    const maxRetries = 5;
    final retryDelays = [
      const Duration(seconds: 1),
      const Duration(seconds: 2),
      const Duration(seconds: 4),
    ];

    Exception? lastException;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          _debugLog(
              '🔄 Retry $attempt/$maxRetries: ${path.basename(fileToUpload.path)}');
          await Future.delayed(retryDelays[attempt - 1]);
        }

        // Tạo unique filename với timestamp
        final fileName = path.basename(fileToUpload.path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storagePath = '$_storagePath/${timestamp}_$fileName';

        // Upload lên Firebase Storage
        final ref = _storage.ref().child(storagePath);
        final uploadTask = ref.putFile(
          fileToUpload,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // Đợi upload hoàn tất
        final snapshot = await uploadTask;

        // Lấy download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();

        _debugLog('✅ Uploaded: $fileName → $downloadUrl');

        // Firebase Storage không tự tạo thumbnail
        // Dùng cùng URL cho cả download và thumbnail
        return {
          'downloadUrl': downloadUrl,
          'thumbnailUrl': downloadUrl,
        };
      } on FirebaseException catch (e) {
        lastException = e;
        _debugLog(
            '❌ Firebase Storage error (attempt ${attempt + 1}): ${e.message}');

        // Nếu lỗi không phải transient → throw ngay
        if (e.code == 'unauthorized' ||
            e.code == 'unauthenticated' ||
            e.code == 'permission-denied') {
          throw Exception(
              'Không có quyền upload lên Firebase Storage: ${e.message}');
        }

        if (attempt == maxRetries - 1) {
          throw Exception(
              'Upload thất bại sau $maxRetries lần thử: ${e.message}');
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        _debugLog('❌ Upload error (attempt ${attempt + 1}): $e');

        if (attempt == maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(retryDelays[attempt]);
      }
    }

    throw lastException ??
        Exception('Upload failed after $maxRetries attempts');
  }

  /// Xóa một file trên Firebase Storage bằng download URL
  Future<void> deleteImageByUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      _debugLog('🗑️ Deleted: $downloadUrl');
    } catch (e) {
      _debugLog('⚠️ Failed to delete image: $e');
    }
  }

  /// Xóa tất cả ảnh cũ trong folder trên Firebase Storage
  Future<void> clearOldImages() async {
    try {
      final ref = _storage.ref().child(_storagePath);
      final listResult = await ref.listAll();

      if (listResult.items.isEmpty) {
        _debugLog('🗑️ Không có ảnh cũ để xóa');
        return;
      }

      _debugLog('🗑️ Đang xóa ${listResult.items.length} ảnh cũ...');

      // Xóa song song tất cả files
      await Future.wait(
        listResult.items.map((item) => item.delete()),
      );

      _debugLog('✅ Đã xóa ${listResult.items.length} ảnh cũ');
    } catch (e) {
      _debugLog('⚠️ Lỗi khi xóa ảnh cũ: $e');
    }
  }
}
