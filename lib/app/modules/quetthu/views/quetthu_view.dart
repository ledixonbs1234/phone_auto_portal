import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quetthu_controller.dart';

class QuetThuView extends GetView<QuetThuController> {
  const QuetThuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét Thư'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (controller.cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_android),
              onPressed: controller.switchCamera,
            ),
        ],
      ),
      body: Obx(() {
        if (!controller.isInitialized.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang khởi tạo camera...'),
              ],
            ),
          );
        }

        if (controller.capturedImagePath.value.isNotEmpty) {
          return _buildImagePreview();
        }

        return _buildCameraPreview();
      }),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      children: [
        // Camera preview
        Container(
          width: double.infinity,
          height: double.infinity,
          child: controller.cameraController?.buildPreview() ?? Container(),
        ),
        // Overlay with capture button
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(() => FloatingActionButton.extended(
                    onPressed: controller.isProcessing.value
                        ? null
                        : controller.captureImage,
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    icon: controller.isProcessing.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(controller.isProcessing.value
                        ? 'Đang xử lý...'
                        : 'Chụp ảnh'),
                  )),
            ],
          ),
        ),
        // Instructions overlay
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Đưa camera về phía thư/bưu phẩm để quét thông tin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            child: Image.file(
              File(controller.capturedImagePath.value),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: controller.retakePhoto,
                icon: const Icon(Icons.refresh),
                label: const Text('Chụp lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.check),
                label: const Text('Xong'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
