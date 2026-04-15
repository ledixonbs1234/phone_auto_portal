import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:get/get.dart';

// Safe logging function that only prints in debug mode
void _debugLog(String message) {
  if (kDebugMode) {
    message.printInfo();
  }
}

/// Service đọc mã hiệu: Ưu tiên Barcode, fallback sang OCR
class BarcodeOcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Pattern để validate mã hiệu
  static const String maHieuPattern = r'^[cCreEpP][a-zA-Z]\d{9}[vV][nN]$';
  static final RegExp _maHieuRegex = RegExp(maHieuPattern);

  /// Validate mã hiệu
  bool isValidMaHieu(String maHieu) {
    return _maHieuRegex.hasMatch(maHieu.trim());
  }

  /// Đọc text từ ảnh bằng OCR (fallback method)
  Future<String?> readTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.blocks.isEmpty) {
        return null;
      }

      // Lấy tất cả text blocks và tìm mã hiệu hợp lệ
      final candidates = <String>[];

      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          // Lấy text và xử lý
          final text = line.text.trim().replaceAll(' ', '').toUpperCase();

          // Validate mã hiệu
          if (isValidMaHieu(text)) {
            candidates.add(text);
          }

          // Thử với từng element
          for (var element in line.elements) {
            final elementText =
                element.text.trim().replaceAll(' ', '').toUpperCase();
            if (isValidMaHieu(elementText)) {
              candidates.add(elementText);
            }
          }
        }
      }

      // Trả về mã hiệu đầu tiên tìm thấy
      return candidates.isNotEmpty ? candidates.first : null;
    } catch (e) {
      _debugLog('Lỗi khi đọc OCR: $e');
      return null;
    }
  }

  /// Workflow hoàn chỉnh: Barcode -> OCR -> Validate
  Future<MaHieuReadResult> readMaHieu(File imageFile) async {
    try {
      // 2. Fallback sang OCR
      String? maHieu = await readTextFromImage(imageFile);

      if (maHieu != null) {
        return MaHieuReadResult(
          maHieu: maHieu.toUpperCase(),
          method: ReadMethod.ocr,
          isSuccess: true,
        );
      }

      // 3. Không đọc được
      return MaHieuReadResult(
        maHieu: null,
        method: ReadMethod.none,
        isSuccess: false,
        errorMessage: 'Không tìm thấy mã hiệu hợp lệ trong ảnh',
      );
    } catch (e) {
      return MaHieuReadResult(
        maHieu: null,
        method: ReadMethod.none,
        isSuccess: false,
        errorMessage: 'Lỗi khi đọc mã hiệu: $e',
      );
    }
  }

  /// Thử đọc với nhiều pattern khác nhau (cho trường hợp OCR sai)
  Future<String?> readWithPatternCorrection(File imageFile) async {
    final result = await readMaHieu(imageFile);

    if (result.isSuccess) {
      return result.maHieu;
    }

    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Phương thức đọc mã hiệu
enum ReadMethod {
  barcode,
  ocr,
  none,
}

/// Kết quả đọc mã hiệu
class MaHieuReadResult {
  final String? maHieu;
  final ReadMethod method;
  final bool isSuccess;
  final String? errorMessage;

  MaHieuReadResult({
    required this.maHieu,
    required this.method,
    required this.isSuccess,
    this.errorMessage,
  });

  String get methodName {
    switch (method) {
      case ReadMethod.barcode:
        return 'Barcode';
      case ReadMethod.ocr:
        return 'OCR';
      case ReadMethod.none:
        return 'None';
    }
  }
}
