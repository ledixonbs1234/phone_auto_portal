import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';
import 'package:phone_auto_portal/app/widgets/host_selection_widget.dart';

import '../controllers/khoi_tao_moi_controller.dart';
import '../models/suggestion_item.dart';

class KhoiTaoMoiView extends GetView<KhoiTaoMoiController> {
  KhoiTaoMoiView({super.key});

  final TextEditingController textInputController = TextEditingController();
  TextEditingController autocompleteTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      resizeToAvoidBottomInset: false,
      appBar: AppTheme.buildAppBar(
        title: '',
        titleWidget: const HostSelectionWidget(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Khởi tạo mới',
                    style: TextStyle(
                        color: AppTheme.accentCyan,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10),
                  if (controller.isLoading.value)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text('Gợi ý: ',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  Expanded(
                    child: Autocomplete<SuggestionItem>(
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<SuggestionItem>.empty();
                        }
                        final searchText = textEditingValue.text.toUpperCase();
                        var filtered = controller.suggestMHs.where((item) =>
                            item.maBuuGui.toUpperCase().contains(searchText) &&
                            !controller.isMaHieuExists(item.maBuuGui));

                        if (filtered.length == 1 &&
                            controller.isLockedCustomer.value) {
                          final item = filtered.first;
                          Future.delayed(const Duration(milliseconds: 100), () {
                            controller.onSelectedSuggestion(item);
                            autocompleteTextController.clear();
                          });
                          return const Iterable<SuggestionItem>.empty();
                        }

                        return filtered;
                      },
                      displayStringForOption: (SuggestionItem item) =>
                          '${item.maBuuGui} - ${item.tenKH}',
                      fieldViewBuilder: (context, textEditingController,
                          focusNode, onFieldSubmitted) {
                        autocompleteTextController = textEditingController;
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          style: TextStyle(color: AppTheme.textPrimary),
                          decoration: AppTheme.inputDecoration(
                            label: 'Nhập hoặc chọn mã bưu gửi',
                            suffix: IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: AppTheme.primaryBlue),
                              onPressed: () {
                                final code = textEditingController.text
                                    .trim()
                                    .toUpperCase();
                                if (code.isNotEmpty) {
                                  HapticFeedback.lightImpact();
                                  controller.addMaHieuFromText(code);
                                  textEditingController.clear();
                                }
                              },
                            ),
                          ).copyWith(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (value) {
                            final code = value.trim().toUpperCase();
                            if (code.isNotEmpty) {
                              HapticFeedback.lightImpact();
                              controller.addMaHieuFromText(code);
                              textEditingController.clear();
                            }
                          },
                        );
                      },
                      onSelected: (SuggestionItem item) {
                        controller.onSelectedSuggestion(item);
                        autocompleteTextController.clear();
                      },
                      optionsViewBuilder: (context, onSelected,
                          Iterable<SuggestionItem> options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxHeight: 250, maxWidth: 350),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final item = options.elementAt(index);
                                  final isSelectedCustomer = controller
                                          .isLockedCustomer.value &&
                                      controller.lockedMaKH.value == item.maKH;
                                  return InkWell(
                                    onTap: () => onSelected(item),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelectedCustomer
                                            ? AppTheme.primaryBlue
                                                .withValues(alpha: 0.1)
                                            : Colors.transparent,
                                        border: Border(
                                          bottom: BorderSide(
                                              color: AppTheme.dividerColor),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.maBuuGui,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textPrimary,
                                                    decoration:
                                                        isSelectedCustomer
                                                            ? TextDecoration
                                                                .underline
                                                            : null,
                                                  ),
                                                ),
                                              ),
                                              if (item.khoiLuong != null &&
                                                  item.khoiLuong! > 0)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.orange.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    '${item.khoiLuong}g',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.deepOrange,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              if (isSelectedCustomer) ...[
                                                SizedBox(width: 4),
                                                Icon(Icons.lock,
                                                    size: 14,
                                                    color:
                                                        AppTheme.primaryBlue),
                                              ],
                                            ],
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            '${item.tenKH} (${item.maKH})',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    bool isError = controller.stateText.value
                        .toLowerCase()
                        .contains('lỗi');
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isError
                            ? AppTheme.dangerRed.withValues(alpha: 0.1)
                            : AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isError
                              ? AppTheme.dangerRed.withValues(alpha: 0.3)
                              : AppTheme.primaryBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        controller.stateText.value.isEmpty
                            ? 'Sẵn sàng'
                            : controller.stateText.value,
                        style: TextStyle(
                          color: isError
                              ? AppTheme.dangerRed
                              : AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Obx(() => Checkbox(
                            value: controller.isLockedCustomer.value,
                            activeColor: AppTheme.primaryBlue,
                            checkColor: AppTheme.textPrimary,
                            side:
                                BorderSide(color: AppTheme.textSecondary),
                            onChanged: (value) {
                              if (value == true &&
                                  controller.lockedMaKH.value.isNotEmpty) {
                                controller.isLockedCustomer.value = true;
                                controller.refreshSuggestions();
                              } else if (value == false) {
                                controller.unlockCustomer();
                              }
                            },
                          )),
                      Expanded(
                        child: Obx(() {
                          final hasLocked =
                              controller.lockedMaKH.value.isNotEmpty;
                          if (hasLocked) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: controller.isLockedCustomer.value
                                    ? AppTheme.primaryBlue
                                        .withValues(alpha: 0.2)
                                    : AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: controller.isLockedCustomer.value
                                      ? AppTheme.primaryBlue
                                          .withValues(alpha: 0.5)
                                      : AppTheme.dividerColor,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    controller.isLockedCustomer.value
                                        ? Icons.lock
                                        : Icons.lock_open,
                                    size: 14,
                                    color: controller.isLockedCustomer.value
                                        ? AppTheme.primaryBlue
                                        : AppTheme.textSecondary,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${controller.lockedTenKH.value} (${controller.lockedMaKH.value})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: controller.isLockedCustomer.value
                                            ? AppTheme.primaryBlue
                                            : AppTheme.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      controller.lockedMaKH.value = "";
                                      controller.lockedTenKH.value = "";
                                      controller.isLockedCustomer.value = false;
                                      controller.refreshSuggestions();
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return Text(
                              'Chưa chọn KH',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            );
                          }
                        }),
                      ),
                      SizedBox(width: 8),
                      Obx(() => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Auto',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Checkbox(
                                value: controller.isAutoSend.value,
                                activeColor: AppTheme.accentCyan,
                                checkColor: AppTheme.primaryDark,
                                side: BorderSide(
                                    color: AppTheme.textSecondary),
                                visualDensity: VisualDensity.compact,
                                onChanged: (value) =>
                                    controller.toggleAutoSend(value ?? false),
                              ),
                            ],
                          )),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [],
            ),
            Expanded(
              child: GetBuilder<KhoiTaoMoiController>(
                builder: (dx) => Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: AppTheme.dividerColor,
                    dataTableTheme: DataTableThemeData(
                      headingTextStyle: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                      dataTextStyle:
                          TextStyle(color: AppTheme.textPrimary),
                      headingRowColor:
                          WidgetStateProperty.all(AppTheme.surfaceCard),
                    ),
                  ),
                  child: DataTable2(
                    showCheckboxColumn: false,
                    sortAscending: false,
                    sortColumnIndex: 1,
                    columnSpacing: 3,
                    horizontalMargin: 8,
                    minWidth: 300,
                    dataRowHeight: 35,
                    headingRowHeight: 35,
                    columns: const [
                      DataColumn2(
                        label: Text('STT', style: TextStyle(fontSize: 12)),
                        fixedWidth: 35,
                        size: ColumnSize.S,
                      ),
                      DataColumn2(
                        label: Text(''),
                        tooltip: 'Trạng thái',
                        fixedWidth: 25,
                      ),
                      DataColumn2(
                          label: Text('Code', style: TextStyle(fontSize: 12)),
                          fixedWidth: 110,
                          numeric: false),
                      DataColumn2(
                          label: Text('KL', style: TextStyle(fontSize: 12)),
                          fixedWidth: 35,
                          numeric: true),
                      DataColumn2(
                          label: Text('COD', style: TextStyle(fontSize: 12)),
                          fixedWidth: 45,
                          numeric: true),
                      DataColumn2(
                          label: Text('State', style: TextStyle(fontSize: 12)),
                          fixedWidth: 45),
                    ],
                    rows: _rowsBuild(dx, context),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Row(
                      children: [
                        AppTheme.actionButton(
                          icon: Icons.barcode_reader,
                          label: 'Quét QR',
                          color: AppTheme.warningOrange,
                          onPressed: () => controller.addKhachHangAsQR(),
                        ),
                        const SizedBox(width: 10),
                        AppTheme.actionButton(
                          icon: Icons.delete_outline,
                          label: 'Xóa',
                          color: AppTheme.dangerRed,
                          onPressed: () => controller.deleteSelected(),
                          onLongPress: () => controller.deleteAll(),
                        ),
                        const SizedBox(width: 10),
                        AppTheme.actionButton(
                          icon: Icons.send_outlined,
                          label: 'Send',
                          color: AppTheme.primaryBlue,
                          onPressed: () => controller.sendToPC(),
                        ),
                        const SizedBox(width: 10),
                        AppTheme.actionButton(
                          icon: Icons.print_outlined,
                          label: 'In BD1 New',
                          color: AppTheme.warningOrange,
                          onPressed: () {
                            controller.printAll();
                          },
                        ),
                        const SizedBox(width: 10),
                        AppTheme.actionButton(
                          icon: Icons.camera_alt,
                          label: 'Chụp ảnh',
                          color: AppTheme.successGreen,
                          onPressed: () => controller.captureImage(),
                        ),
                      ],
                    )
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
        return AppTheme.successGreen;
      default:
        return AppTheme.textSecondary;
    }
  }

  List<DataRow> _rowsBuild(KhoiTaoMoiController dx, BuildContext context) {
    return List<DataRow>.generate(
        dx.buuGuis.length,
        (index) => DataRow(
                selected: index == dx.iBuuGui.value,
                onSelectChanged: (value) {
                  dx.iBuuGui.value = index;
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
                    style: TextStyle(
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
                            color: _getStatusColor(dx.buuGuis[index].trangThai),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(
                    dx.buuGuis[index].maBuuGui!,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textPrimary),
                  )),
                  DataCell(Text(
                    dx.buuGuis[index].khoiLuong == null
                        ? ""
                        : dx.buuGuis[index].khoiLuong!.toString(),
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textPrimary),
                  )),
                  DataCell(Text(
                    dx.buuGuis[index].money == null
                        ? ""
                        : dx.buuGuis[index].money!.toString(),
                    style: TextStyle(
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