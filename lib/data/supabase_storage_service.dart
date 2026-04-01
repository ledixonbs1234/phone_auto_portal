import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart' as path;

import 'image_cache_service.dart';
import '../app/modules/import_images/models/image_item_model.dart';

/// Singleton service for uploading images to Supabase Storage
class SupabaseStorageService {
  static final SupabaseStorageService _instance =
      SupabaseStorageService._internal();
  static SupabaseStorageService get instance => _instance;

  SupabaseStorageService._internal();

  void _debugLog(String message) {
    if (kDebugMode) {
      print('[SupabaseStorageService] $message');
    }
  }

  final String _supabaseUrl = 'https://awelxjuegmcczgbvbtgi.supabase.co';
  final String _supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3ZWx4anVlZ21jY3pnYnZidGdpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NTAxNTY2OCwiZXhwIjoyMDkwNTkxNjY4fQ.pkZmocE3IfPKObcL2Tp8yRwuwI4folG5CYaKdAPuSoA';
  final String _bucketName = 'images';

  late final Dio _dio;

  /// Storage path prefix dựa trên keyData (giống firebaseManager)
  String get _storagePath {
    final keyData = GetStorage().read('key') ?? 'maychu';
    return 'imported_images/$keyData';
  }

  /// Khởi tạo service
  Future<void> init() async {
    try {
      _dio = Dio(BaseOptions(
        baseUrl: '$_supabaseUrl/storage/v1',
        headers: {
          'Authorization': 'Bearer $_supabaseKey',
          'apikey': _supabaseKey,
        },
      ));
      await ImageCacheService.instance.init();
      _debugLog('SupabaseStorageService initialized');
    } catch (e) {
      print('SupabaseStorageService init error (silently ignored): $e');
    }
  }

  /// Upload single image to Supabase Storage
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

  /// Upload multiple images to Supabase Storage
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

  /// Upload file lên Supabase Storage với retry logic
  /// Returns: {downloadUrl: String, thumbnailUrl: String}
  Future<Map<String, String>> _uploadWithRetry(File fileToUpload) async {
    const maxRetries = 5;
    final retryDelays = [
      const Duration(seconds: 1),
      const Duration(seconds: 2),
      const Duration(seconds: 4),
      const Duration(seconds: 8),
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
        final uploadPath = '$_storagePath/${timestamp}_$fileName';

        // Gọi Supabase API Endpoint: POST /storage/v1/object/<bucketName>/<uploadPath>
        // Set Request Header để nhận stream binary từ Dio
        final fileLength = fileToUpload.lengthSync();
        await _dio.post(
          '/object/$_bucketName/$uploadPath',
          data: fileToUpload.openRead(),
          options: Options(
            headers: {
              'Content-Type': 'image/jpeg',
              'x-upsert': 'true',
              Headers.contentLengthHeader: fileLength,
            },
          ),
        );

        // Upload thành công. Parse Download URL public
        // Endpoint cho file public:
        // https://awelxjuegmcczgbvbtgi.supabase.co/storage/v1/object/public/<bucketName>/<uploadPath>
        final downloadUrl =
            '$_supabaseUrl/storage/v1/object/public/$_bucketName/$uploadPath';

        _debugLog('✅ Uploaded: $fileName → $downloadUrl');

        return {
          'downloadUrl': downloadUrl,
          'thumbnailUrl': downloadUrl, // Dùng url chung tương tự firebase
        };
      } on DioException catch (e) {
        lastException = e;
        final responseData = e.response?.data;
        _debugLog(
            '❌ Supabase Dio error (attempt ${attempt + 1}): ${e.message}. Status: ${e.response?.statusCode}. Data: $responseData');

        // Bỏ retry cho các lỗi xác thực
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          throw Exception(
              'Không có quyền (401/403) upload lên Supabase Storage: $responseData');
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
      }
    }

    throw lastException ??
        Exception('Upload failed after $maxRetries attempts');
  }

  /// Xóa một file trên Supabase Storage bằng download URL
  Future<void> deleteImageByUrl(String downloadUrl) async {
    try {
      final downloadPrefix =
          '$_supabaseUrl/storage/v1/object/public/$_bucketName/';
      if (downloadUrl.startsWith(downloadPrefix)) {
        final filePath = downloadUrl.substring(downloadPrefix.length);

        // Delete endpoint is DELETE /storage/v1/object/$_bucketName/<filePath>
        await _dio.delete('/object/$_bucketName/$filePath');
        _debugLog('🗑️ Deleted: $downloadUrl');
      }
    } catch (e) {
      _debugLog('⚠️ Failed to delete image by URL ($downloadUrl): $e');
    }
  }

  /// Xóa tất cả ảnh cũ trong folder tương ứng
  Future<void> clearOldImages() async {
    try {
      // Đầu tiên phải get link những file trong thư mục:
      // POST /storage/v1/object/list/:bucketName
      final response = await _dio.post(
        '/object/list/$_bucketName',
        data: {
          'prefix': _storagePath,
          'limit': 1000,
          'offset': 0,
        },
      );

      final List files = response.data;
      if (files.isEmpty) {
        _debugLog('🗑️ Không có ảnh cũ để xóa trong Supabase');
        return;
      }
      
      // Xoá tất cả resource theo metadata name (không bao gồm placeholder .emptyFolderPlaceholder)
      final filesToDelete = files
          .where((f) => f['name'] != null && f['name'] != '.emptyFolderPlaceholder')
          .map((f) => '$_storagePath/${f['name']}')
          .toList();

      if (filesToDelete.isEmpty) {
        _debugLog('🗑️ Tệp thuộc prefix không hợp lệ');
        return;
      }

      _debugLog('🗑️ Đang xóa ${filesToDelete.length} ảnh cũ...');

      // DELETE /storage/v1/object/:bucketName 
      // body: { "prefixes": ["path/to/file1", "path/to/file2"] }
      final deleteBody = {
        'prefixes': filesToDelete
      };

      await _dio.delete(
        '/object/$_bucketName',
        data: deleteBody,
      );

      _debugLog('✅ Đã xóa ${filesToDelete.length} ảnh cũ');
    } catch (e) {
      _debugLog('⚠️ Lỗi khi xóa ảnh cũ: $e');
    }
  }
}
