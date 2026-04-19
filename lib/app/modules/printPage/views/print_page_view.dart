import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';

import '../controllers/print_page_controller.dart';

class PrintPageView extends GetView<PrintPageController> {
  const PrintPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppTheme.buildAppBar(
        title: 'In Mã Hiệu',
        onBack: () => Get.back(),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AppTheme.gradientSeparator(),
            const SizedBox(height: 12),
            _buildInputSection(),
            const SizedBox(height: 16),
            _buildMaHieuList(),
            const SizedBox(height: 16),
            _buildButtonSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return AppTheme.cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhập mã hiệu',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.maHieuController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: AppTheme.inputDecoration(
                    label: '',
                    hint: 'VD: CA123456789VN',
                    prefixIcon: Icons.qr_code_rounded,
                    suffix: IconButton(
                      icon: const Icon(Icons.add_rounded,
                          color: AppTheme.accentCyan),
                      onPressed: controller.addMaHieuFromInput,
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => controller.addMaHieuFromInput(),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: controller.startBulkQRScanInDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.warningOrange, Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppTheme.warningOrange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.qr_code_scanner_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Quét QR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaHieuList() {
    return Expanded(
      child: AppTheme.cardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Row(
                      children: [
                        const Text(
                          'Danh sách ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${controller.scannedMaHieus.length}',
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    )),
                GestureDetector(
                  onTap: controller.clearAllMaHieus,
                  child: Row(
                    children: [
                      Icon(Icons.clear_all_rounded,
                          color: AppTheme.dangerRed.withValues(alpha: 0.7),
                          size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Xóa tất cả',
                        style: TextStyle(
                          color: AppTheme.dangerRed.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (controller.scannedMaHieus.isEmpty) {
                  return AppTheme.emptyState(
                    icon: Icons.qr_code_2_rounded,
                    title: 'Chưa có mã hiệu nào',
                    subtitle: 'Nhập thủ công hoặc quét QR để thêm',
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.scannedMaHieus.length,
                  itemBuilder: (context, index) {
                    final maHieu = controller.scannedMaHieus[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.dividerColor
                                .withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              maHieu,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontFamily: 'monospace',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => controller.removeMaHieu(maHieu),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.dangerRed
                                  .withValues(alpha: 0.6),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonSection() {
    return Obx(() => Row(
          children: [
            AppTheme.gradientButton(
              icon: Icons.print_rounded,
              label: controller.scannedMaHieus.isNotEmpty
                  ? 'In ${controller.scannedMaHieus.length} mã hiệu'
                  : 'Không có mã hiệu',
              color: controller.scannedMaHieus.isNotEmpty
                  ? AppTheme.successGreen
                  : AppTheme.textSecondary,
              onPressed: controller.scannedMaHieus.isNotEmpty
                  ? controller.printAllMaHieus
                  : null,
            ),
          ],
        ));
  }
}
