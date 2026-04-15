import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:path/path.dart' as path;

import 'exceptions/telegram_exceptions.dart';
import 'image_cache_service.dart';
import '../app/modules/import_images/models/image_item_model.dart';

/// Singleton service for uploading images to Telegram Bot API
class TelegramService {
  static final TelegramService _instance = TelegramService._internal();
  static TelegramService get instance => _instance;

  TelegramService._internal();

  void _debugLog(String message) {
    if (kDebugMode) {
      '[TelegramService] $message'.printInfo();
    }
  }

  // Hardcoded Telegram Bot API base URL
  static const String _baseUrl = 'https://api.telegram.org';

  // Configuration loaded from Firebase
  String? _botToken;
  String? _chatId;
  int _concurrentUploads = 3; // Default value

  // Dio instance with timeout configuration
  late final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  /// Check if service is properly configured
  bool get isConfigured =>
      _botToken != null &&
      _botToken!.isNotEmpty &&
      _chatId != null &&
      _chatId!.isNotEmpty;

  /// Get configured concurrent upload limit
  int get concurrentUploads => _concurrentUploads;

  /// Initialize service by loading configuration from Firebase
  /// Silently handles errors without blocking app startup
  Future<void> init() async {
    try {
      // Initialize image cache service
      await ImageCacheService.instance.init();

      final database = FirebaseDatabase.instance.ref();
      final settingsRef = database.child('PORTAL/SETTINGS');

      // Load bot token
      final tokenSnapshot = await settingsRef.child('telegram_bot_token').get();
      if (tokenSnapshot.exists && tokenSnapshot.value != null) {
        _botToken = tokenSnapshot.value.toString();
      }

      // Load chat ID
      final chatIdSnapshot = await settingsRef.child('telegram_chat_id').get();
      if (chatIdSnapshot.exists && chatIdSnapshot.value != null) {
        _chatId = chatIdSnapshot.value.toString();
      }

      // Load concurrent uploads limit (default to 3 if not set)
      final concurrentSnapshot =
          await settingsRef.child('telegram_concurrent_uploads').get();
      if (concurrentSnapshot.exists && concurrentSnapshot.value != null) {
        final value = concurrentSnapshot.value;
        if (value is int) {
          _concurrentUploads = value;
        } else if (value is String) {
          _concurrentUploads = int.tryParse(value) ?? 3;
        }
      }

      'TelegramService initialized: configured=$isConfigured, concurrent=$_concurrentUploads'
          .printInfo();
    } catch (e) {
      'TelegramService init error (silently ignored): $e'.printInfo();
      // Silently ignore errors, validation happens on first upload
    }
  }

