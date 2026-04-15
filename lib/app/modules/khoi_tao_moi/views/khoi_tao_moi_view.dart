import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/widgets/host_selection_widget.dart';

import '../controllers/khoi_tao_moi_controller.dart';

class KhoiTaoMoiView extends GetView<KhoiTaoMoiController> {
  KhoiTaoMoiView({super.key});

  final TextEditingController textInputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const HostSelectionWidget(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Khởi tạo mới',
                    style: TextStyle(
                        color: Colors.teal,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  if (controller.isLoading.value)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textInputController,
                      decoration: InputDecoration(
                        hintText: 'Nhập mã bưu gửi',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon:
                              const Icon(Icons.add_circle, color: Colors.blue),
                          onPressed: () {
                            final code =
                                textInputController.text.trim().toUpperCase();
                            if (code.isNotEmpty) {
                              HapticFeedback.lightImpact();
                              controller.addMaHieuFromText(code);
                              textInputController.clear();
                            }
                          },
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (value) {
                        final code = value.trim().toUpperCase();
                        if (code.isNotEmpty) {
                          HapticFeedback.lightImpact();
                          controller.addMaHieuFromText(code);
                          textInputController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.barcode_reader,
                    label: 'Quét QR',
                    color: Colors.orange,
                    onPressed: () => controller.addKhachHangAsQR(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GetBuilder<KhoiTaoMoiController>(
                builder: (dx) => DataTable2(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SizedBox(
                width: 400,
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          label: 'Xóa',
                          color: Colors.red,
                          onPressed: () => controller.deleteSelected(),
                          onLongPress: () => controller.deleteAll(),
                        ),
                        const SizedBox(width: 10),
                        _buildActionButton(
                          icon: Icons.send_outlined,
                          label: 'Send',
                          color: Colors.blue,
                          onPressed: () => controller.sendToPC(),
                        ),
                        const SizedBox(width: 10),
                        _buildActionButton(
                          icon: Icons.print_outlined,
                          label: 'In BD1 New',
                          color: Colors.orange,
                          onPressed: () {
                            // if (controller.selectedState.value != "CC") {
                            //   controller.printAllAndDelete();
                            // } else {
                            controller.printAll();
                            // }
                          },
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
        return Colors.red;
      case 'đã phân hướng':
        return Colors.blue;
      case 'đang đi thu gom':
        return Colors.yellow;
      case 'nhận hàng thành công':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      onPressed: onPressed,
      onLongPress: onLongPress,
    );
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
                    return Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.6);
                  }
                  return null;
                }),
                cells: [
                  DataCell(Text(
                    dx.buuGuis[index].index.toString(),
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 102, 102, 96),
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
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic),
                  )),
                  DataCell(Text(
                    dx.buuGuis[index].khoiLuong == null
                        ? ""
                        : dx.buuGuis[index].khoiLuong!.toString(),
                    style: const TextStyle(fontSize: 11),
                  )),
                  DataCell(Text(
                    dx.buuGuis[index].money == null
                        ? ""
                        : dx.buuGuis[index].money!.toString(),
                    style: const TextStyle(fontSize: 11),
                  )),
                  DataCell(Text(
                    dx.buuGuis[index].trangThaiRequest == null
                        ? ""
                        : dx.buuGuis[index].trangThaiRequest!.toString(),
                    style: const TextStyle(color: Colors.teal, fontSize: 11),
                  )),
                ]));
  }
}
