import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/widgets/host_selection_widget.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';

import '../controllers/detail_controller.dart';

class DetailView extends GetView<DetailController> {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppTheme.buildAppBar(
        title: '',
        titleWidget: const HostSelectionWidget(),
      ),
      body: Center(
        child: Obx(
          () => Column(
            children: [
              AppTheme.gradientSeparator(),

              // ── Customer Name ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  controller.khachHang.value.tenKH!,
                  style: const TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // ── Customer Info Row ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip(
                        'Mã KH', '${controller.khachHang.value.maKH}',
                        color: AppTheme.warningOrange),
                    _buildInfoChip(
                        'Số Lượng',
                        '${controller.khachHang.value.buuGuis?.length ?? "0"}',
                        color: AppTheme.dangerRed),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Filter Checkboxes Row 1 ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFilterCheck(
                      'Đang gom: ${controller.khachHang.value.countState?.countDangGom ?? "0"}',
                      controller.isCheckedDangGom.value,
                      (e) {
                        controller.isCheckedDangGom.value = e!;
                        controller.updateBuuguiFromCheck();
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterCheck(
                      'Phân hướng: ${controller.khachHang.value.countState?.countPhanHuong ?? "0"}',
                      controller.isCheckPhanHuong.value,
                      (e) {
                        controller.isCheckPhanHuong.value = e!;
                        controller.updateBuuguiFromCheck();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // ── Filter Checkboxes Row 2 ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFilterCheck(
                      'Nhận hàng: ${controller.khachHang.value.countState?.countNhanHang ?? "0"}',
                      controller.isCheckNhanHang.value,
                      (e) {
                        controller.isCheckNhanHang.value = e!;
                        controller.updateBuuguiFromCheck();
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterCheck(
                      'Chấp nhận: ${controller.khachHang.value.countState?.countChapNhan ?? "0"}',
                      controller.isCheckChapNhan.value,
                      (e) {
                        controller.isCheckChapNhan.value = e!;
                        controller.updateBuuguiFromCheck();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // ── Options Row ──
              Obx(() => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFilterCheck(
                          'Xóa số điện thoại',
                          controller.isDeletePhone.value,
                          (e) => controller.isDeletePhone.value = e!,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterCheck(
                          'Thời gian',
                          controller.isShowTimeTrangThai.value,
                          (e) {
                            controller.isShowTimeTrangThai.value = e!;
                            controller.update();
                          },
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 6),

              // ── State Text ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppTheme.statusBanner('${controller.stateText}'),
              ),

              const SizedBox(height: 6),

              // ── Data Table ──
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GetBuilder<DetailController>(
                      builder: (dx) => DataTable2(
                        showCheckboxColumn: false,
                        sortAscending: false,
                        sortColumnIndex: 1,
                        columnSpacing: 5,
                        horizontalMargin: 10,
                        headingRowHeight: 36,
                        headingTextStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        dataTextStyle: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                        columns: _buildColumns(),
                        rows: List<DataRow>.generate(
                          dx.buuGuis.length,
                          (index) => DataRow(
                            selected: dx.iSeBuuGui.value == index,
                            onSelectChanged: (value) {
                              dx.iSeBuuGui.value = index;
                              dx.update();
                            },
                            onLongPress: () =>
                                _showWeightDialog(context, index),
                            color: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return AppTheme.primaryBlue
                                    .withValues(alpha: 0.2);
                              }
                              return null;
                            }),
                            cells: _buildCells(dx, index),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom Action Buttons ──
              AppTheme.bottomBar(
                child: Row(
                  children: [
                    AppTheme.gradientButton(
                      icon: Icons.stop_circle_outlined,
                      label: 'Stop',
                      color: AppTheme.dangerRed,
                      onPressed: () => controller.stopToPortal(),
                    ),
                    AppTheme.gradientButton(
                      icon: Icons.print_rounded,
                      label: 'Print',
                      color: AppTheme.warningOrange,
                      onPressed: () => controller.printAll(),
                    ),
                    AppTheme.gradientButton(
                      icon: Icons.send_rounded,
                      label: 'Send',
                      color: AppTheme.primaryBlue,
                      onPressed: controller.isEnableRunBtn.value
                          ? () async {
                              controller.isEnableRunBtn.value = false;
                              controller.sendToPortal(isAuto: true);
                              await Future.delayed(
                                  const Duration(seconds: 3));
                              controller.isEnableRunBtn.value = true;
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info Chip ──────────────────────────────────────
  Widget _buildInfoChip(String label, String value, {required Color color}) {
    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ── Filter Checkbox ────────────────────────────────
  Widget _buildFilterCheck(
      String label, bool value, ValueChanged<bool?> onChanged) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: value
                ? AppTheme.successGreen.withValues(alpha: 0.1)
                : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value
                  ? AppTheme.successGreen.withValues(alpha: 0.3)
                  : AppTheme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: value ? AppTheme.successGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: value
                        ? AppTheme.successGreen
                        : AppTheme.textSecondary,
                    width: 1.5,
                  ),
                ),
                child: value
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 12)
                    : null,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color:
                        value ? AppTheme.textPrimary : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Weight Dialog ──────────────────────────────────
  void _showWeightDialog(BuildContext context, int index) {
    final TextEditingController weightController = TextEditingController();
    weightController.text =
        controller.buuGuis[index].khoiLuong?.toString() ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Weight',
              style: TextStyle(color: AppTheme.textPrimary)),
          content: TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: AppTheme.inputDecoration(label: 'New Weight'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Confirm'),
              onPressed: () {
                final newWeight = int.tryParse(weightController.text);
                if (newWeight != null) {
                  controller.updateWeight(index, newWeight);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ── Table Columns ──────────────────────────────────
  List<DataColumn2> _buildColumns() {
    final showTime = controller.isShowTimeTrangThai.value;
    // Narrow widths when time column is visible to prevent overflow
    final codeWidth = showTime ? 95.0 : 115.0;
    final klWidth = showTime ? 40.0 : 48.0;

    List<DataColumn2> columns = [
      const DataColumn2(label: Text('STT'), fixedWidth: 25, size: ColumnSize.S),
      DataColumn2(
          label: const Text('Code'), fixedWidth: codeWidth, numeric: false),
      DataColumn2(label: const Text('KL'), fixedWidth: klWidth, numeric: true),
      const DataColumn2(label: Text('COD'), numeric: true),
      const DataColumn2(label: Text('State'), fixedWidth: 35),
    ];

    if (showTime) {
      columns.add(const DataColumn2(
          label: Text('TG'), fixedWidth: 65, numeric: false));
    }

    columns.add(const DataColumn2(label: Text('?'), fixedWidth: 15));

    return columns;
  }

  // ── Table Cells ────────────────────────────────────
  List<DataCell> _buildCells(dynamic dx, int index) {
    List<DataCell> cells = [
      DataCell(Text(
        dx.buuGuis[index].index.toString(),
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      )),
      DataCell(Text(
        dx.buuGuis[index].maBuuGui!,
        style: TextStyle(
          fontWeight: FontWeight.w400,
          color: dx.buuGuis[index].isBlackList
              ? AppTheme.dangerRed
              : AppTheme.textPrimary,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      )),
      DataCell(Text(
        dx.buuGuis[index].khoiLuong == null
            ? ""
            : dx.buuGuis[index].khoiLuong!.toString(),
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      )),
      DataCell(Text(
        dx.buuGuis[index].money == null
            ? ""
            : dx.buuGuis[index].money!.toString(),
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      )),
      DataCell(Text(
        dx.buuGuis[index].trangThaiRequest == null
            ? ""
            : dx.buuGuis[index].trangThaiRequest!.toString(),
        style: const TextStyle(color: AppTheme.accentCyan, fontSize: 12),
      )),
    ];

    if (controller.isShowTimeTrangThai.value) {
      cells.add(DataCell(Text(
        dx.buuGuis[index].timeTrangThai ?? "",
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.primaryBlue.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
      )));
    }

    cells.add(DataCell(
      PopupMenuButton<String>(
        color: AppTheme.surfaceCard,
        onSelected: (value) async {
          if (value == 'Copy mã hiệu') {
            await Clipboard.setData(
                ClipboardData(text: dx.buuGuis[index].maBuuGui ?? ''));
            Get.snackbar(
              'Thành công',
              'Đã copy mã hiệu: ${dx.buuGuis[index].maBuuGui}',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppTheme.successGreen.withValues(alpha: 0.9),
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          }
        },
        icon: const Icon(Icons.more_vert_rounded,
            size: 16, color: AppTheme.textSecondary),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'Copy mã hiệu',
            child: Row(
              children: [
                Icon(Icons.copy_rounded,
                    size: 16, color: AppTheme.textPrimary),
                SizedBox(width: 8),
                Text('Copy mã hiệu',
                    style: TextStyle(color: AppTheme.textPrimary)),
              ],
            ),
          ),
          const PopupMenuDivider(),
          dx.buuGuis[index].isBlackList
              ? PopupMenuItem<String>(
                  value: 'Xóa khỏi Blacklist',
                  child: const Text('Xóa khỏi Blacklist',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  onTap: () => {controller.removeMHFromBlackList(index)},
                )
              : PopupMenuItem<String>(
                  value: 'Thêm vào Blacklist',
                  child: const Text('Thêm vào Blacklist',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  onTap: () => {controller.addMHToBlackList(index)},
                ),
        ],
      ),
    ));

    return cells;
  }
}
