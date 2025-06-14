import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/portalinfo_controller.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/state_ma_hieu_model.dart'; // Import StateMaHieu

class PortalinfoView extends GetView<PortalinfoController> {
  const PortalinfoView({super.key});

  // Hàm tạo button chung theo style của CreateNewView
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // Nền button màu trắng
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      onPressed: onPressed,
      onLongPress: onLongPress,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Page'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            // Row chứa các button Refresh và Chọn Ngày
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.refresh,
                      label: "Refresh",
                      color: Colors.blue,
                      onPressed: () {
                        controller.refreshPortal(null);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.calendar_today,
                      label: "Chọn Ngày",
                      color: Colors.green,
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now());
                        if (pickedDate != null) {
                          controller.selectedDate.value = pickedDate;
                          controller
                              .refreshPortal(controller.selectedDate.value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Row hiển thị trạng thái
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text('Trạng Thái : '),
                      Obx(
                        () => Text(
                          '${controller.stateText}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            // Row hiển thị số lượng
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text('Số Lượng : '),
                      Obx(
                        () => Text(
                          '${controller.countPortalSelected.value}',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // DataTable hiển thị danh sách portal
            Expanded(
              child: GetBuilder<PortalinfoController>(
                builder: (dx) => DataTable2(
                  showCheckboxColumn: true,
                  sortAscending: false,
                  sortColumnIndex: 1,
                  onSelectAll: (value) {
                    for (var row in dx.portals) {
                      row.selected = value!;
                    }
                    dx.update();
                  },
                  columnSpacing: 5,
                  horizontalMargin: 10,
                  columns: const [
                    DataColumn2(
                      label: Text('Thứ Tự'),
                      fixedWidth: 30,
                      size: ColumnSize.L,
                    ),
                    DataColumn2(label: Text('Tên'), numeric: false),
                    DataColumn2(
                        label: Text('SL'), fixedWidth: 30, numeric: true),
                    DataColumn2(label: Text('State'), fixedWidth: 70),
                  ],
                  rows: List<DataRow>.generate(
                      dx.portals.length,
                      (index) => DataRow(
                              selected: dx.portals[index].selected,
                              onLongPress: () {
                                controller.isShowEdit.value = false;
                                controller.getMaHieuToShow(index);
                                showImprovedDialog(
                                    context, index, dx, controller);
                              },
                              onSelectChanged: (value) {
                                dx.iPotal.value = index;
                                if (dx.portals[index].selected != value) {
                                  dx.portals[index].selected = value!;
                                }
                                // Cập nhật số lượng portal được chọn
                                dx.countPortalSelected.value = dx.portals
                                    .where((element) => element.selected)
                                    .length;
                                dx.update();
                              },
                              color: WidgetStateProperty.resolveWith<Color?>(
                                  (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.6);
                                }
                                return null;
                              }),
                              cells: [
                                DataCell(Text(
                                  index.toString(),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 102, 102, 96),
                                      fontWeight: FontWeight.bold),
                                )),
                                DataCell(Text(
                                  dx.portals[index].name!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: !dx.portals[index].isXuLyDiNgoai
                                          ? const Color(0xff008DDA)
                                          : Colors.orange,
                                      fontStyle: FontStyle.italic),
                                )),
                                DataCell(Text(
                                  dx.portals[index].soLuong == null
                                      ? ""
                                      : dx.portals[index].soLuong.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                                )),
                                DataCell(
                                  dx.portals[index].trangThai == null
                                      ? const Text("")
                                      : dx.portals[index].trangThai == "2"
                                          ? const Text(
                                              "Đang xử lý",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green),
                                            )
                                          : dx.portals[index].trangThai == "3"
                                              ? const Text("Chấp Nhận",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xff5356FF)))
                                              : const Text(""),
                                ),
                              ])),
                ),
              ),
            ),
            // Card chứa row với các tuỳ chọn và button xử lý portal
            Obx(
              () => Card(
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Dropdown chọn may chủ
                      DropdownButton<String>(
                        value: controller.selectedMayChu.value,
                        onChanged: (value) {
                          controller.selectedMayChu.value = value!;
                        },
                        items: controller.maychus.map((e) {
                          return DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          );
                        }).toList(),
                      ),
                      // Checkbox sắp xếp
                      Checkbox(
                        value: controller.isSortDiNgoai.value,
                        activeColor: Colors
                            .deepPurple, // Ví dụ: sử dụng màu sâu cho checkbox
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        onChanged: (e) {
                          controller.isSortDiNgoai.value = e!;
                        },
                      ),
                      const Text("Sắp xếp"),
                      // Checkbox In
                      Checkbox(
                        value: controller.isPrinted.value,
                        activeColor: Colors.orange,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        onChanged: (e) {
                          controller.isPrinted.value = e!;
                        },
                      ),
                      const Text("In"),
                    ],
                  ),
                  // Row chứa các button xử lý dữ liệu portal
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.download,
                            label: 'Lấy DL',
                            color: Colors.blue,
                            onPressed: () {
                              controller.layDuLieu();
                            },
                            onLongPress: () {
                              controller.layDuLieuLo();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.save,
                            label: 'Lưu BD1',
                            color: Colors.orange,
                            onPressed: () {
                              controller.test();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.send,
                            label: 'Đi Ngoài',
                            color: Colors.green,
                            onPressed: () {
                              controller.sendDiNgoai();
                            },
                            onLongPress: () {
                              controller.sendDiNgoaiAndRunBD();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            // Row chứa các button cuối: Sửa, In Sắp Xếp, In
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.edit,
                      label: 'Sửa',
                      color: Colors.purple,
                      onPressed: () {
                        controller.editHangHoas();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.print,
                      label: 'In Sort',
                      color: Colors.teal,
                      onPressed: () {
                        controller.printPageSelectedAndSort();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.print_outlined,
                      label: 'In Ra Vô',
                      color: Colors.red,
                      onPressed: () {
                        controller.printPageSelected();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showImprovedDialog(BuildContext context, int index,
      PortalinfoController dx, PortalinfoController controller) {
    controller.isShowEdit.value = false; // Reset trước khi hiển thị dialog mới
    controller.getMaHieuToShow(index);
    // Lấy trạng thái của portal hiện tại để kiểm tra
    final String? currentPortalStatus = dx.portals[index].trangThai;
    final bool showDeleteButton =
        currentPortalStatus == "2"; // Điều kiện hiển thị nút xóa

    Get.dialog(
      barrierDismissible: true, // Cho phép đóng bằng cách chạm bên ngoài
      Dialog(
        backgroundColor: Colors.white, // Nền trắng
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: WillPopScope(
          onWillPop: () async => true,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 400,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    "Danh sách hàng hóa",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                  ),
                  const SizedBox(height: 8.0),
                  const Divider(thickness: 1.0),
                  const SizedBox(height: 12.0),
                  // Thông tin Người Nhập
                  Row(
                    children: [
                      const Text(
                        'Người Nhập: ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      Text(
                        dx.portals[index].nguoiNhap ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Danh sách Mã hiệu
                  Expanded(
                    child: Obx(() {
                      if (!controller.isShowEdit.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (dx.currentMaHieusInPortal.isEmpty) {
                        return const Center(
                            child: Text("Không có dữ liệu mã hiệu."));
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: dx.currentMaHieusInPortal.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final item = dx.currentMaHieusInPortal[i];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.code ?? 'N/A',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(item.Date ?? 'N/A'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item.Weight ?? 'N/A'),
                                if (showDeleteButton) // Space after weight
                                  const SizedBox(width: 4), // Reduced space
                                if (showDeleteButton) // Nút thay đổi trọng lượng
                                  IconButton(
                                    icon: const Icon(Icons.scale,
                                        color: Colors.blueAccent),
                                    tooltip: 'Thay đổi trọng lượng',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    iconSize: 20,
                                    onPressed: () {
                                      _showChangeWeightDialog(
                                          context, item, index);
                                    },
                                  ),
                                if (showDeleteButton) // Space after scale icon
                                  const SizedBox(width: 4), // Reduced space
                                if (showDeleteButton) // Delete icon
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.redAccent),
                                    tooltip: 'Xóa',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    iconSize: 20,
                                    onPressed: () {
                                      Get.dialog(
                                        AlertDialog(
                                          title: const Text("Xác nhận xóa"),
                                          content: Text(
                                              "Bạn có chắc chắn muốn xóa bưu gửi ${item.code ?? ''}?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Get.back(),
                                              child: const Text("Hủy"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Get.back();
                                                controller.deleteBG(item);
                                                Future.delayed(
                                                    const Duration(seconds: 2),
                                                    () {
                                                  controller
                                                      .getMaHieuToShow(index);
                                                });
                                              },
                                              child: const Text("Xóa",
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Hàm hiển thị dialog thay đổi trọng lượng
  void _showChangeWeightDialog(
      BuildContext context, StateMaHieu item, int index) {
    final TextEditingController weightController =
        TextEditingController(text: item.Weight ?? '');

    Get.dialog(
      AlertDialog(
        title: const Text("Thay đổi trọng lượng"),
        content: TextField(
          controller: weightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Trọng lượng mới"),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.updateWeight(item, weightController.text);
              Future.delayed(const Duration(seconds: 6), () {
                controller.getMaHieuToShow(index);
              });
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }
}
