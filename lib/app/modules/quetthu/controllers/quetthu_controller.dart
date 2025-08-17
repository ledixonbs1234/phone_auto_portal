import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:phone_auto_portal/app/modules/home/GeminiChatService.dart';

class QuetThuController extends GetxController {
  CameraController? cameraController;
  final isInitialized = false.obs;
  final isProcessing = false.obs;
  final capturedImagePath = ''.obs;

  List<CameraDescription> cameras = [];
  late GeminiChatService geminiSevice;

  // --- THAY THẾ BẰNG KHÓA API CỦA BẠN ---
  final String _geminiApiKey = 'AIzaSyA4nh1XgptxJGC6RRTXJ0cht9iRJEQqG30';
  // ------------------------------------

  final String _modelId = 'gemini-2.0-flash'; // Hoặc 'gemini-1.5-flash'
  late final Uri _apiUrl = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelId:streamGenerateContent?key=$_geminiApiKey');

  @override
  void onInit() {
    super.onInit();
    // Delay camera initialization to ensure platform is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      initializeCamera();
    });
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    geminiSevice = GeminiChatService(apiUrl: _apiUrl.toString());
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }

  Future<void> initializeCamera() async {
    try {
      // Add platform check
      if (GetPlatform.isAndroid || GetPlatform.isIOS) {
        cameras = await availableCameras();
        if (cameras.isNotEmpty) {
          cameraController = CameraController(
            cameras[0],
            ResolutionPreset.high,
            enableAudio: false,
          );

          await cameraController!.initialize();
          isInitialized.value = true;

          Get.snackbar(
            'Camera',
            'Camera đã sẵn sàng',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 1),
          );
        } else {
          Get.snackbar(
            'Lỗi Camera',
            'Không tìm thấy camera nào trên thiết bị',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        // For web or desktop, show a placeholder
        Get.snackbar(
          'Thông báo',
          'Camera chỉ hoạt động trên thiết bị di động',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi Camera',
        'Không thể khởi tạo camera: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _requestCameraPermission() async {
    // Camera permissions are handled automatically by the camera plugin
    // This is just a placeholder for any future permission handling
  }

  Future<void> captureImage() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      Get.snackbar(
        'Lỗi',
        'Camera chưa được khởi tạo',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isProcessing.value = true;

      final XFile image = await cameraController!.takePicture();
      capturedImagePath.value = image.path;
      //convert image to file
      final File imageFile = File(capturedImagePath.value);

      if (isGeminiRunFirst) {
        isGeminiRunFirst = false;
        await geminiSevice.extractInfoFromImage(imageFile);
      } else {
        geminiSevice.askFollowUp(imageFile);
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi chụp ảnh',
        'Không thể chụp ảnh: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  void retakePhoto() {
    capturedImagePath.value = '';
  }

  void switchCamera() async {
    if (cameras.length > 1) {
      try {
        await cameraController?.dispose();

        final currentCamera = cameraController?.description;
        final newCamera = cameras.firstWhere(
          (camera) => camera != currentCamera,
          orElse: () => cameras[0],
        );

        cameraController = CameraController(
          newCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await cameraController!.initialize();
        update();
      } catch (e) {
        Get.snackbar(
          'Lỗi',
          'Không thể chuyển camera: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  // Fallback method using image picker if camera initialization fails
  Future<void> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        capturedImagePath.value = image.path;
        isProcessing.value = true;
        File imageFile = File(capturedImagePath.value);

        if (isGeminiRunFirst) {
          isGeminiRunFirst = false;
          await geminiSevice.extractInfoFromImage(imageFile);
        } else {
          geminiSevice.askFollowUp(imageFile);
        }
        isProcessing.value = false;

        Get.snackbar(
          'Thành công',
          'Đã xử lý ảnh từ thư viện',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isProcessing.value = false;
      Get.snackbar(
        'Lỗi',
        'Không thể chọn ảnh: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  bool isGeminiRunFirst = true;

  // Method to take photo from camera using image picker
  Future<void> takePhotoFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        capturedImagePath.value = image.path;
        isProcessing.value = true;

        final File imageFile = File(capturedImagePath.value);

        if (isGeminiRunFirst) {
          isGeminiRunFirst = false;
          await geminiSevice.extractInfoFromImage(imageFile);
        } else {
          geminiSevice.askFollowUp(imageFile);
        }
        // Process image with AI (for now, using mock data)
        isProcessing.value = false;

        Get.snackbar(
          'Thành công',
          'Đã chụp và xử lý ảnh',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isProcessing.value = false;
      Get.snackbar(
        'Lỗi',
        'Không thể chụp ảnh: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