  /// Upload image to Telegram and return URLs (full + thumbnail)
  /// Expects file to already be compressed (from ImageCacheService)
  ///
  /// IMPORTANT: Accepts both File and ImageItem
  /// - If File: upload directly (assume already compressed)
  /// - If ImageItem: upload image.file directly (already compressed by controller)
  ///
  /// Returns: {downloadUrl: String, thumbnailUrl: String}
  Future<Map<String, String>> uploadImage(dynamic imageInput) async {
    // Lazy validation - check config on first upload attempt
    if (!isConfigured) {
      throw TelegramConfigMissingException();
    }

    File fileToUpload;

    // Xử lý input: File hoặc ImageItem
    if (imageInput is ImageItem) {
      // File đã được compress trong controller
      fileToUpload = imageInput.file;
      _debugLog('📤 Uploading ImageItem: ${path.basename(fileToUpload.path)}');
    } else if (imageInput is File) {
      // Direct File upload (assume already compressed)
      fileToUpload = imageInput;
      _debugLog('📤 Uploading File: ${path.basename(fileToUpload.path)}');
    } else {
      throw ArgumentError('imageInput must be File or ImageItem');
    }

    // Upload to Telegram with retry logic
    final uploadResult = await _uploadWithRetry(fileToUpload);

    // Get full download URL for largest photo
    final downloadUrl = await _getFileUrl(uploadResult['largestFileId']!);

    // Get thumbnail URL for smallest photo
    final thumbnailUrl = await _getFileUrl(uploadResult['smallestFileId']!);

    return {
      'downloadUrl': downloadUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  /// Upload multiple images as Media Group (album) to Telegram
  /// Returns list of URL maps {downloadUrl, thumbnailUrl} in the same order as input files
  /// Maximum 10 images per media group (Telegram limit)
  /// Files must already be compressed (from ImageCacheService)
  ///
  /// IMPORTANT: Accepts both List<File> and List<ImageItem>
  Future<List<Map<String, String>>> uploadMediaGroup(
      List<dynamic> imageInputs) async {
    // Lazy validation - check config on first upload attempt
    if (!isConfigured) {
      throw TelegramConfigMissingException();
    }

    if (imageInputs.isEmpty) {
      throw ArgumentError('imageInputs cannot be empty');
    }

    if (imageInputs.length > 10) {
      throw ArgumentError('Maximum 10 images per media group (Telegram limit)');
    }

    // Extract files to upload (already compressed)
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

    // Upload as media group with retry logic
    final uploadResults = await _uploadMediaGroupWithRetry(filesToUpload);

    // Get URLs for all images (full + thumbnail)
    final urlMaps = <Map<String, String>>[];
    for (final result in uploadResults) {
      final downloadUrl = await _getFileUrl(result['largestFileId']!);
      final thumbnailUrl = await _getFileUrl(result['smallestFileId']!);
      urlMaps.add({
        'downloadUrl': downloadUrl,
        'thumbnailUrl': thumbnailUrl,
      });
    }

    return urlMaps;
  }

  /// Upload file to Telegram with retry logic for transient errors
  /// Returns map with largestFileId and smallestFileId
  Future<Map<String, String>> _uploadWithRetry(File fileToUpload) async {
    const maxRetries = 3;
    const retryDelays = [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ];

    Exception? lastException;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Prepare multipart form data
        final formData = FormData.fromMap({
          'chat_id': _chatId,
          'photo': await MultipartFile.fromFile(
            fileToUpload.path,
            filename: path.basename(fileToUpload.path),
          ),
        });

        // Send photo to Telegram
        final response = await _dio.post(
          '$_baseUrl/bot$_botToken/sendPhoto',
          data: formData,
        );

        // Parse response
        final responseData = response.data;
        if (responseData['ok'] == true && responseData['result'] != null) {
          final photos = responseData['result']['photo'] as List;
          if (photos.isNotEmpty) {
            // Get file_id from largest photo (last in array)
            final largestFileId = photos.last['file_id'] as String;
            // Get file_id from second smallest photo (index 1, ~320x180) for thumbnail
            // Index 0 (~90x51) quá nhỏ, index 1 (~320x180) vừa phải cho thumbnail
            final smallestFileId = (photos.length > 1
                ? photos[1]['file_id']
                : photos.first['file_id']) as String;
            return {
              'largestFileId': largestFileId,
              'smallestFileId': smallestFileId,
            };
          }
        }

        throw TelegramApiException(
          message: 'Invalid response format from Telegram API',
          statusCode: response.statusCode,
          responseBody: jsonEncode(responseData),
        );
      } on DioException catch (e) {
        lastException = e;
        final statusCode = e.response?.statusCode;

        // Handle specific HTTP status codes
        if (statusCode == 401 || statusCode == 403) {
          throw TelegramInvalidTokenException(statusCode: statusCode);
        } else if (statusCode == 400) {
          throw TelegramChatNotFoundException(statusCode: statusCode);
        } else if (statusCode == 413) {
          throw TelegramFileTooLargeException(statusCode: statusCode);
        }

        // Check if error is retryable (transient network errors)
        final isRetryable = statusCode == 408 ||
            statusCode == 502 ||
            statusCode == 503 ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError;

        if (!isRetryable || attempt == maxRetries - 1) {
          // Non-retryable error or last attempt - throw exception
          throw TelegramApiException(
            message: e.message ?? 'Telegram upload failed',
            statusCode: statusCode,
            responseBody: e.response?.data?.toString(),
          );
        }

        // Wait before retrying
        await Future.delayed(retryDelays[attempt]);
      } catch (e) {
        lastException = e as Exception;
        if (attempt == maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(retryDelays[attempt]);
      }
    }

    throw lastException ??
        Exception('Upload failed after $maxRetries attempts');
  }

  /// Upload multiple files as media group to Telegram with retry logic
  /// Returns list of maps with largestFileId and smallestFileId for each image
  Future<List<Map<String, String>>> _uploadMediaGroupWithRetry(
      List<File> compressedFiles) async {
    const maxRetries = 3;
    const retryDelays = [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ];

    Exception? lastException;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Prepare media array for sendMediaGroup
        final mediaArray = <Map<String, dynamic>>[];

        for (int i = 0; i < compressedFiles.length; i++) {
          mediaArray.add({
            'type': 'photo',
            'media': 'attach://photo$i',
          });
        }

        // Prepare multipart form data with all photos
        final formDataMap = <String, dynamic>{
          'chat_id': _chatId,
          'media': jsonEncode(mediaArray),
        };

        // Add all photo files
        for (int i = 0; i < compressedFiles.length; i++) {
          final file = compressedFiles[i];
          formDataMap['photo$i'] = await MultipartFile.fromFile(
            file.path,
            filename: path.basename(file.path),
          );
        }

        final formData = FormData.fromMap(formDataMap);

        // Send media group to Telegram
        final response = await _dio.post(
          '$_baseUrl/bot$_botToken/sendMediaGroup',
          data: formData,
        );

        // Parse response to get file_ids in correct order
        final responseData = response.data;
        if (responseData['ok'] == true && responseData['result'] != null) {
          final results = responseData['result'] as List;

          // Extract file_ids from each result
          final uploadResults = <Map<String, String>>[];
          for (final result in results) {
            final photos = result['photo'] as List;
            if (photos.isNotEmpty) {
              // Get file_id from largest photo (last in array)
              final largestFileId = photos.last['file_id'] as String;
              // Get file_id from second smallest photo (index 1, ~320x180) for thumbnail
              // Index 0 (~90x51) quá nhỏ, index 1 (~320x180) vừa phải cho thumbnail
              final smallestFileId = (photos.length > 1
                  ? photos[1]['file_id']
                  : photos.first['file_id']) as String;
              uploadResults.add({
                'largestFileId': largestFileId,
                'smallestFileId': smallestFileId,
              });
            }
          }

          if (uploadResults.length == compressedFiles.length) {
            return uploadResults;
          }
        }

        throw TelegramApiException(
          message: 'Invalid response format from Telegram API',
          statusCode: response.statusCode,
          responseBody: jsonEncode(responseData),
        );
      } on DioException catch (e) {
        lastException = e;
        final statusCode = e.response?.statusCode;

        // Handle specific HTTP status codes
        if (statusCode == 401 || statusCode == 403) {
          throw TelegramInvalidTokenException(statusCode: statusCode);
        } else if (statusCode == 400) {
          throw TelegramChatNotFoundException(statusCode: statusCode);
        } else if (statusCode == 413) {
          throw TelegramFileTooLargeException(statusCode: statusCode);
        }

        // Check if error is retryable (transient network errors)
        final isRetryable = statusCode == 408 ||
            statusCode == 502 ||
            statusCode == 503 ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError;

        if (!isRetryable || attempt == maxRetries - 1) {
          // Non-retryable error or last attempt - throw exception
          throw TelegramApiException(
            message: e.message ?? 'Telegram media group upload failed',
            statusCode: statusCode,
            responseBody: e.response?.data?.toString(),
          );
        }

        // Wait before retrying
        await Future.delayed(retryDelays[attempt]);
      } catch (e) {
        lastException = e as Exception;
        if (attempt == maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(retryDelays[attempt]);
      }
    }

    throw lastException ??
        Exception('Media group upload failed after $maxRetries attempts');
  }

  /// Get full download URL from Telegram using file_id
  Future<String> _getFileUrl(String fileId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/bot$_botToken/getFile',
        queryParameters: {'file_id': fileId},
      );

      final responseData = response.data;
      if (responseData['ok'] == true && responseData['result'] != null) {
        final filePath = responseData['result']['file_path'] as String;
        // Return full URL with token
        return '$_baseUrl/file/bot$_botToken/$filePath';
      }

      throw TelegramApiException(
        message: 'Failed to get file URL from Telegram',
        statusCode: response.statusCode,
        responseBody: jsonEncode(responseData),
      );
    } on DioException catch (e) {
      throw TelegramApiException(
        message: 'Failed to get file URL: ${e.message}',
        statusCode: e.response?.statusCode,
        responseBody: e.response?.data?.toString(),
      );
    }
  }
}
