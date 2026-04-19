import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/danhsachbd_controller.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';

class DanhSachBDView extends GetView<DanhSachBDController> {
  const DanhSachBDView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppTheme.buildAppBar(
        title: 'Danh Sách BĐ & Tự Động',
        onBack: () => Get.back(),
        actions: [
          AppTheme.appBarAction(
            icon: Icons.refresh_rounded,
            onPressed: () => controller.refreshData(),
            color: AppTheme.warningOrange,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          );
        }

        final data = controller.data.value;
        if (data == null) {
          return AppTheme.emptyState(
            icon: Icons.list_alt_rounded,
            title: 'Không có dữ liệu',
            subtitle: 'Nhấn refresh để tải lại',
          );
        }

        return Column(
          children: [
            AppTheme.gradientSeparator(),

            // ── Stats Row ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Kiện', data.countKien, AppTheme.primaryBlue),
                  _buildStatCard(
                      'Túi', data.countTui, AppTheme.warningOrange),
                  _buildStatCard(
                      'Bao', data.countBao, AppTheme.successGreen),
                ],
              ),
            ),

            // ── Input Section ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.textController,
                      focusNode: controller.focusNode,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: AppTheme.inputDecoration(
                        label: 'Quét/Nhập mã hiệu',
                        prefixIcon: Icons.qr_code_scanner_rounded,
                      ),
                      onSubmitted: controller.onSubmitted,
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => controller
                          .onSubmitted(controller.textController.text),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryBlue, Color(0xFF3A6AE8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Gửi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Selected BD & Create Button ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Row(
                        children: [
                          const Text('Đang chọn: ',
                              style:
                                  TextStyle(color: AppTheme.textSecondary)),
                          Text(
                            controller.selectedBD.value.isEmpty
                                ? "Chưa chọn"
                                : controller.selectedBD.value,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                        ],
                      )),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: controller.selectedBD.value.isEmpty
                          ? null
                          : () => controller
                              .createBD(controller.selectedBD.value),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: controller.selectedBD.value.isNotEmpty
                              ? const LinearGradient(
                                  colors: [
                                    AppTheme.successGreen,
                                    Color(0xFF16A34A)
                                  ],
                                )
                              : null,
                          color: controller.selectedBD.value.isEmpty
                              ? AppTheme.dividerColor
                              : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_box_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Tạo BĐ',
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
            ),

            // ── Data Table ──
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.dividerColor.withValues(alpha: 0.5)),
                ),
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 400,
                  headingRowHeight: 40,
                  dataRowHeight: 50,
                  headingTextStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  dataTextStyle: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  border: TableBorder.all(
                    color: AppTheme.dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  columns: const [
                    DataColumn2(
                        label: Text('Tuyến'), size: ColumnSize.L),
                    DataColumn2(label: Text('SL'), size: ColumnSize.S),
                    DataColumn2(label: Text('Chọn'), size: ColumnSize.S),
                  ],
                  rows: data.locBDs.map((loc) {
                    bool isSelected =
                        controller.selectedBD.value == loc.tenBD;
                    Color bgColor = Colors.transparent;
                    if (loc.isSendAlled == '#FFD28F') {
                      bgColor =
                          AppTheme.warningOrange.withValues(alpha: 0.1);
                    }
                    if (isSelected) {
                      bgColor =
                          AppTheme.primaryBlue.withValues(alpha: 0.15);
                    }

                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) => bgColor),
                      onSelectChanged: (selected) {
                        if (selected == true) {
                          controller.selectBD(loc.tenBD);
                        }
                      },
                      cells: [
                        DataCell(Text(loc.tenBD,
                            style: const TextStyle(
                                color: AppTheme.textPrimary))),
                        DataCell(Text(
                          loc.count.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentCyan,
                          ),
                        )),
                        DataCell(
                          Radio<String>(
                            value: loc.tenBD,
                            groupValue: controller.selectedBD.value,
                            onChanged: (value) {
                              if (value != null) controller.selectBD(value);
                            },
                            activeColor: AppTheme.primaryBlue,
                            fillColor: WidgetStateProperty.resolveWith(
                              (states) => states
                                      .contains(WidgetState.selected)
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      }),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
