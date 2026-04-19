import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';

import '../controllers/capture_image_controller.dart';

class CaptureImageView extends GetView<CaptureImageController> {
  const CaptureImageView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppTheme.buildAppBar(
        title: 'Chụp Ảnh',
        onBack: () => Get.back(),
      ),
      body: Obx(() {
        if (!controller.isCameraInitialized.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          );
        }

        if (controller.isProcessing.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppTheme.accentCyan),
                const SizedBox(height: 16),
                Text(
                  'Đang xử lý ảnh...',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            CameraPreview(controller.cameraController!),

            // Flash toggle
            Positioned(
              top: 40,
              left: 20,
              child: GestureDetector(
                onTap: controller.toggleFlash,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: controller.isFlashOn.value
                          ? AppTheme.warningOrange.withValues(alpha: 0.5)
                          : AppTheme.dividerColor,
                    ),
                  ),
                  child: Icon(
                    controller.isFlashOn.value
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: controller.isFlashOn.value
                        ? AppTheme.warningOrange
                        : AppTheme.textSecondary,
                    size: 24,
                  ),
                ),
              ),
            ),

            // Capture count badge
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_camera_rounded,
                        color: AppTheme.accentCyan, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Đã chụp: ${controller.capturedCount.value}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Capture button
            Positioned(
              bottom: 40,
              child: GestureDetector(
                onTap: controller.takePicture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFE0E0E0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                      width: 3,
                    ),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppTheme.primaryDark, size: 32),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
