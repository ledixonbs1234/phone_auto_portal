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
        actions: [
          // Toggle button for barcode scanning section
          Obx(() => IconButton(
                icon: Icon(
                  controller.isScanSectionVisible.value
                      ? Icons.search_off
                      : Icons.search,
                ),
                tooltip: controller.isScanSectionVisible.value
                    ? 'Ẩn tìm kiếm'
                    : 'Hiện tìm kiếm',
                onPressed: () {
                  controller.toggleScanSection();
                },
              )),
        ],
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
            // Collapsible barcode scanning section
            Obx(() => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: controller.isScanSectionVisible.value ? 50 : 0,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: controller.isScanSectionVisible.value
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height:
                                      40, // Reduced height for compact design
                                  child: TextField(
                                    controller:
                                        controller.barcodeInputController,
                                    style: const TextStyle(
                                        fontSize: 14), // Smaller font
                                    decoration: InputDecoration(
                                      labelText: 'Mã sản phẩm',
                                      hintText: 'Nhập hoặc quét mã',
                                      labelStyle: const TextStyle(fontSize: 12),
                                      hintStyle: const TextStyle(fontSize: 12),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.0),
                                      ),
                                      prefixIcon:
                                          const Icon(Icons.qr_code, size: 18),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () {
                                          controller.barcodeInputController
                                              .clear();
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 24, minHeight: 24),
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      if (value.isNotEmpty) {
                                        controller.refreshPortal(null);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 40, // Matching height with text field
                                  child: Obx(() => ElevatedButton.icon(
                                        icon: Icon(
                                          controller.isScanning.value
                                              ? Icons.hourglass_empty
                                              : Icons.qr_code_scanner,
                                          color: Colors.purple,
                                          size: 16, // Smaller icon
                                        ),
                                        label: Text(
                                          controller.isScanning.value
                                              ? "Quét..."
                                              : "Quét",
                                          style: const TextStyle(
                                            color: Colors.purple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12, // Smaller font
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          side: BorderSide(
                                              color: Colors.purple
                                                  .withOpacity(0.5)),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6.0)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4, horizontal: 8),
                                        ),
                                        onPressed: () {
                                          controller.scanBarcode();
                                        },
                                      )),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                )),
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
                                showImprovedDialog(context, index);
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
                            label: 'Xác Nhận',
                            color: Colors.red,
                            onPressed: () {
                              _showConfirmProcessDialog(context);
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

  void showImprovedDialog(BuildContext context, int index) {
    controller.getMaHieuToShow(index);

    final String? currentPortalStatus = controller.portals[index].trangThai;
    final bool showDeleteButton = currentPortalStatus == "2";

    Get.dialog(
      barrierDismissible: true,
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: PopScope(
          onPopInvoked: (didPop) {
            // Hủy stream quét khi đóng dialog
            controller.cancelBulkQRScanInDialog();
          },
          child: GetBuilder<PortalinfoController>(
            builder: (dx) => ConstrainedBox(
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
                    // Title, bộ đếm và nút QR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "Danh sách",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Obx(() {
                          if (dx.selectedDialogItemCount.value == 0) {
                            return const SizedBox.shrink();
                          }
                          return Chip(
                            label: Text(
                                '${dx.selectedDialogItemCount.value} đã chọn'),
                            backgroundColor: Colors.deepPurple.shade100,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            labelStyle: TextStyle(
                                color: Colors.deepPurple.shade900,
                                fontSize: 12),
                          );
                        }),
                        if (showDeleteButton)
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner,
                                color: Colors.deepPurple),
                            tooltip: 'Quét hàng loạt',
                            onPressed: () =>
                                controller.startBulkQRScanInDialog(),
                          ),
                      ],
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
                      child: !dx.isShowEdit.value
                          ? const Center(child: CircularProgressIndicator())
                          : dx.currentMaHieusInPortal.isEmpty
                              ? const Center(
                                  child: Text("Không có dữ liệu mã hiệu."))
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: dx.currentMaHieusInPortal.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, i) {
                                    final item = dx.currentMaHieusInPortal[i];
                                    return ListTile(
                                      dense: true,
                                      tileColor: item.selected
                                          ? Colors.blue.withOpacity(0.2)
                                          : null,
                                      onTap: showDeleteButton
                                          ? () => controller
                                              .toggleItemSelectedInDialog(item)
                                          : null,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        item.code ?? 'N/A',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(item.Date ?? 'N/A'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(item.Weight ?? 'N/A'),
                                          if (showDeleteButton) ...[
                                            const SizedBox(width: 4),
                                            _buildIconDialogButton(
                                              icon: Icons.scale,
                                              color: Colors.blueAccent,
                                              tooltip: 'Thay đổi trọng lượng',
                                              onPressed: () {
                                                _showChangeWeightDialog(
                                                    context, item, index);
                                              },
                                            ),
                                            const SizedBox(width: 4),
                                            _buildIconDialogButton(
                                              icon: Icons.delete,
                                              color: Colors.redAccent,
                                              tooltip: 'Xóa',
                                              onPressed: () {
                                                _showConfirmDeleteDialog(
                                                    context, item, index);
                                              },
                                            ),
                                          ]
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                    // Nút xóa tất cả
                    if (showDeleteButton && dx.isAnyItemSelectedInDialog)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.delete_sweep, size: 18),
                              label: const Text('Xóa đã chọn'),
                              onPressed: () =>
                                  _showConfirmDeleteAllDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconDialogButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 30, maxHeight: 30),
      child: IconButton(
        icon: Icon(icon, color: color),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 20,
        onPressed: onPressed,
      ),
    );
  }

  // Dialog xác nhận xóa một item
  void _showConfirmDeleteDialog(
      BuildContext context, StateMaHieu item, int portalIndex) {
    Get.dialog(
      AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa bưu gửi ${item.code ?? ''}?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Đóng dialog xác nhận
              controller.deleteBG(item);
              // Đợi một chút để server xử lý rồi làm mới
              Future.delayed(const Duration(seconds: 1),
                  () => controller.getMaHieuToShow(portalIndex));
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Dialog xác nhận xóa tất cả item đã chọn
  void _showConfirmDeleteAllDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text(
            "Bạn có chắc chắn muốn xóa tất cả các bưu gửi đã chọn không?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Đóng dialog xác nhận
              controller.deleteSelectedBGs();
            },
            child:
                const Text("Xóa tất cả", style: TextStyle(color: Colors.red)),
          ),
        ],
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
              // Đợi một chút rồi cập nhật lại list
              Future.delayed(const Duration(seconds: 1),
                  () => controller.getMaHieuToShow(index));
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // Dialog xác nhận xử lý portal
  void _showConfirmProcessDialog(BuildContext context) {
    // First check if any portals are selected
    final selectedPortals = controller.getSelectedsPortal();

    if (selectedPortals.isEmpty) {
      // Show warning if no portals are selected
      Get.snackbar(
        'Cảnh báo',
        'Vui lòng chọn ít nhất một khách hàng để xác nhận xử lý',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Prepare the list of selected portal names
    final selectedNames =
        selectedPortals.map((portal) => portal.name ?? 'N/A').toList();
    final count = selectedPortals.length;

    // Create the content message
    String contentMessage = count == 1
        ? "Bạn có muốn xác nhận xử lý khách hàng này không?\n\n"
        : "Bạn có muốn xác nhận xử lý $count khách hàng này không?\n\n";

    contentMessage += count == 1 ? "Khách hàng:\n" : "Danh sách khách hàng:\n";

    // Limit display to first 10 items to prevent dialog overflow
    final displayCount = selectedNames.length > 10 ? 10 : selectedNames.length;
    for (int i = 0; i < displayCount; i++) {
      contentMessage += "${i + 1}. ${selectedNames[i]}\n";
    }

    if (selectedNames.length > 10) {
      contentMessage += "... và ${selectedNames.length - 10} khách hàng khác";
    }

    Get.dialog(
      AlertDialog(
        title: const Text("Xác nhận xử lý"),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: 400,
          ),
          child: SingleChildScrollView(
            child: Text(
              contentMessage.trim(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Đóng dialog xác nhận
              controller.xacNhansPortal();
            },
            child: const Text("Xác nhận",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
