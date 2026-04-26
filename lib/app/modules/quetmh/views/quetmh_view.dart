import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';
import '../controllers/quetmh_controller.dart';

class QuetmhView extends GetView<QuetmhController> {
  const QuetmhView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppTheme.buildAppBar(
        title: 'Quét Mã Hóa',
        onBack: () => Get.back(),
        centerTitle: true,
        actions: [
          AppTheme.appBarAction(
            icon: Icons.flash_on_rounded,
            onPressed: () => controller.toggleFlash(),
            color: AppTheme.warningOrange,
          ),
          AppTheme.appBarAction(
            icon: Icons.switch_camera_rounded,
            onPressed: () => controller.toggleCamera(),
            color: AppTheme.accentCyan,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          AppTheme.gradientSeparator(),

          // ── Scanner Area ──
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller.scannerController,
                  onDetect: controller.onBarcodeDetect,
                ),
                // Scan frame
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accentCyan.withValues(alpha: 0.7),
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
                // Scan count badge
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.accentCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Obx(() => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_scanner_rounded,
                                  color: AppTheme.accentCyan, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Đã quét: ${controller.totalScanned.value} mã',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Control Panel ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(
                top: BorderSide(
                  color: AppTheme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Text(
                    'Gửi lệnh điều khiển',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Command Buttons Row 1 ──
                  Row(
                    children: [
                      _buildCommandButton(
                        label: 'mokntb',
                        icon: Icons.looks_one_rounded,
                        color: AppTheme.primaryBlue,
                        onPressed: () => controller.sendMokntb(),
                      ),
                      const SizedBox(width: 8),
                      _buildCommandButton(
                        label: 'moemsntb',
                        icon: Icons.looks_two_rounded,
                        color: AppTheme.successGreen,
                        onPressed: () => controller.sendMoemsntb(),
                      ),
                      const SizedBox(width: 8),
                      _buildCommandButton(
                        label: 'inbd8',
                        icon: Icons.looks_3_rounded,
                        color: AppTheme.warningOrange,
                        onPressed: () => controller.sendInbd8(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Control Buttons Row 2 ──
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => controller.toggleScanning(),
                            borderRadius: BorderRadius.circular(12),
                            child: Obx(() => Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF9B5DE5),
                                        const Color(0xFF9B5DE5)
                                            .withValues(alpha: 0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF9B5DE5)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        controller.isScanning.value
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        controller.isScanning.value
                                            ? 'Tạm dừng'
                                            : 'Tiếp tục',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => controller.resetCounter(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.textSecondary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.textSecondary
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded,
                                      color: AppTheme.textSecondary,
                                      size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Reset đếm',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}