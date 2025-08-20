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
          // Hiển thị số lượng ảnh đã chụp
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Đã chụp: ${controller.capturedImageCount.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )),
          // Nút reset bộ đếm
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.resetCaptureCount,
            tooltip: 'Reset bộ đếm',
          ),
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

        // Luôn hiển thị camera preview, không hiển thị image preview nữa
        return _buildCameraPreview();
      }),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      children: [
        // Camera preview
        SizedBox(
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Nút chụp ảnh
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
              // Nút gửi message
              FloatingActionButton.extended(
                onPressed: controller.sendSubmitMessage,
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.send),
                label: const Text('Gửi Submit'),
              ),
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
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Đưa camera về phía thư/bưu phẩm để quét thông tin.\nSau khi chụp, ảnh sẽ được xử lý tự động và bạn có thể tiếp tục chụp ảnh khác.',
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
}
