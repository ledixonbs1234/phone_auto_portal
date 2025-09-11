import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/direction_scanning_controller.dart';

class DirectionScanningView extends GetView<DirectionScanningController> {
  const DirectionScanningView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Quét Barcode Theo Hướng'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.goBack,
        ),
        actions: [
          Obx(() => controller.isDataPrepared.value
              ? IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.green),
                  onPressed: controller.prepareDirectionData,
                  tooltip: 'Cập nhật dữ liệu',
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  onPressed: controller.prepareDirectionData,
                  tooltip: 'Chuẩn bị dữ liệu',
                )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang chuẩn bị dữ liệu...'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info
              _buildHeaderInfo(),

              const SizedBox(height: 24),

              // Direction Selection
              _buildDirectionSelection(),

              const SizedBox(height: 24),

              // Direction Statistics
              _buildDirectionStatistics(),

              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(),

              const SizedBox(height: 24),

              // Scan Progress (if active)
              _buildScanProgress(),

              const SizedBox(height: 24),

              // Recent Scan Results
              _buildRecentResults(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeaderInfo() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Thông tin Portal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Portal đã chọn: ${controller.selectedPortalIds.length}'),
                    Text('Tổng bưu gửi: ${controller.allMaHieus.length}'),
                    Text(
                      'Trạng thái: ${controller.isDataPrepared.value ? "✅ Đã chuẩn bị" : "⏳ Chưa chuẩn bị"}',
                      style: TextStyle(
                        color: controller.isDataPrepared.value
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📍 Chọn Hướng Xử Lý',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedDirection.value.isEmpty
                      ? null
                      : controller.selectedDirection.value,
                  hint: const Text('-- Chọn hướng cần xử lý --'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  items: controller.availableDirections
                      .map((direction) => DropdownMenuItem<String>(
                            value: direction,
                            child: Row(
                              children: [
                                _getDirectionIcon(direction),
                                const SizedBox(width: 8),
                                Text(direction),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: controller.isDataPrepared.value
                      ? (value) {
                          if (value != null) {
                            controller.selectedDirection.value = value;
                          }
                        }
                      : null,
                )),
            if (!controller.isDataPrepared.value) ...[
              const SizedBox(height: 8),
              const Text(
                'Vui lòng chuẩn bị dữ liệu trước khi chọn hướng',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionStatistics() {
    return Obx(() {
      if (!controller.isDataPrepared.value) {
        return const SizedBox();
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 Thống Kê Theo Hướng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...controller.availableDirections.map((direction) {
                final count =
                    controller.packagesByDirection[direction]?.length ?? 0;
                final percentage = controller.allMaHieus.isEmpty
                    ? 0.0
                    : (count / controller.allMaHieus.length) * 100;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _getDirectionIcon(direction),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          direction,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getDirectionColor(direction),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count (${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Obx(() => ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Bắt Đầu Quét'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: (controller.isDataPrepared.value &&
                            controller.selectedDirection.value.isNotEmpty)
                        ? () => controller.startDirectionScan(
                            controller.selectedDirection.value)
                        : null,
                  )),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.analytics),
                label: const Text('Xem Kết Quả'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: controller.showScanResults,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Nút xem bưu gửi còn lại
        Obx(() {
          final session = controller.currentScanSession.value;
          if (session == null || !controller.isDirectionScanActive.value) {
            return const SizedBox();
          }

          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.list_alt),
              label: Text('Xem BG Còn Lại (${session.remainingCount})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => controller.showRemainingPackages(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildScanProgress() {
    return Obx(() {
      final session = controller.currentScanSession.value;
      if (session == null || !controller.isDirectionScanActive.value) {
        return const SizedBox();
      }

      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Đang Quét ${session.direction}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      'Tiến độ: ${session.processedCount}/${session.totalPackagesInDirection}'),
                  Text('${session.progress.toStringAsFixed(1)}%'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: session.progress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRecentResults() {
    return Obx(() {
      if (controller.scannedPackagesInSession.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.qr_code_2, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có dữ liệu quét',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn hướng và bắt đầu quét để xem kết quả',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.history),
                  const SizedBox(width: 8),
                  const Text(
                    'Kết Quả Gần Đây',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${controller.scannedPackagesInSession.length} mã',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.scannedPackagesInSession.length > 10
                    ? 10
                    : controller.scannedPackagesInSession.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final pkg = controller.scannedPackagesInSession[
                      controller.scannedPackagesInSession.length - 1 - index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      pkg.isFoundInCurrentDirection
                          ? Icons.check_circle
                          : Icons.error,
                      color: pkg.statusColor,
                      size: 20,
                    ),
                    title: Text(
                      pkg.barcode,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      pkg.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: pkg.statusColor,
                      ),
                    ),
                    trailing: Text(
                      '${pkg.scannedTime.hour.toString().padLeft(2, '0')}:${pkg.scannedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
              if (controller.scannedPackagesInSession.length > 10) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: controller.showScanResults,
                    child: Text(
                      'Xem tất cả ${controller.scannedPackagesInSession.length} kết quả',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Icon _getDirectionIcon(String direction) {
    switch (direction) {
      case 'RA':
        return const Icon(Icons.arrow_upward, color: Colors.red);
      case 'VÔ':
        return const Icon(Icons.arrow_downward, color: Colors.green);
      case 'Quảng Nam':
        return const Icon(Icons.location_city, color: Colors.orange);
      case 'Quảng Ngãi':
        return const Icon(Icons.location_city, color: Colors.purple);
      default:
        return const Icon(Icons.location_on, color: Colors.grey);
    }
  }

  Color _getDirectionColor(String direction) {
    switch (direction) {
      case 'RA':
        return Colors.red;
      case 'VÔ':
        return Colors.green;
      case 'Quảng Nam':
        return Colors.orange;
      case 'Quảng Ngãi':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
