// Path: hone_auto_portal/lib/app/modules/dingoai_config/views/dingoai_config_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/state_ma_hieu_model.dart';
import '../controllers/dingoai_config_controller.dart';
import '../models/dingoai_config_item.dart';

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
          // Hiển thị trạng thái tải dữ liệu bưu gửi
          Obx(() {
            if (controller.isLoadingPackages.value) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.accentCyan),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.stateText.value,
                        style: const TextStyle(
                            color: AppTheme.accentCyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
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

  Widget _buildConfigItem(
      BuildContext context, int index, DiNgoaiConfigItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onLongPress: () => _showItemDetailDialog(context, item, index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Bên trái: Tên Portal và Số lượng
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.portalName ?? 'Không tên',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.soLuong != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Số lượng: ${item.soLuong}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Đã bọc Flexible + overflow để tránh lỗi tràn layout RenderFlex
                            Flexible(
                              child: Text(
                                '(Giữ lâu để xem chi tiết)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.accentCyan
                                      .withValues(alpha: 0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Bên phải: Dropdown lựa chọn hành động
                Obx(() => _buildActionDropdown(index, item.action)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionDropdown(int index, String currentAction) {
    final List<Map<String, String>> actions = [
      {'id': 'ban_bd_ntb_1', 'label': 'BĐ NTB 1'},
      {'id': 'ban_bd_ntb_2', 'label': 'BĐ NTB 2'},
      {'id': 'ban_bd_ntb_3', 'label': 'BĐ NTB 3'},
      {'id': 'ban_bd_ntb_rieng', 'label': 'BĐ NTB riêng'},
      {'id': 'duong_thu_rieng', 'label': 'Đường thư TQ-NTB'},
      {'id': 'di_ra_rieng', 'label': 'Đi Ra Riêng'},
      {'id': 'dn_ntb_tq', 'label': 'ĐN,NTB Riêng TQ'},
      {'id': 'khong_chon', 'label': 'Không chọn'},
    ];

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: DropdownButton<String>(
        value: currentAction,
        dropdownColor: AppTheme.surfaceCard,
        underline: const SizedBox.shrink(),
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppTheme.textSecondary,
          size: 18,
        ),
        onChanged: (value) {
          if (value != null) {
            controller.updateAction(index, value);
          }
        },
        items: actions.map((act) {
          return DropdownMenuItem<String>(
            value: act['id'],
            child: Text(act['label']!),
          );
        }).toList(),
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
                          style: TextStyle(
                              fontSize: 14, color: AppTheme.textPrimary),
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.textSecondary),
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedMayChu.value = value;
                            }
                          },
                          items: controller.maychus.map((e) {
                            return DropdownMenuItem<String>(
                                value: e, child: Text(e));
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
                            colors: [
                              AppTheme.successGreen,
                              AppTheme.successGreen.withValues(alpha: 0.8)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.successGreen.withValues(alpha: 0.3),
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

  // Dialog hiển thị chi tiết bưu gửi của portal để lọc
  void _showItemDetailDialog(
      BuildContext context, DiNgoaiConfigItem item, int index) {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedCount = item.packages.where((p) => p.selected).length;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          color: AppTheme.accentCyan, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.portalName ?? 'Chi tiết bưu gửi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bộ lọc chọn nhanh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã chọn: $selectedCount / ${item.packages.length}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final allSelected =
                              selectedCount == item.packages.length;
                          setDialogState(() {
                            for (var p in item.packages) {
                              p.selected = !allSelected;
                            }
                          });
                          controller.configItems.refresh();
                        },
                        child: Text(
                          selectedCount == item.packages.length
                              ? 'Bỏ chọn hết'
                              : 'Chọn hết',
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Danh sách bưu gửi
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: item.packages.isEmpty
                          ? AppTheme.emptyState(
                              title: 'Không có dữ liệu bưu gửi')
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: item.packages.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: AppTheme.dividerColor
                                    .withValues(alpha: 0.3),
                              ),
                              itemBuilder: (context, i) {
                                final pkg = item.packages[i];
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () {
                                    setDialogState(() {
                                      pkg.selected = !pkg.selected;
                                    });
                                    controller.configItems.refresh();
                                  },
                                  leading: Checkbox(
                                    value: pkg.selected,
                                    activeColor: AppTheme.primaryBlue,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        pkg.selected = val ?? false;
                                      });
                                      controller.configItems.refresh();
                                    },
                                  ),
                                  title: Text(
                                    pkg.code ?? 'N/A',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${pkg.Weight ?? 0}g',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${pkg.Money ?? 0}đ',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.successGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nút hành động xác nhận
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Xác nhận',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
