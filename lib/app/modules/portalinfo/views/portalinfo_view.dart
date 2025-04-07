import 'package:data_table_2/data_table_2.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/portalinfo_controller.dart';

class PortalinfoView extends GetView<PortalinfoController> {
  const PortalinfoView({super.key});

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
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              ElevatedButton(
                  onPressed: () {
                    controller.refreshPortal(null);
                  },
                  child: const Text("Refresh")),
              ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now());
                    if (pickedDate != null) {
                      controller.selectedDate.value = pickedDate;
                      controller.refreshPortal(controller.selectedDate.value);
                    }
                  },
                  child: const Text("Chọn Ngày")),
            ]),
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
                                //count portals selected
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

                                return null; // Use the default value.
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
            Obx(
              () => Card(
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      Checkbox(
                          value: controller.isSortDiNgoai.value,
                          onChanged: (e) {
                            controller.isSortDiNgoai.value = e!;
                          }),
                      const Text("Sắp xếp"),
                      Checkbox(
                          value: controller.isPrinted.value,
                          onChanged: (e) {
                            controller.isPrinted.value = e!;
                          }),
                      const Text("In"),
                    ],
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              controller.layDuLieu();
                            },
                            onLongPress: () {
                              controller.layDuLieuLo();
                            },
                            child: const Text('Lấy DL')),
                        ElevatedButton(
                            onPressed: () {
                              controller.sendAndCheckDiNgoais();
                            },
                            child: const Text("Lưu BD1")),
                        // ElevatedButton(
                        //     onPressed: () {
                        //       controller.sendTest();
                        //     },
                        //     onLongPress: () {
                        //       controller.sendDiNgoaiAndRunBD();
                        //     },
                        //     child: const Text('Test')),
                        ElevatedButton(
                            onPressed: () {
                              controller.sendDiNgoai();
                            },
                            onLongPress: () {
                              controller.sendDiNgoaiAndRunBD();
                            },
                            child: const Text('Đi Ngoài')),
                      ])
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        controller.editHangHoas();
                      },
                      child: const Text("Sửa")),
                  ElevatedButton(
                      onPressed: () {
                        controller.printPageSelectedAndSort();
                      },
                      child: const Text("In Sắp Xếp")),
                  ElevatedButton(
                    onPressed: () {
                      controller.printPageSelected();
                    },
                    child:
                        const Text("In", style: TextStyle(color: Colors.red)),
                  )
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
        // elevation: 4.0, // Thêm độ nổi nếu muốn
        backgroundColor: Colors.white, // Nền trắng rõ ràng
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Bo góc mềm mại
        ),
        child: PopScope(
          // Sử dụng PopScope thay cho WillPopScope
          canPop: true, // Có thể đóng bằng nút back
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height *
                  0.8, // Giới hạn chiều cao
              maxWidth: 400, // Giới hạn chiều rộng nếu cần
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Padding đồng đều
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Để Column co lại theo nội dung
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Title ---
                  Text(
                    "Danh sách hàng hóa",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple, // Màu title nổi bật
                        ),
                  ),
                  const SizedBox(height: 8.0),
                  const Divider(thickness: 1.0), // Vạch ngăn cách
                  const SizedBox(height: 12.0),

                  // --- Thông tin Người Nhập ---
                  Row(
                    children: [
                      const Text(
                        'Người Nhập: ',
                        style: TextStyle(
                            color: Colors.black54), // Màu chữ nhẹ hơn cho label
                      ),
                      Text(
                        dx.portals[index].nguoiNhap ?? 'N/A', // Xử lý null
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent, // Màu xanh dễ chịu hơn
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0), // Khoảng cách rõ ràng

                  // --- Danh sách Mã hiệu ---
                  Expanded(
                    // Để ListView chiếm không gian còn lại
                    child: Obx(() {
                      // Hiển thị loading hoặc thông báo nếu cần
                      if (!controller.isShowEdit.value) {
                        return const Center(
                            child:
                                CircularProgressIndicator()); // Ví dụ loading
                      }
                      if (dx.currentMaHieusInPortal.isEmpty) {
                        return const Center(
                            child: Text("Không có dữ liệu mã hiệu."));
                      }

                      // ListView với giao diện ListTile đẹp hơn
                      return ListView.separated(
                        shrinkWrap: true, // Quan trọng khi trong Column
                        itemCount: dx.currentMaHieusInPortal.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1), // Ngăn cách item
                        itemBuilder: (context, i) {
                          final item = dx.currentMaHieusInPortal[i];
                          return ListTile(
                            dense: true, // Làm list item gọn hơn
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.code ?? 'N/A',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(item.Date ?? 'N/A'),
                            trailing: Row(
                              // Sử dụng Row để chứa cả KL và nút Xóa
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item.Weight ??
                                    'N/A'), // Giữ nguyên Text hiển thị KL
                                const SizedBox(
                                    width: 8), // Khoảng cách giữa KL và nút xóa
                                // --- Chỉ hiển thị nút xóa nếu trạng thái là "2" ---
                                if (showDeleteButton)
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.redAccent),
                                    tooltip: 'Xóa',
                                    padding: EdgeInsets
                                        .zero, // Giảm padding mặc định
                                    constraints:
                                        const BoxConstraints(), // Loại bỏ constraint mặc định
                                    iconSize: 20, // Kích thước icon nhỏ hơn
                                    onPressed: () {
                                      // --- Hiển thị Dialog xác nhận ---
                                      Get.dialog(
                                        AlertDialog(
                                          title: const Text("Xác nhận xóa"),
                                          content: Text(
                                              "Bạn có chắc chắn muốn xóa bưu gửi ${item.code ?? ''}?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Get
                                                  .back(), // Đóng dialog xác nhận
                                              child: const Text("Hủy"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Get.back(); // Đóng dialog xác nhận
                                                // Gọi hàm xóa trong controller
                                                controller.deleteBG(item);
                                                //Chờ khoảng 2s
                                                Future.delayed(
                                                    const Duration(seconds: 2),
                                                    () {
                                                  controller
                                                      .getMaHieuToShow(index);
                                                  // Đóng dialog sau khi xóa
                                                });

                                                // Cập nhật danh sách mã hiệu
                                              },
                                              child: const Text("Xóa",
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                        barrierDismissible:
                                            false, // Không cho đóng bằng cách chạm ra ngoài
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16.0), // Khoảng cách trước nút đóng

                  // --- Nút Đóng ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.back(), // Hành động đóng dialog
                      child: const Text("Đóng"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
