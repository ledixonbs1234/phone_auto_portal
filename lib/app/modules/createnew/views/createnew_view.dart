import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:group_button/group_button.dart';
import 'package:phone_auto_portal/app/widgets/host_selection_widget.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';

import '../controllers/createnew_controller.dart';
import 'option_view.dart';

class CreatenewView extends GetView<CreatenewController> {
  const CreatenewView({super.key});

  // ── Shared weight‐button style ────────────────────
  static final _klButtonOptions = GroupButtonOptions(
    borderRadius: BorderRadius.circular(8),
    unselectedColor: AppTheme.surfaceCard,
    unselectedTextStyle:
        const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
    selectedColor: AppTheme.primaryBlue,
    selectedTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
  );

  // ── Compact dark input decoration ─────────────────
  static InputDecoration _compactInput({Color? focusColor}) {
    return InputDecoration(
      filled: true,
      fillColor: AppTheme.surfaceCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: focusColor ?? AppTheme.primaryBlue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      resizeToAvoidBottomInset: false,
      appBar: AppTheme.buildAppBar(
        title: '',
        titleWidget: const HostSelectionWidget(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppTheme.gradientSeparator(),

            // ── Header: KH name + HDR + count badge ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
              child: Obx(
                () => Row(
                  children: [
                    // Count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                AppTheme.primaryBlue.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        "${controller.susggestMHs.length}",
                        style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // KH name
                    Expanded(
                      child: Text(
                        controller.tenKH.value,
                        style: const TextStyle(
                            color: AppTheme.accentCyan,
                            fontSize: 17,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // HDR ID badge
                    if (controller.hdrIdText.value.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF9B5DE5).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          controller.hdrIdText.value,
                          style: const TextStyle(
                              color: Color(0xFF9B5DE5),
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Quick actions: Khởi tạo · Option ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: AppTheme.actionButton(
                        icon: Icons.cloud_upload_outlined,
                        label: 'Khởi tạo',
                        color: AppTheme.primaryBlue,
                        onPressed: controller.selectedState.value == "CC"
                            ? () => controller.khoiTaoPortal()
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppTheme.actionButton(
                      icon: Icons.settings_outlined,
                      label: 'Option',
                      color: const Color(0xFF9B5DE5),
                      onPressed: () {
                        controller.loadOptions();
                        Get.to(() => const OptionView());
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Input section (card container) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: AppTheme.cardContainer(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    // Row 1: Gợi ý + KL/NOT toggles
                    Row(
                      children: [
                        const Text('Gợi ý',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 180,
                          height: 36,
                          child: Autocomplete<String>(
                            fieldViewBuilder: (context, textEditingController,
                                focusNode, onFieldSubmitted) {
                              controller.textHintController =
                                  textEditingController;
                              controller.focusHint = focusNode;
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: const TextStyle(
                                    color: AppTheme.textPrimary, fontSize: 14),
                                decoration: _compactInput(),
                              );
                            },
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              var list = controller.susggestMHs.where(
                                  (e) => e.contains(textEditingValue.text));
                              if (list.length == 1 &&
                                  textEditingValue.text.length != 13) {
                                controller.onFindedMH(list.first);
                                return const Iterable<String>.empty();
                              }
                              return list;
                            },
                            onSelected: (options) {
                              debugPrint('You selected $options');
                              controller.onFindedMH(options);
                            },
                          ),
                        ),
                        const Spacer(),
                        Obx(
                          () => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _miniCheckbox(
                                value: controller.isChangeKL.value,
                                label: 'KL',
                                color: AppTheme.successGreen,
                                onChanged: (v) {
                                  controller.isChangeKL.value = v ?? false;
                                  controller.update();
                                },
                              ),
                              const SizedBox(width: 6),
                              _miniCheckbox(
                                value: controller.isNotCheckData.value,
                                label: 'NOT',
                                color: AppTheme.warningOrange,
                                onChanged: (v) {
                                  controller.isNotCheckData.value = v ?? false;
                                  controller.update();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Row 2: MH + KL inputs
                    Row(
                      children: [
                        const Text('MH',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 36,
                            child: TextField(
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold),
                              controller: controller.textMHController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: _compactInput(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('KL',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 68,
                          height: 36,
                          child: TextField(
                            style: const TextStyle(
                                fontSize: 15, color: AppTheme.dangerRed),
                            controller: controller.textKLController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            focusNode: controller.focusKL,
                            decoration:
                                _compactInput(focusColor: AppTheme.dangerRed),
                            onSubmitted: (s) {
                              if (controller.isDo.value) {
                                controller.focusK1.requestFocus();
                              } else {
                                controller.addKhachHang();
                                controller.focusHint.requestFocus();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Row 3: KL quick buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final kl in [500, 1000, 1500, 2000]) ...[
                          if (kl != 500) const SizedBox(width: 4),
                          GroupButton(
                            buttons: ['$kl'],
                            options: _klButtonOptions,
                            onSelected: (_, __, ___) => controller.addKL(kl),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Info + Direction dropdown row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                children: [
                  // Compact info text
                  Expanded(
                    flex: 2,
                    child: Obx(
                      () => Text(
                        'Info: ${controller.stateText}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryBlue),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Direction dropdown (compact)
                  Expanded(
                    flex: 3,
                    child: Obx(
                      () => Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: DropdownButton<String>(
                          value: controller.selectedState.value,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceCard,
                          underline: const SizedBox.shrink(),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textPrimary),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.textSecondary, size: 18),
                          onChanged: (value) {
                            controller.selectedState.value = value!;
                            controller.updateSuggestMHsForSelectedState();
                            controller.update();
                          },
                          items: [
                            _directionItem("NTB", 'NTB',
                                controller.namTrungBoCount),
                            _directionItem(
                                "DN", 'ĐN', controller.daNangCount),
                            _directionItem(
                                "CL", 'CL', controller.conLaiCount),
                            const DropdownMenuItem(
                              value: "CC",
                              child: Text('Chưa Chọn',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Toolbar: QR, Tự Gửi, Xóa SĐT, etc. ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    AppTheme.actionButton(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'QR',
                      color: AppTheme.warningOrange,
                      onPressed: () => controller.addKhachHangAsQR(),
                    ),
                    const SizedBox(width: 6),
                    Obx(() => AppTheme.toggleOption(
                          'Tự Gửi',
                          controller.isAutoWork.value,
                          () {
                            controller.isAutoWork.value =
                                !controller.isAutoWork.value;
                            if (controller.isAutoWork.value) {
                              controller.autoWork();
                            }
                          },
                        )),
                    const SizedBox(width: 6),
                    Obx(() => AppTheme.toggleOption(
                          'Xóa SĐT',
                          controller.isDeletePhone.value,
                          () => controller.isDeletePhone.value =
                              !controller.isDeletePhone.value,
                        )),
                    const SizedBox(width: 6),
                    AppTheme.actionButton(
                      icon: Icons.send_and_archive_rounded,
                      label: 'Send End',
                      color: const Color(0xFF6366F1),
                      onPressed: () => controller.sendEndAndPrint(),
                    ),
                    const SizedBox(width: 6),
                    AppTheme.actionButton(
                      icon: Icons.download_rounded,
                      label: 'Lấy Lan',
                      color: AppTheme.accentCyan,
                      onPressed: () =>
                          controller.getDiNgoaisTempFromFirebase(),
                    ),
                    const SizedBox(width: 6),
                    AppTheme.actionButton(
                      icon: Icons.visibility,
                      label: 'H.Hết',
                      color: AppTheme.textSecondary,
                      onPressed: () => controller.showAll(),
                    ),
                  ],
                ),
              ),
            ),

            // ── Data Table ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                child: GetBuilder<CreatenewController>(
                  builder: (dx) => DataTable2(
                    showCheckboxColumn: false,
                    sortAscending: false,
                    sortColumnIndex: 1,
                    columnSpacing: 3,
                    horizontalMargin: 8,
                    minWidth: 300,
                    dataRowHeight: 34,
                    headingRowHeight: 32,
                    headingRowColor:
                        WidgetStateProperty.all(AppTheme.surfaceDark),
                    headingTextStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    dataRowColor:
                        WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primaryBlue.withValues(alpha: 0.2);
                      }
                      return null;
                    }),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              AppTheme.dividerColor.withValues(alpha: 0.5)),
                    ),
                    columns: const [
                      DataColumn2(
                          label: Text('STT'), fixedWidth: 32, size: ColumnSize.S),
                      DataColumn2(
                          label: Text(''), tooltip: 'Trạng thái', fixedWidth: 22),
                      DataColumn2(
                          label: Text('Code'), fixedWidth: 110, numeric: false),
                      DataColumn2(
                          label: Text('KL'), fixedWidth: 32, numeric: true),
                      DataColumn2(
                          label: Text('COD'), fixedWidth: 42, numeric: true),
                      DataColumn2(label: Text('State'), fixedWidth: 42),
                    ],
                    rows: _rowsBuild(dx),
                  ),
                ),
              ),
            ),

            // ── Bottom Action Bar ──
            AppTheme.bottomBar(
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    AppTheme.actionButton(
                      icon: Icons.delete_outline,
                      label: 'Xóa',
                      color: AppTheme.dangerRed,
                      onPressed: () => controller.deleteSelected(),
                      onLongPress: () => controller.deleteAll(),
                    ),
                    const SizedBox(width: 6),
                    AppTheme.actionButton(
                      icon: Icons.send_outlined,
                      label: 'Send',
                      color: AppTheme.primaryBlue,
                      onPressed: () => controller.sendToPC(),
                    ),
                    const SizedBox(width: 6),
                    AppTheme.actionButton(
                      icon: Icons.print_outlined,
                      label: 'In BD1',
                      color: AppTheme.warningOrange,
                      onPressed: () {
                        if (controller.selectedState.value != "CC") {
                          controller.printAllAndDelete();
                        } else {
                          controller.printAll();
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    AppTheme.actionButton(
                      icon: Icons.print_outlined,
                      label: 'In AR',
                      color: AppTheme.textSecondary,
                      onPressed: () {
                        if (controller.selectedState.value != "CC") {
                          controller.printAllAndDelete();
                        } else {
                          controller.printARs();
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    AppTheme.actionButton(
                      icon: Icons.check,
                      label: 'HT Tin',
                      color: AppTheme.successGreen,
                      onPressed: () => controller.hoanTatTin(),
                    ),
                    const SizedBox(width: 6),
                    AppTheme.actionButton(
                      icon: Icons.info_outline,
                      label: 'Đ.Tin',
                      color: const Color(0xFF6366F1),
                      onPressed: () => controller.dieuTin(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────

  Widget _miniCheckbox({
    required bool value,
    required String label,
    required Color color,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: value,
            activeColor: color,
            checkColor: Colors.white,
            side: const BorderSide(color: AppTheme.textSecondary),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: value ? color : AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  DropdownMenuItem<String> _directionItem(
      String value, String shortLabel, RxInt count) {
    return DropdownMenuItem(
      value: value,
      child: Obx(() => Text(
            '$shortLabel (${count.value})',
            style:
                const TextStyle(color: AppTheme.accentCyan, fontSize: 12),
          )),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'đã chấp nhận':
        return AppTheme.dangerRed;
      case 'đã phân hướng':
        return AppTheme.primaryBlue;
      case 'đang đi thu gom':
        return AppTheme.warningOrange;
      case 'nhận hàng thành công':
        return const Color(0xFFF97316);
      default:
        return AppTheme.textSecondary;
    }
  }

  List<DataRow> _rowsBuild(CreatenewController dx) {
    return List<DataRow>.generate(
      dx.buuGuis.length,
      (index) {
        final bg = dx.buuGuis[index];
        return DataRow(
          selected: index == dx.iBuuGui.value,
          onSelectChanged: (_) {
            dx.iBuuGui.value = index;
            dx.checkSelected();
            dx.update();
          },
          color:
              WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.primaryBlue.withValues(alpha: 0.2);
            }
            return null;
          }),
          cells: [
            DataCell(Text('${bg.index}',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold))),
            DataCell(Center(
              child: Tooltip(
                message: bg.trangThai ?? 'N/A',
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _getStatusColor(bg.trangThai),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )),
            DataCell(Text(bg.maBuuGui!,
                style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textPrimary))),
            DataCell(Text(bg.khoiLuong?.toString() ?? '',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textPrimary))),
            DataCell(Text(bg.money?.toString() ?? '',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textPrimary))),
            DataCell(Text(bg.trangThaiRequest?.toString() ?? '',
                style: const TextStyle(
                    color: AppTheme.accentCyan, fontSize: 11))),
          ],
        );
      },
    );
  }
}
