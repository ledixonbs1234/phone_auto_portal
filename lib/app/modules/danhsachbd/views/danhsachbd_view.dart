import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/danhsachbd_controller.dart';
import 'package:data_table_2/data_table_2.dart';

class DanhSachBDView extends GetView<DanhSachBDController> {
  const DanhSachBDView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Sách BĐ & Tự Động'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshData(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.data.value;
        if (data == null) {
          return const Center(child: Text('Không có dữ liệu'));
        }

        return Column(
          children: [
            // Thống kê số lượng
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Kiện', data.countKien, Colors.blue),
                  _buildStatCard('Túi', data.countTui, Colors.orange),
                  _buildStatCard('Bao', data.countBao, Colors.green),
                ],
              ),
            ),
            
            // Khu vực nhập mã (autoAdd)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.textController,
                      focusNode: controller.focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Quét/Nhập mã hiệu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code_scanner),
                      ),
                      onSubmitted: controller.onSubmitted,
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => controller.onSubmitted(controller.textController.text),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    ),
                    child: const Text('Gửi'),
                  ),
                ],
              ),
            ),

            // Nút Tạo BD từ BD đang chọn
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Text(
                    'Đang chọn: ${controller.selectedBD.value.isEmpty ? "Chưa chọn" : controller.selectedBD.value}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  )),
                  ElevatedButton.icon(
                    onPressed: controller.selectedBD.value.isEmpty ? null : () => controller.createBD(controller.selectedBD.value),
                    icon: const Icon(Icons.add_box),
                    label: const Text('Tạo BĐ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Danh sách các tuyến (LocBDs)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 400,
                  headingRowHeight: 40,
                  dataRowHeight: 50,
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columns: const [
                    DataColumn2(label: Text('Tuyến', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
                    DataColumn2(label: Text('SL', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.S),
                    DataColumn2(label: Text('Chọn', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.S),
                  ],
                  rows: data.locBDs.map((loc) {
                    bool isSelected = controller.selectedBD.value == loc.tenBD;
                    Color bgColor = Colors.transparent;
                    if (loc.isSendAlled == '#FFD28F') {
                      bgColor = Colors.orange.shade100; // Đã gửi/xong?
                    }
                    if (isSelected) {
                      bgColor = Colors.blue.withOpacity(0.2);
                    }

                    return DataRow(
                      color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) => bgColor),
                      onSelectChanged: (selected) {
                        if (selected == true) {
                          controller.selectBD(loc.tenBD);
                        }
                      },
                      cells: [
                        DataCell(Text(loc.tenBD)),
                        DataCell(Text(loc.count.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(
                          Radio<String>(
                            value: loc.tenBD,
                            groupValue: controller.selectedBD.value,
                            onChanged: (value) {
                              if (value != null) controller.selectBD(value);
                            },
                          )
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(count.toString(), style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
