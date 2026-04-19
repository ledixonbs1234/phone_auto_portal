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

  // ── Action Button (dark style) ─────────────────────
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
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

            // ── Customer Name & HDR ID ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(controller.tenKH.value,
                          style: const TextStyle(
                              color: AppTheme.accentCyan,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (controller.hdrIdText.value.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        controller.hdrIdText.value,
                        style: const TextStyle(
                            color: Color(0xFF9B5DE5),
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ]
                  ],
                ),
              ),
            ),

            // ── Top Action Row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Obx(
                () => Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                AppTheme.primaryBlue.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        "Còn: ${controller.susggestMHs.length}",
                        style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Khởi tạo',
                      color: AppTheme.primaryBlue,
                      onPressed: controller.selectedState.value == "CC"
                          ? () => controller.khoiTaoPortal()
                          : () {},
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
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

            // ── Hint / Autocomplete Row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Text('Gợi ý',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    height: 40,
                    child: Autocomplete<String>(
                      fieldViewBuilder: (context, textEditingController,
                          focusNode, onFieldSubmitted) {
                        controller.textHintController = textEditingController;
                        controller.focusHint = focusNode;
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.surfaceCard,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppTheme.dividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppTheme.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryBlue, width: 1.5),
                            ),
                          ),
                        );
                      },
                      optionsBuilder: ((textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        var list = controller.susggestMHs.where((element) =>
                            element.contains(textEditingValue.text));
                        if (list.length == 1 &&
                            textEditingValue.text.length != 13) {
                          controller.onFindedMH(list.first);
                          return const Iterable<String>.empty();
                        }
                        return list;
                      }),
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
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: controller.isChangeKL.value,
                            activeColor: AppTheme.successGreen,
                            checkColor: Colors.white,
                            side: const BorderSide(
                                color: AppTheme.textSecondary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            onChanged: (e) {
                              controller.isChangeKL.value = e ?? false;
                              controller.update();
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('KL',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: controller.isNotCheckData.value,
                            activeColor: AppTheme.warningOrange,
                            checkColor: Colors.white,
                            side: const BorderSide(
                                color: AppTheme.textSecondary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            onChanged: (e) {
                              controller.isNotCheckData.value = e ?? false;
                              controller.update();
                              'NOT checkbox changed to: ${controller.isNotCheckData.value}'
                                  .printInfo();
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('NOT',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            // ── MH + KL Input Row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Text('MH',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(width: 8),
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
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surfaceCard,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppTheme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppTheme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryBlue, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('KL',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    height: 36,
                    child: TextField(
                      style: const TextStyle(
                          fontSize: 15, color: AppTheme.dangerRed),
                      controller: controller.textKLController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      focusNode: controller.focusKL,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surfaceCard,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppTheme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppTheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppTheme.dangerRed, width: 1.5),
                        ),
                      ),
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
            ),

            // ── Info / State Text ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Text('Info: ',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  Expanded(
                    child: Obx(
                      () => Text(
                        '${controller.stateText}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  )
                ],
              ),
            ),

            // ── Weight Quick Buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GroupButton(
                      buttons: const ['500'],
                      options: GroupButtonOptions(
                        borderRadius: BorderRadius.circular(8),
                        unselectedColor: AppTheme.surfaceCard,
                        unselectedTextStyle: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                        selectedColor: AppTheme.primaryBlue,
                        selectedTextStyle: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                      onSelected: (value, index, isSelected) =>
                          controller.addKL(500)),
                  const SizedBox(width: 4),
                  GroupButton(
                      buttons: const ['1000'],
                      options: GroupButtonOptions(
                        borderRadius: BorderRadius.circular(8),
                        unselectedColor: AppTheme.surfaceCard,
                        unselectedTextStyle: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                        selectedColor: AppTheme.primaryBlue,
                        selectedTextStyle: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                      onSelected: (value, index, isSelected) =>
                          controller.addKL(1000)),
                  const SizedBox(width: 4),
                  GroupButton(
                      buttons: const ['1500'],
                      options: GroupButtonOptions(
                        borderRadius: BorderRadius.circular(8),
                        unselectedColor: AppTheme.surfaceCard,
                        unselectedTextStyle: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                        selectedColor: AppTheme.primaryBlue,
                        selectedTextStyle: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                      onSelected: (value, index, isSelected) =>
                          controller.addKL(1500)),
                  const SizedBox(width: 4),
                  GroupButton(
                      buttons: const ['2000'],
                      options: GroupButtonOptions(
                        borderRadius: BorderRadius.circular(8),
                        unselectedColor: AppTheme.surfaceCard,
                        unselectedTextStyle: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                        selectedColor: AppTheme.primaryBlue,
                        selectedTextStyle: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                      onSelected: (value, index, isSelected) =>
                          controller.addKL(2000)),
                ],
              ),
            ),

            // ── Direction Dropdown + Show All ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: AppTheme.dividerColor),
                        ),
                        child: DropdownButton<String>(
                          value: controller.selectedState.value,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceCard,
                          underline: const SizedBox.shrink(),
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textPrimary),
                          icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.textSecondary),
                          onChanged: (value) {
                            controller.selectedState.value = value!;
                            controller.updateSuggestMHsForSelectedState();
                            controller.update();
                          },
                          items: [
                            DropdownMenuItem(
                              value: "NTB",
                              child: Obx(() => Text(
                                    'Nam Trung Bộ (${controller.namTrungBoCount.value})',
                                    style: const TextStyle(
                                        color: AppTheme.accentCyan),
                                  )),
                            ),
                            DropdownMenuItem(
                              value: "DN",
                              child: Obx(() => Text(
                                    'Đà Nẵng (${controller.daNangCount.value})',
                                    style: const TextStyle(
                                        color: AppTheme.accentCyan),
                                  )),
                            ),
                            DropdownMenuItem(
                              value: "CL",
                              child: Obx(() => Text(
                                    'Còn Lại (${controller.conLaiCount.value})',
                                    style: const TextStyle(
                                        color: AppTheme.accentCyan),
                                  )),
                            ),
                            const DropdownMenuItem(
                              value: "CC",
                              child: Text('Chưa Chọn',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.visibility,
                      label: "Hiện Hết",
                      color: AppTheme.primaryBlue,
                      onPressed: () => controller.showAll(),
                    ),
                  ],
                ),
              ),
            ),

            // ── Options Bar (QR, Tự Gửi, etc.) ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildActionButton(
                      icon: Icons.barcode_reader,
                      label: 'QR',
                      color: AppTheme.warningOrange,
                      onPressed: () => controller.addKhachHangAsQR(),
                    ),
                    const SizedBox(width: 8),
                    Obx(
                      () => AppTheme.toggleOption(
                        'Tự Gửi',
                        controller.isAutoWork.value,
                        () {
                          controller.isAutoWork.value =
                              !controller.isAutoWork.value;
                          if (controller.isAutoWork.value) {
                            controller.autoWork();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(
                      () => AppTheme.toggleOption(
                        'Xóa SĐT',
                        controller.isDeletePhone.value,
                        () {
                          controller.isDeletePhone.value =
                              !controller.isDeletePhone.value;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.send_and_archive_rounded,
                      label: 'Send End',
                      color: const Color(0xFF6366F1),
                      onPressed: () => controller.sendEndAndPrint(),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.download_rounded,
                      label: 'Lấy Lan',
                      color: AppTheme.accentCyan,
                      onPressed: () =>
                          controller.getDiNgoaisTempFromFirebase(),
                    ),
                  ],
                ),
              ),
            ),

            // ── Data Table ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GetBuilder<CreatenewController>(
                  builder: (dx) => DataTable2(
                    showCheckboxColumn: false,
                    sortAscending: false,
                    sortColumnIndex: 1,
                    columnSpacing: 3,
                    horizontalMargin: 8,
                    minWidth: 300,
                    dataRowHeight: 35,
                    headingRowHeight: 35,
                    headingRowColor:
                        WidgetStateProperty.all(AppTheme.surfaceDark),
                    headingTextStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) {
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
                        label: Text('STT'),
                        fixedWidth: 35,
                        size: ColumnSize.S,
                      ),
                      DataColumn2(
                        label: Text(''),
                        tooltip: 'Trạng thái',
                        fixedWidth: 25,
                      ),
                      DataColumn2(
                          label: Text('Code'),
                          fixedWidth: 110,
                          numeric: false),
                      DataColumn2(
                          label: Text('KL'),
                          fixedWidth: 35,
                          numeric: true),
                      DataColumn2(
                          label: Text('COD'),
                          fixedWidth: 45,
                          numeric: true),
                      DataColumn2(
                          label: Text('State'), fixedWidth: 45),
                    ],
                    rows: _rowsBuild(dx, context),
                  ),
                ),
              ),
            ),

            // ── Bottom Action Bar ──
            AppTheme.bottomBar(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Xóa',
                      color: AppTheme.dangerRed,
                      onPressed: () => controller.deleteSelected(),
                      onLongPress: () => controller.deleteAll(),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.send_outlined,
                      label: 'Send',
                      color: AppTheme.primaryBlue,
                      onPressed: () => controller.sendToPC(),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.print_outlined,
                      label: 'In BD1 New',
                      color: AppTheme.warningOrange,
                      onPressed: () {
                        if (controller.selectedState.value != "CC") {
                          controller.printAllAndDelete();
                        } else {
                          controller.printAll();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
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
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.check,
                      label: 'Hoàn tất tin',
                      color: AppTheme.successGreen,
                      onPressed: () => controller.hoanTatTin(),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.info_outline,
                      label: 'Điều tin',
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

  List<DataRow> _rowsBuild(CreatenewController dx, BuildContext context) {
    return List<DataRow>.generate(
        dx.buuGuis.length,
        (index) => DataRow(
                selected: index == dx.iBuuGui.value,
                onSelectChanged: (value) {
                  dx.iBuuGui.value = index;
                  dx.checkSelected();
                  dx.update();
                },
                color: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.primaryBlue.withValues(alpha: 0.2);
                  }
                  return null;
                }),
                cells: [
                  DataCell(Text(
                    dx.buuGuis[index].index.toString(),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold),
                  )),
                  DataCell(
                    Center(
                      child: Tooltip(
                        message:
                            dx.buuGuis[index].trangThai ?? 'Không xác định',
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                                dx.buuGuis[index].trangThai),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(
                    dx.buuGuis[index].maBuuGui!,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textPrimary),
                  )),
                  DataCell(Text(
                    dx.buuGuis[index].khoiLuong == null
                        ? ""
                        : dx.buuGuis[index].khoiLuong!.toString(),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textPrimary),
                  )),
                  DataCell(Text(
                    dx.buuGuis[index].money == null
                        ? ""
                        : dx.buuGuis[index].money!.toString(),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textPrimary),
                  )),
                  DataCell(Text(
                    dx.buuGuis[index].trangThaiRequest == null
                        ? ""
                        : dx.buuGuis[index].trangThaiRequest!.toString(),
                    style: const TextStyle(
                        color: AppTheme.accentCyan, fontSize: 11),
                  )),
                ]));
  }
}
