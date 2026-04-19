import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';
import '../controllers/quetthu_controller.dart';

class QuetThuView extends GetView<QuetThuController> {
  const QuetThuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppTheme.buildAppBar(
        title: 'Quét Thư',
        onBack: () => Get.back(),
        centerTitle: true,
        actions: [
          // Captured count badge
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.accentCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Đã chụp: ${controller.capturedImageCount.value}',
                      style: const TextStyle(
                        color: AppTheme.accentCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )),
          AppTheme.appBarAction(
            icon: Icons.refresh_rounded,
            onPressed: controller.resetCaptureCount,
            color: AppTheme.warningOrange,
          ),
          if (controller.cameras.length > 1)
            AppTheme.appBarAction(
              icon: Icons.flip_camera_android_rounded,
              onPressed: controller.switchCamera,
              color: AppTheme.primaryBlue,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (!controller.isInitialized.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                    color: AppTheme.primaryBlue),
                const SizedBox(height: 16),
                Text(
                  'Đang khởi tạo camera...',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

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

        // Instructions overlay
        Positioned(
          top: 30,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: const Text(
              'Đưa camera về phía thư/bưu phẩm để quét thông tin.\nSau khi chụp, ảnh sẽ được xử lý tự động.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Bottom action buttons
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Capture button
              Obx(() => _buildFloatingButton(
                    icon: controller.isProcessing.value
                        ? null
                        : Icons.camera_alt_rounded,
                    label: controller.isProcessing.value
                        ? 'Đang xử lý...'
                        : 'Chụp ảnh',
                    color: AppTheme.primaryBlue,
                    isLoading: controller.isProcessing.value,
                    onPressed: controller.isProcessing.value
                        ? null
                        : controller.captureImage,
                  )),
              // Submit button
              _buildFloatingButton(
                icon: Icons.send_rounded,
                label: 'Gửi Submit',
                color: AppTheme.warningOrange,
                onPressed: controller.sendSubmitMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingButton({
    IconData? icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: onPressed != null
                ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.85)],
                  )
                : null,
            color: onPressed == null
                ? color.withValues(alpha: 0.3)
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: onPressed != null
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else if (icon != null)
                Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
