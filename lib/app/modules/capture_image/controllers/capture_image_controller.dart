import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class CaptureImageController extends GetxController {
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  final isCameraInitialized = false.obs;
  final isProcessing = false.obs;
  final capturedCount = 0.obs;
  final capturedImagePaths = <String>[].obs;

  // MethodChannel để nhận sự kiện phím volume từ native Android
  static const _volumeChannel =
      MethodChannel('com.example.phone_auto_portal/volume');

  @override
  void onInit() {
    super.onInit();
    _initializeCamera();
    _listenVolumeKeys();
  }

  void _listenVolumeKeys() {
    _volumeChannel.setMethodCallHandler((call) async {
      if (call.method == 'volumeKeyPressed') {
        takePicture();
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        cameraController = CameraController(
          cameras![0],
          ResolutionPreset.ultraHigh,
          enableAudio: false,
        );
        await cameraController!.initialize();
        isCameraInitialized.value = true;

        // Tự động lưu ảnh đánh dấu khi bắt đầu phiên chụp
        await _saveMarkerImage();
      } else {
        Get.snackbar("Lỗi", "Không tìm thấy camera trên thiết bị");
      }
    } catch (e) {
      Get.snackbar("Lỗi Camera", "Không thể khởi tạo camera: $e");
    }
  }

  Future<void> takePicture() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    if (cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      // Chỉ đợi lấy ảnh từ sensor camera
      final XFile imageFile = await cameraController!.takePicture();

      // Phản hồi rung nhẹ khi chụp
      HapticFeedback.mediumImpact();

      // Gọi xử lý ảnh và lưu file bất đồng bộ (không dùng await)
      // Giúp giao diện không bị chặn và có thể ấn chụp liên tục
      _processAndSaveImage(imageFile.path);
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể chụp ảnh: $e");
    }
  }

  Future<void> _processAndSaveImage(String originalPath) async {
    try {
      // Dùng flutter_image_compress (native API) để:
      // - Tự động bake EXIF orientation vào pixels
      // - Strip toàn bộ EXIF metadata
      // - Giữ nguyên định dạng JPG, nhanh hơn rất nhiều so với Dart image package
      final directory = await getApplicationDocumentsDirectory();
      final String newPath =
          '${directory.path}/IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
        originalPath,
        newPath,
        quality: 95,
        autoCorrectionAngle: true, // Tự động xoay ảnh theo EXIF orientation
        keepExif: false, // Xóa toàn bộ EXIF để tránh bị xoay lại
      );

      if (compressedFile != null) {
        try {
          // Lưu file vào thư viện ảnh công khai sử dụng Gal
          await Gal.putImage(compressedFile.path);
          capturedCount.value++;
          capturedImagePaths.add(compressedFile.path);
        } on GalException catch (e) {
          Get.snackbar("Lỗi", "Không thể lưu ảnh: ${e.type.message}",
              snackPosition: SnackPosition.BOTTOM);
        } catch (e) {
          Get.snackbar("Lỗi", "Xảy ra lỗi lưu ảnh: $e",
              snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        Get.snackbar("Lỗi", "Không thể xử lý ảnh.");
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Xảy ra lỗi khi xử lý ảnh: $e");
    }
  }

  Future<void> _saveMarkerImage() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Vẽ nền chữ nhật màu đỏ
      final paint = ui.Paint()..color = const ui.Color(0xFFE53935);
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 1000, 1000), paint);

      // Vẽ chữ đánh dấu ở giữa
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'BẮT ĐẦU\nCHỤP ẢNH',
          style: TextStyle(
            color: ui.Color(0xFFFFFFFF),
            fontSize: 120,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        ui.Offset(
          (1000 - textPainter.width) / 2,
          (1000 - textPainter.height) / 2,
        ),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(1000, 1000);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        final directory = await getApplicationDocumentsDirectory();
        final String newPath =
            '${directory.path}/MARKER_${DateTime.now().millisecondsSinceEpoch}.png';
        final File newFile = File(newPath);
        await newFile.writeAsBytes(buffer);

        // Lưu ảnh marker vào thư viện
        await Gal.putImage(newPath);
        // Tùy chọn: có thể tăng biến count hoặc thêm vào danh sách, nhưng ảnh marker phụ thường
        // không cần đếm vào số lượng ảnh thực tế của người dùng.
      }
    } catch (e) {
      Get.log("Lỗi tạo ảnh đánh dấu: $e");
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}
