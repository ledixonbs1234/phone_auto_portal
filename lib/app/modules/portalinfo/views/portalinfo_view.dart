import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/widgets/host_selection_widget.dart';
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

  String _getLastWords(String? text, int count) {
    if (text == null || text.isEmpty) return "Không có địa chỉ";
    if (text.length <= count) return text;
    return "...${text.substring(text.length - count)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const HostSelectionWidget(),
        centerTitle: true,
      ),
      body: Center(
        child: Column(children: [
          // Host Selection Widget at the top
          // Row chứa các button Refresh và Chọn Ngày
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.check_circle,
                    label: "Check",
                    color: Colors.orange,
                    onPressed: () {
                      controller.checkPortal();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Swapped: REFRESH moved to the right
                _buildActionButton(
                  icon: Icons.refresh,
                  label: "",
                  color: Colors.blue,
                  onPressed: () {
                    controller.refreshPortal(null);
                  },
                ),
                const SizedBox(width: 8),

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
                    ))
              ],
            ),
          ),
          // Collapsible search & filter section
          Obx(() => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: controller.isScanSectionVisible.value ? null : 0,
                constraints: controller.isScanSectionVisible.value
                    ? BoxConstraints(
                        minHeight: 0,
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      )
                    : const BoxConstraints(maxHeight: 0),
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: controller.isScanSectionVisible.value
                    ? ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8.0),
                        children: [
                          // Row 1: Barcode scanning
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: controller.barcodeInputController,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'Mã sản phẩm',
                                    hintText: 'Nhập hoặc quét mã',
                                    labelStyle: const TextStyle(fontSize: 12),
                                    hintStyle: const TextStyle(fontSize: 12),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.0),
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
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 1,
                                child: Obx(() => ElevatedButton.icon(
                                      icon: Icon(
                                        controller.isScanning.value
                                            ? Icons.hourglass_empty
                                            : Icons.qr_code_scanner,
                                        color: Colors.purple,
                                        size: 16,
                                      ),
                                      label: Text(
                                        controller.isScanning.value
                                            ? "Quét..."
                                            : "Quét",
                                        style: const TextStyle(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        side: BorderSide(
                                            color:
                                                Colors.purple.withOpacity(0.5)),
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
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Row 2: Từ ngày đến ngày
                          Row(children: [
                            Expanded(
                              child: Obx(
                                () => InkWell(
                                  onTap: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: controller.fromDate.value,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now(),
                                    );
                                    if (pickedDate != null) {
                                      controller.fromDate.value = pickedDate;
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Từ: ${controller.fromDate.value.day}/${controller.fromDate.value.month}/${controller.fromDate.value.year}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: Obx(
                                  () => InkWell(
                                    onTap: () async {
                                      DateTime? pickedDate =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: controller.toDate.value,
                                        firstDate: DateTime(2025),
                                        lastDate: DateTime.now(),
                                      );
                                      if (pickedDate != null) {
                                        controller.toDate.value = pickedDate;
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 18,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Đến: ${controller.toDate.value.day}/${controller.toDate.value.month}/${controller.toDate.value.year}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),
                            // Row 3: Tên người nhận
                          ]),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 50,
                            child: TextField(
                              controller: controller.recipientNameController,
                              onChanged: (value) {
                                controller.recipientNameFilter.value = value;
                              },
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Tên người nhận',
                                hintText: 'Nhập tên người nhận',
                                labelStyle: const TextStyle(fontSize: 12),
                                hintStyle: const TextStyle(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                prefixIcon: const Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                                suffixIcon: Obx(
                                  () => controller
                                          .recipientNameFilter.value.isNotEmpty
                                      ? IconButton(
                                          icon:
                                              const Icon(Icons.clear, size: 16),
                                          onPressed: () {
                                            controller.recipientNameController
                                                .clear();
                                            controller
                                                .recipientNameFilter.value = "";
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                              minWidth: 24, minHeight: 24),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                          // Row 4: Search Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text(
                                'Tìm kiếm',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.blue.shade700,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                              ),
                              onPressed: () {
                                // Trigger search/filter with all parameters
                                controller.refreshPortal(
                                  null,
                                  fromDate: controller.fromDate.value,
                                  toDate: controller.toDate.value,
                                  recipientName:
                                      controller.recipientNameFilter.value,
                                );
                                Get.snackbar(
                                  'Tìm kiếm',
                                  'Đang tìm kiếm với bộ lọc đã chọn...',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.blue,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 2),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              )),
          // Row hiển thị trạng thái
          Container(
            padding: const EdgeInsets.all(8.0),
            width: double.infinity,
            child: Row(
              children: [
                const Text('SL : '),
                Obx(
                  () => Text(
                    '${controller.countPortalSelected.value}',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('TT : '),
                Expanded(
                  child: Obx(
                    () => Text(
                      '${controller.stateText}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Row hiển thị số lượng
          // DataTable hiển thị danh sách portal
          Expanded(
            child: GetBuilder<PortalinfoController>(
              builder: (dx) => DataTable2(
                showCheckboxColumn: true,
                sortAscending: controller.sortAscending.value,
                sortColumnIndex: controller.sortColumnIndex.value,
                onSelectAll: (value) {
                  for (var row in dx.portals) {
                    row.selected = value!;
                  }
                  dx.update();
                },
                columnSpacing: 5,
                horizontalMargin: 10,
                columns: [
                  const DataColumn2(
                    label: Text('Thứ Tự'),
                    fixedWidth: 30,
                    size: ColumnSize.L,
                  ),
                  DataColumn2(
                    label: const Text('Tên'),
                    numeric: false,
                    onSort: (columnIndex, ascending) {
                      controller.sortPortals(columnIndex, ascending);
                    },
                  ),
                  DataColumn2(
                    label: const Text('SL'),
                    fixedWidth: 30,
                    numeric: true,
                    onSort: (columnIndex, ascending) {
                      controller.sortPortals(columnIndex, ascending);
                    },
                  ),
                  DataColumn2(
                    label: const Text('State'),
                    fixedWidth: 70,
                    onSort: (columnIndex, ascending) {
                      controller.sortPortals(columnIndex, ascending);
                    },
                  ),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SizedBox(
                width: 400,
                height: 40,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.analytics,
                        label: 'Thống kê',
                        color: Colors.purple,
                        onPressed: () {
                          controller.sendThongKe();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.print,
                        label: 'In Sort',
                        color: Colors.teal,
                        onPressed: () {
                          controller.printPageSelectedAndSort();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.print_outlined,
                        label: 'In Ra Vô',
                        color: Colors.red,
                        onPressed: () {
                          controller.printPageSelected();
                        },
                      ),
                      const SizedBox(width: 8),
                      // Check Direction Button
                      _buildActionButton(
                        icon: Icons.qr_code_scanner,
                        label: 'Check Hướng',
                        color: Colors.purple,
                        onPressed: () {
                          controller.goToDirectionScanning();
                        },
                      ),
                      const SizedBox(width: 8),
                      // Check Direction Button
                      _buildActionButton(
                        icon: Icons.qr_code_scanner,
                        label: 'Di Ngoài RT',
                        color: Colors.purple,
                        onPressed: () {
                          controller.goToDiNgoaiRT();
                        },
                      )
                    ],
                  ),
                ])),
          ),
        ]),
      ),
    );
  }

  void showImprovedDialog(BuildContext context, int index) {
    final String? currentPortalStatus = controller.portals[index].trangThai;
    final bool showDeleteButton = currentPortalStatus == "2";

    // Reset trạng thái highlight khi mở dialog mới
    controller.similarIdCodes.clear();

    Get.dialog(
      barrierDismissible: true,
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: PopScope(
          onPopInvoked: (didPop) {
            controller.cancelBulkQRScanInDialog();
          },
          child: GetBuilder<PortalinfoController>(
            builder: (dx) => ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height *
                    0.9, // Tăng chiều cao một chút
                maxWidth: 400,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 8.0),
                    // --- HEADER: Title & Counters ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "Danh sách (${dx.currentMaHieusInPortal.length})",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                  fontSize: 18,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showDeleteButton || currentPortalStatus == "3")
                          Row(
                            children: [
                              // Nút tìm tên trùng - Hiện cho cả status 2 và 3
                              IconButton(
                                icon: const Icon(Icons.person_search,
                                    color: Colors.orange),
                                tooltip: 'Tìm tên giống nhau > 90%',
                                onPressed: () => controller.findSimilarNames(),
                              ),
                              // Nút quét QR - Hiện cho cả status 2 và 3 (nếu muốn) hoặc chỉ 2
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
                      ],
                    ),

                    const SizedBox(height: 8.0),

                    // --- TOOLBAR: View Mode & Sorting ---
                    Row(
                      children: [
                        // Toggle Đơn giản / Chi tiết
                        const Text("Chi tiết:", style: TextStyle(fontSize: 12)),
                        Obx(() => Switch(
                              value: controller.isDetailedView.value,
                              activeColor: Colors.blue,
                              onChanged: (val) =>
                                  controller.toggleViewMode(val),
                            )),

                        const Spacer(), // Đẩy Sort sang phải

                        // Sort Buttons (Giữ nguyên logic cũ nhưng làm gọn)
                        _buildSortButton(
                            "KL", "Trọng lượng", Colors.deepPurple),
                        const SizedBox(width: 4),
                        _buildSortButton("\$", "COD", Colors.green),
                      ],
                    ),

                    // --- SELECTED COUNTER ---
                    Obx(() {
                      if (dx.selectedDialogItemCount.value == 0)
                        return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.deepPurple.shade200),
                        ),
                        child: Text(
                          'Đã chọn: ${dx.selectedDialogItemCount.value} bưu gửi',
                          style: TextStyle(
                              color: Colors.deepPurple.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    }),

                    const Divider(thickness: 1.0),

                    // --- LIST VIEW ---
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

                                    // Kiểm tra xem item có nằm trong danh sách trùng tên không
                                    final isSimilar = controller.similarIdCodes
                                        .contains(item.IDCODE);

                                    // Xác định màu nền: Ưu tiên Selected -> Similar -> Default
                                    Color? tileColor;
                                    if (item.selected) {
                                      tileColor = Colors.blue.withOpacity(0.2);
                                    } else if (isSimilar) {
                                      tileColor = Colors.amber.withOpacity(
                                          0.3); // Highlight màu cam nhạt
                                    }

                                    return Obx(() => ListTile(
                                          dense: true,
                                          tileColor: tileColor,
                                          onTap: showDeleteButton
                                              ? () => controller
                                                  .toggleItemSelectedInDialog(
                                                      item)
                                              : null,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 4, vertical: 0),

                                          // Code (Mã hiệu)
                                          title: Row(
                                            children: [
                                              if (isSimilar)
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(right: 4),
                                                  child: Icon(
                                                      Icons
                                                          .warning_amber_rounded,
                                                      size: 16,
                                                      color: Colors.orange),
                                                ),
                                              Text(
                                                item.code ?? 'N/A',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),

                                          // Hiển thị nội dung dựa trên Toggle
                                          subtitle: controller
                                                  .isDetailedView.value
                                              ? Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item.Name ??
                                                          "Không có tên",
                                                      style: const TextStyle(
                                                          color: Colors.black87,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 13),
                                                    ),
                                                    Text(
                                                      _getLastWords(
                                                          item.Address, 50),
                                                      style: TextStyle(
                                                          color: Colors
                                                              .grey.shade700,
                                                          fontSize: 12),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign: TextAlign.left,
                                                      textDirection:
                                                          TextDirection.ltr,
                                                    ),
                                                    Text(item.Date ?? '',
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            fontStyle: FontStyle
                                                                .italic,
                                                            color:
                                                                Colors.grey)),
                                                  ],
                                                )
                                              : Text(item.Date ?? 'N/A',
                                                  style: const TextStyle(
                                                      fontSize: 12)),

                                          // Cột bên phải: KL, Tiền, Actions
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    item.Weight ?? '0',
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                  Text(
                                                    item.Money ?? '0',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.green.shade700,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (showDeleteButton) ...[
                                                const SizedBox(width: 8),
                                                _buildIconDialogButton(
                                                  icon: Icons.scale,
                                                  color: Colors.blueAccent,
                                                  tooltip: 'Sửa KL',
                                                  onPressed: () =>
                                                      _showChangeWeightDialog(
                                                          context, item, index),
                                                ),
                                                _buildIconDialogButton(
                                                  icon: Icons.delete,
                                                  color: Colors.redAccent,
                                                  tooltip: 'Xóa',
                                                  onPressed: () =>
                                                      _showConfirmDeleteDialog(
                                                          context, item, index),
                                                ),
                                              ]
                                            ],
                                          ),
                                        ));
                                  },
                                ),
                    ),

                    // Footer: Delete All Button
                    if (showDeleteButton && dx.isAnyItemSelectedInDialog)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete_sweep, size: 18),
                            label: const Text('Xóa các mục đã chọn'),
                            onPressed: () =>
                                _showConfirmDeleteAllDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
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

  // Helper widget cho nút sort để code gọn hơn
  Widget _buildSortButton(String label, String sortType, Color color) {
    return Obx(() => InkWell(
          onTap: () => controller.sortDialogList(sortType),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: controller.dialogSortOption.value == sortType
                  ? color
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: controller.dialogSortOption.value == sortType
                            ? Colors.white
                            : Colors.black54)),
                if (controller.dialogSortOption.value == sortType)
                  Icon(
                    controller.dialogSortAscending.value
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 12,
                    color: Colors.white,
                  )
              ],
            ),
          ),
        ));
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
        content:
            const Text("Bạn có chắc chắn muốn xóa các bưu gửi đã chọn không?"),
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
                const Text("Xóa đã chọn", style: TextStyle(color: Colors.red)),
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

  // Helper method to build category count display
  Widget _buildCategoryCount(String categoryName, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$categoryName: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.8),
        ),
      ),
    );
  }
}
