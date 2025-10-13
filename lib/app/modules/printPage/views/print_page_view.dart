import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/print_page_controller.dart';

class PrintPageView extends GetView<PrintPageController> {
  const PrintPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In Mã Hiệu'),
        centerTitle: true,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header section với input và nút quét
            _buildInputSection(),

            const SizedBox(height: 20),

            // Danh sách mã hiệu
            _buildMaHieuList(),

            const SizedBox(height: 20),

            // Buttons section
            _buildButtonSection(),
          ],
        ),
      ),
    );
  }

  /// Widget cho phần nhập liệu
  Widget _buildInputSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập mã hiệu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.maHieuController,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã hiệu (VD: CA123456789VN)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.qr_code),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: controller.addMaHieuFromInput,
                        tooltip: 'Thêm mã hiệu',
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => controller.addMaHieuFromInput(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: controller.startBulkQRScanInDialog,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Quét QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget cho danh sách mã hiệu
  Widget _buildMaHieuList() {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Text(
                        'Danh sách mã hiệu (${controller.scannedMaHieus.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      )),
                  TextButton.icon(
                    onPressed: controller.clearAllMaHieus,
                    icon: const Icon(Icons.clear_all, color: Colors.red),
                    label: const Text(
                      'Xóa tất cả',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  if (controller.scannedMaHieus.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có mã hiệu nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Nhập thủ công hoặc quét QR để thêm mã hiệu',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.scannedMaHieus.length,
                    itemBuilder: (context, index) {
                      final maHieu = controller.scannedMaHieus[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            maHieu,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => controller.removeMaHieu(maHieu),
                            tooltip: 'Xóa mã hiệu',
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget cho phần buttons
  Widget _buildButtonSection() {
    return Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.scannedMaHieus.isNotEmpty
                ? controller.printAllMaHieus
                : null,
            icon: const Icon(Icons.print),
            label: Text(
              controller.scannedMaHieus.isNotEmpty
                  ? 'In ${controller.scannedMaHieus.length} mã hiệu'
                  : 'Không có mã hiệu để in',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.scannedMaHieus.isNotEmpty
                  ? Colors.green
                  : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
  }
}
