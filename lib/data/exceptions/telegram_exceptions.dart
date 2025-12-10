/// Custom exceptions for Telegram Bot API operations

/// Thrown when Telegram configuration (bot token or chat ID) is missing from Firebase
class TelegramConfigMissingException implements Exception {
  final String message;

  TelegramConfigMissingException(
      [this.message =
          'Thiếu cấu hình Telegram trong Firebase. Vui lòng khởi động lại ứng dụng.']);

  @override
  String toString() => 'TelegramConfigMissingException: $message';
}

/// Thrown when Telegram bot token is invalid (401/403 errors)
class TelegramInvalidTokenException implements Exception {
  final String message;
  final int? statusCode;

  TelegramInvalidTokenException(
      {this.statusCode,
      this.message =
          'Token Telegram không hợp lệ (401/403). Kiểm tra cấu hình.'});

  @override
  String toString() =>
      'TelegramInvalidTokenException: $message (Status: $statusCode)';
}

/// Thrown when Telegram chat is not found (400 error)
class TelegramChatNotFoundException implements Exception {
  final String message;
  final int? statusCode;

  TelegramChatNotFoundException(
      {this.statusCode, this.message = 'Không tìm thấy chat Telegram (400).'});

  @override
  String toString() =>
      'TelegramChatNotFoundException: $message (Status: $statusCode)';
}

/// Thrown when file size exceeds Telegram's limit (413 error)
class TelegramFileTooLargeException implements Exception {
  final String message;
  final int? statusCode;

  TelegramFileTooLargeException(
      {this.statusCode,
      this.message = 'File ảnh quá lớn (413). Telegram giới hạn 10MB.'});

  @override
  String toString() =>
      'TelegramFileTooLargeException: $message (Status: $statusCode)';
}

/// Generic Telegram API exception with status code and response message
class TelegramApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  TelegramApiException({
    required this.message,
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() {
    final buffer = StringBuffer('TelegramApiException: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    if (responseBody != null && responseBody!.isNotEmpty) {
      buffer.write(' - Response: $responseBody');
    }
    return buffer.toString();
  }
}

/// Thrown when batch upload fails, includes list of successfully uploaded image IDs for rollback
class TelegramBatchUploadFailedException implements Exception {
  final String message;
  final List<String> successfulImageIds;
  final Exception? originalException;

  TelegramBatchUploadFailedException({
    required this.message,
    this.successfulImageIds = const [],
    this.originalException,
  });

  @override
  String toString() {
    final buffer = StringBuffer('TelegramBatchUploadFailedException: $message');
    if (successfulImageIds.isNotEmpty) {
      buffer.write(
          ' (Uploaded ${successfulImageIds.length} images before failure)');
    }
    if (originalException != null) {
      buffer.write(' - Caused by: $originalException');
    }
    return buffer.toString();
  }
}
