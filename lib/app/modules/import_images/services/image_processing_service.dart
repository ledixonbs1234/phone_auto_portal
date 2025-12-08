import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// Safe logging function that only prints in debug mode
void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

/// Service xử lý ảnh: Detect hướng chữ và xoay ảnh
class ImageProcessingService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Detect hướng chữ trong ảnh và trả về góc xoay cần thiết (0, 90, 180, 270)
  Future<int> detectTextOrientation(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.blocks.isEmpty) {
        _debugLog('⚠️ Không phát hiện text trong ảnh');
        return 0; // Không có text, giữ nguyên
      }

      // Phân tích góc của text block dài nhất (chính xác hơn)
      TextBlock? longestBlock;
      int maxTextLength = 0;

      for (var block in recognizedText.blocks) {
        final textLength = block.text.length;
        if (textLength > maxTextLength) {
          maxTextLength = textLength;
          longestBlock = block;
        }
      }

      if (longestBlock == null) return 0;

      // Tính góc của block dài nhất
      final angle = _calculateBlockAngle(longestBlock);
      _debugLog(
          '📐 Text block dài nhất (${longestBlock.text.substring(0, longestBlock.text.length > 20 ? 20 : longestBlock.text.length)}...): angle = $angle°');

      // Chuẩn hóa góc text hiện tại
      final textAngle = _normalizeRotationAngle(angle);
      _debugLog('📏 Text đang ở góc: $textAngle°');

      // Tính góc cần xoay để chữ thẳng đứng (xoay ngược lại)
      final rotationNeeded = _calculateCorrectionAngle(textAngle);
      _debugLog('🔄 Cần xoay: $rotationNeeded° để chữ thẳng đứng');

      return rotationNeeded;
    } catch (e) {
      _debugLog('❌ Lỗi khi detect text orientation: $e');
      return 0;
    }
  }

  /// Tính góc cần xoay để chữ thẳng đứng (correction angle)
  int _calculateCorrectionAngle(int textCurrentAngle) {
    // Nếu text đang ở góc X, cần xoay ngược lại để về 0°
    switch (textCurrentAngle) {
      case 0:
        return 0; // Text đã thẳng, không cần xoay
      case 90:
        return 270; // Text nghiêng 90° → xoay -90° = 270°
      case 180:
        return 180; // Text ngược 180° → xoay 180°
      case 270:
        return 90; // Text nghiêng 270° → xoay -270° = 90°
      default:
        return 0;
    }
  }

  /// Tính góc nghiêng của text block
  double _calculateBlockAngle(TextBlock block) {
    final corners = block.cornerPoints;
    if (corners.length < 2) return 0;

    // Tính góc từ 2 điểm đầu tiên
    final dx = corners[1].x - corners[0].x;
    final dy = corners[1].y - corners[0].y;

    return math.atan2(dy, dx) * 180 / math.pi;
  }

  /// Chuẩn hóa góc thành 0, 90, 180, hoặc 270
  int _normalizeRotationAngle(double angle) {
    // Normalize về khoảng [0, 360)
    angle = angle % 360;
    if (angle < 0) angle += 360;

    // Làm tròn về góc gần nhất
    if (angle >= 315 || angle < 45) {
      return 0;
    } else if (angle >= 45 && angle < 135) {
      return 90;
    } else if (angle >= 135 && angle < 225) {
      return 180;
    } else {
      return 270;
    }
  }

  /// Xoay ảnh theo góc chỉ định
  Future<File> rotateImage(File imageFile, int rotationAngle) async {
    if (rotationAngle == 0) {
      return imageFile; // Không cần xoay
    }

    try {
      // Đọc ảnh
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Không thể decode ảnh');
      }

      // Xoay ảnh
      img.Image rotated;
      switch (rotationAngle) {
        case 90:
          rotated = img.copyRotate(image, angle: 90);
          break;
        case 180:
          rotated = img.copyRotate(image, angle: 180);
          break;
        case 270:
          rotated = img.copyRotate(image, angle: 270);
          break;
        default:
          rotated = image;
      }

      // Lưu ảnh đã xoay vào thư mục temp
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(imageFile.path);
      final rotatedPath = path.join(tempDir.path,
          '${path.basenameWithoutExtension(fileName)}_rotated.jpg');
      final rotatedFile = File(rotatedPath);
      await rotatedFile.writeAsBytes(img.encodeJpg(rotated, quality: 95));

      return rotatedFile;
    } catch (e) {
      _debugLog('Lỗi khi xoay ảnh: $e');
      rethrow;
    }
  }

  /// Compress ảnh trước khi upload
  Future<File> compressImage(File imageFile, {int quality = 85}) async {
    try {
      // Lưu vào thư mục temp
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(imageFile.path);
      final targetPath = path.join(tempDir.path,
          '${path.basenameWithoutExtension(fileName)}_compressed.jpg');

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (compressedFile == null) {
        throw Exception('Không thể compress ảnh');
      }

      return File(compressedFile.path);
    } catch (e) {
      _debugLog('Lỗi khi compress ảnh: $e');
      return imageFile; // Trả về ảnh gốc nếu compress thất bại
    }
  }

  /// Workflow hoàn chỉnh: Detect orientation -> Rotate (không compress để giữ chất lượng)
  Future<ProcessedImageResult> processImage(File imageFile) async {
    File? tempRotatedFile;

    try {
      // 1. Detect orientation
      final rotationAngle = await detectTextOrientation(imageFile);

      // 2. Rotate nếu cần (không compress để giữ chất lượng OCR)
      File processedFile = imageFile;
      if (rotationAngle != 0) {
        tempRotatedFile = await rotateImage(imageFile, rotationAngle);
        processedFile = tempRotatedFile;
      }

      return ProcessedImageResult(
        file: processedFile,
        rotationAngle: rotationAngle,
        isSuccess: true,
        tempFiles: tempRotatedFile != null ? [tempRotatedFile] : [],
      );
    } catch (e) {
      // Xóa file tạm nếu có lỗi
      if (tempRotatedFile != null && await tempRotatedFile.exists()) {
        await tempRotatedFile.delete();
      }

      return ProcessedImageResult(
        file: imageFile,
        rotationAngle: 0,
        isSuccess: false,
        errorMessage: e.toString(),
        tempFiles: [],
      );
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Kết quả xử lý ảnh
class ProcessedImageResult {
  final File file;
  final int rotationAngle;
  final bool isSuccess;
  final String? errorMessage;
  final List<File> tempFiles; // Danh sách file tạm cần xóa sau khi upload

  ProcessedImageResult({
    required this.file,
    required this.rotationAngle,
    required this.isSuccess,
    this.errorMessage,
    required this.tempFiles,
  });
}
