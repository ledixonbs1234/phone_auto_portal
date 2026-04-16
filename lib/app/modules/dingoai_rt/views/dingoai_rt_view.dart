import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dingoai_rt_controller.dart';

class DiNgoaiRtView extends GetView<DiNgoaiRtController> {
  const DiNgoaiRtView({super.key});

  Widget _buildDiNgoaiItem(BuildContext context, int index) {
    return Obx(() {
      final item = controller.diNgoaiItems[index];
      final isSelected = item.selected;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        child: ListTile(
          onTap: () => controller.toggleSelect(index),
          leading: CircleAvatar(
            backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 12,
              ),
            ),
          ),
          title: Text(
            item.code,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            item.buuCucNhanTemp ?? '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đi Ngoài RT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.goBack,
        ),
        actions: [
          // Nút QR Scanner
          Obx(() => IconButton(
                icon: Icon(
                  controller.isScanning.value
                      ? Icons.qr_code_scanner
                      : Icons.qr_code_scanner,
                ),
                tooltip: 'Quét QR Code',
                onPressed:
                    controller.isScanning.value ? null : controller.showScanner,
              )),
          // Nút Refresh từ Firebase
          Obx(() => IconButton(
                icon: controller.isLoading.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh dữ liệu từ Firebase',
                onPressed:
                    controller.isLoading.value ? null : controller.refreshData,
              )),
        ],
      ),
      body: Column(
        children: [
          // ── Header: Trạng thái & Thống kê ──
          Obx(() => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trạng thái
                    if (controller.stateText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            controller.stateText.value.isEmpty
                                ? 'Quét QR hoặc chọn item để xử lý'
                                : controller.stateText.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    // Thống kê
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đi ngoài: ${controller.diNgoaiItems.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Đã chọn: ${controller.selectedCount.value}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),

          // ── ListView ──
          Expanded(
            child: Obx(() {
              if (controller.diNgoaiItems.isEmpty) {
                return const Center(
                  child: Text(
                    'Không có dữ liệu',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }
              return ListView.builder(
                itemCount: controller.diNgoaiItems.length,
                itemBuilder: (context, index) =>
                    _buildDiNgoaiItem(context, index),
              );
            }),
          ),

          // ── Bottom Action Bar ──
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Row 1: Checkboxes
                Row(
                  children: [
                    // Checkbox Auto
                    Expanded(
                      child: Obx(() => CheckboxListTile(
                            title: const Text(
                              'Auto',
                              style: TextStyle(fontSize: 14),
                            ),
                            value: controller.isAuto.value,
                            onChanged: (val) =>
                                controller.isAuto.value = val ?? false,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          )),
                    ),
                    // Checkbox In (Print)
                    Expanded(
                      child: Obx(() => CheckboxListTile(
                            title: const Text(
                              'In',
                              style: TextStyle(fontSize: 14),
                            ),
                            value: controller.isPrint.value,
                            onChanged: (val) =>
                                controller.isPrint.value = val ?? false,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          )),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Row 2: Buttons
                Row(
                  children: [
                    // Button Refresh
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Obx(() => ElevatedButton.icon(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.refreshData,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            )),
                      ),
                    ),
                    // Button Xóa
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton.icon(
                          onPressed: controller.deleteSelected,
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Xóa'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Button Auto
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton.icon(
                          onPressed: controller.runAuto,
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Auto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
