import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dingoai_rt_controller.dart';
import '../../../routes/app_pages.dart';

class DiNgoaiRtView extends GetView<DiNgoaiRtController> {
  const DiNgoaiRtView({super.key});

  Widget _buildDiNgoaiItem(BuildContext context, int index) {
    return Obx(() {
      final item = controller.diNgoaiItems[index];
      final isSelected = item.selected;

      // Determine colors based on state
      Color cardColor;
      Color avatarColor;
      Widget? trailingIcon;

      switch (item.state) {
        case 1: // Thành công
          cardColor = isSelected
              ? Colors.green.shade100
              : Colors.green.shade50;
          avatarColor = Colors.green;
          trailingIcon = const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 22,
          );
          break;
        case 2: // Thất bại
          cardColor = isSelected
              ? Colors.red.shade100
              : Colors.red.shade50;
          avatarColor = Colors.red;
          trailingIcon = const Icon(
            Icons.cancel,
            color: Colors.red,
            size: 22,
          );
          break;
        default: // Chưa xử lý
          cardColor =
              isSelected ? Colors.blue.shade50 : Colors.white;
          avatarColor =
              isSelected ? Colors.blue : Colors.grey.shade300;
          trailingIcon = null;
      }

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        color: cardColor,
        child: ListTile(
          onTap: () => controller.toggleSelect(index),
          leading: CircleAvatar(
            backgroundColor: avatarColor,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: item.state == 0 && !isSelected
                    ? Colors.black
                    : Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          title: Text(
            item.code,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              decoration: item.state == 1
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: item.state == 2 ? Colors.red.shade700 : null,
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
          trailing: trailingIcon,
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
          // Nút Ping kiểm tra kết nối PC
          Obx(() {
            Color pingColor;
            IconData pingIcon;
            String tooltip;

            switch (controller.pingStatus.value) {
              case 'online':
                pingColor = Colors.green;
                pingIcon = Icons.cell_tower;
                tooltip =
                    'PC Online - ${controller.pingResponseTime.value}ms';
                break;
              case 'offline':
                pingColor = Colors.red;
                pingIcon = Icons.signal_wifi_off;
                tooltip = 'PC Offline';
                break;
              case 'pinging':
                pingColor = Colors.orange;
                pingIcon = Icons.sync;
                tooltip = 'Đang ping...';
                break;
              default:
                pingColor = Colors.grey.shade400;
                pingIcon = Icons.cell_tower;
                tooltip = 'Kiểm tra kết nối PC';
            }

            return IconButton(
              icon: controller.isPinging.value
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.orange),
                      ),
                    )
                  : Icon(pingIcon, color: pingColor),
              tooltip: tooltip,
              onPressed: controller.isPinging.value
                  ? null
                  : controller.pingPC,
            );
          }),
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
          // Nút Danh Sách BĐ & Tự Động
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Mở Danh Sách BĐ & Tự Động',
            onPressed: () => Get.toNamed(Routes.DANHSACHBD),
          ),
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
                              onLongPress: controller.isLoading.value
                                  ? null
                                  : controller.lamMoi,
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
                          onLongPress: controller.deleteAll,
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
