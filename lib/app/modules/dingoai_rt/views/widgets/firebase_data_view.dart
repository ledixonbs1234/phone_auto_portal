import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/dingoai_rt_controller.dart';

/// Widget hiển thị danh sách dữ liệu từ Firebase Real-time Database
class FirebaseDataView extends GetView<DiNgoaiRtController> {
  const FirebaseDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dữ liệu Firebase'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.diNgoaiItems.isEmpty) {
          return const Center(
            child: Text(
              'Không có dữ liệu từ Firebase',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.diNgoaiItems.length,
          itemBuilder: (context, index) {
            final item = controller.diNgoaiItems[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor:
                      item.state == 1 ? Colors.red : Colors.green,
                  child: Text(
                    '${item.index}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  item.code,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  item.tenBuuCuc ?? 'N/A',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Mã barcode', item.code),
                        _buildInfoRow('ID Code', item.idCode),
                        _buildInfoRow('Trạng thái',
                            item.state == 1 ? 'Cần xử lý' : 'Bình thường'),
                        _buildInfoRow('Tỉnh gốc', item.tinhGocGui),
                        _buildInfoRow('Tỉnh dự kiến', item.tinhDuKien),
                        _buildInfoRow('Bưu cục nhận', item.buuCucNhanTemp),
                        _buildInfoRow('Mã bưu cục', item.maBuuCuc),
                        _buildInfoRow('Tên bưu cục', item.tenBuuCuc),
                        _buildInfoRow(
                            'Khối lượng (g)',
                            item.khoiLuong != null
                                ? item.khoiLuong.toString()
                                : 'N/A'),
                        _buildInfoRow('Địa chỉ', item.address),
                        _buildInfoRow(
                            'Chuyển hoàn',
                            item.isChuyenHoan
                                ? 'Có'
                                : 'Không'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
