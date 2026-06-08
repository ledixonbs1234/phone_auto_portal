import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';
import '../controllers/dingoai_config_controller.dart';

class DingoaiConfigView extends GetView<DingoaiConfigController> {
  const DingoaiConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppTheme.buildAppBar(
        title: 'Cấu hình Đi Ngoài Auto',
        onBack: () => Get.back(),
      ),
      body: Column(
        children: [
          AppTheme.gradientSeparator(),
          Expanded(
            child: Obx(() {
              if (controller.configItems.isEmpty) {
                return AppTheme.emptyState(
                  title: 'Không có portal nào được chọn',
                  subtitle: 'Vui lòng quay lại và chọn ít nhất một portal.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: controller.configItems.length,
                itemBuilder: (context, index) {
                  final item = controller.configItems[index];
                  return _buildConfigItem(context, index, item);
                },
              );
            }),
          ),
          _buildBottomPanel(context),
        ],
      ),
    );
  }

  Widget _buildConfigItem(BuildContext context, int index, dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.portalName ?? 'Không tên',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.soLuong != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'SL: ${item.soLuong}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warningOrange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => _buildActionButtons(index, item.action)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int index, String currentAction) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          label: 'Bắn BĐ NTB riêng',
          isSelected: currentAction == 'ban_bd_ntb_rieng',
          onTap: () => controller.updateAction(index, 'ban_bd_ntb_rieng'),
          color: AppTheme.primaryBlue,
        ),
        _buildActionButton(
          label: 'Đường thư riêng',
          isSelected: currentAction == 'duong_thu_rieng',
          onTap: () => controller.updateAction(index, 'duong_thu_rieng'),
          color: AppTheme.accentCyan,
        ),
        _buildActionButton(
          label: 'Không chọn',
          isSelected: currentAction == 'khong_chon',
          onTap: () => controller.updateAction(index, 'khong_chon'),
          color: AppTheme.textSecondary,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppTheme.dividerColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 16)
              else
                Icon(Icons.radio_button_unchecked, color: AppTheme.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Obx(() => DropdownButton<String>(
                          value: controller.selectedMayChu.value,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceCard,
                          underline: const SizedBox.shrink(),
                          style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedMayChu.value = value;
                            }
                          },
                          items: controller.maychus.map((e) {
                            return DropdownMenuItem<String>(value: e, child: Text(e));
                          }).toList(),
                        )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: controller.submitDiNgoaiConfig,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.successGreen, AppTheme.successGreen.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.successGreen.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Đi Ngoài Auto',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
    );
  }
}
