import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:phone_auto_portal/app/modules/import_images/controllers/image_import_controller.dart';
import 'package:phone_auto_portal/app/modules/import_images/models/image_batch_model.dart';
import 'package:phone_auto_portal/app/modules/import_images/models/image_item_model.dart';
import 'package:phone_auto_portal/app/widgets/host_selection_widget.dart';

class ImportImagesView extends StatelessWidget {
  ImportImagesView({super.key});

  final controller = Get.put(ImageImportController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const HostSelectionWidget(),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Cài đặt thư mục',
            onPressed: () => _showFolderSettings(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.batches.isEmpty) {
          return _buildEmptyState();
        }
        return _buildBatchList();
      }),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButton: Obx(() => controller.isLoading.value
          ? const SizedBox()
          : FloatingActionButton.extended(
              onPressed: controller.loadImagesFromFolders,
              icon: const Icon(Icons.folder_open),
              label: const Text('Lấy ảnh hôm nay'),
            )),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có ảnh nào',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút "Lấy ảnh hôm nay" để bắt đầu',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: controller.batches.length,
      itemBuilder: (context, index) {
        final batch = controller.batches[index];
        return _buildBatchCard(batch, index);
      },
    );
  }

  Widget _buildBatchCard(ImageBatch batch, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => controller.toggleBatchSelection(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Checkbox(
                    value: batch.isSelected,
                    onChanged: (_) => controller.toggleBatchSelection(index),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      batch.timeRangeLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildBatchStatusChip(batch),
                ],
              ),

              const Divider(height: 24),

              // Statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.image,
                    label: 'Tổng',
                    value: '${batch.totalImages}',
                    color: Colors.blue,
                  ),
                  _buildStatItem(
                    icon: Icons.check_circle,
                    label: 'Xong',
                    value: '${batch.processedCount}',
                    color: Colors.green,
                  ),
                  _buildStatItem(
                    icon: Icons.error,
                    label: 'Lỗi',
                    value: '${batch.errorCount}',
                    color: Colors.red,
                  ),
                ],
              ),

              // Progress bar
              if (batch.isProcessing) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: batch.progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(batch.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],

              // Image grid preview
              const SizedBox(height: 12),
              _buildImageGridPreview(batch),

              // Actions
              if (batch.errorCount > 0) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => controller.retryErrorImages(batch),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry lỗi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatchStatusChip(ImageBatch batch) {
    Color color;
    String label;
    IconData icon;

    switch (batch.status) {
      case BatchStatus.pending:
        color = Colors.grey;
        label = 'Chờ';
        icon = Icons.pending;
        break;
      case BatchStatus.processing:
        color = Colors.blue;
        label = 'Đang xử lý';
        icon = Icons.sync;
        break;
      case BatchStatus.completed:
        color = Colors.green;
        label = 'Hoàn thành';
        icon = Icons.check_circle;
        break;
      case BatchStatus.error:
        color = Colors.red;
        label = 'Có lỗi';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildImageGridPreview(ImageBatch batch) {
    final maxPreview = 4;
    final hasMore = batch.images.length > maxPreview;
    final previewCount = hasMore ? maxPreview : batch.images.length;
    final remainingCount = batch.images.length - maxPreview;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hasMore ? previewCount + 1 : previewCount,
        itemBuilder: (context, index) {
          // Hiển thị thumbnail cho các ảnh đầu tiên
          if (index < previewCount) {
            final image = batch.images[index];
            return _buildImageThumbnail(image);
          }

          // Hiển thị indicator "+X" cho các ảnh còn lại
          return Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.grey[100],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 24, color: Colors.grey[600]),
                  const SizedBox(height: 4),
                  Text(
                    '+$remainingCount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageThumbnail(ImageItem image) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              image.file,
              fit: BoxFit.cover,
            ),
          ),
          // Status overlay
          Positioned(
            top: 4,
            right: 4,
            child: _buildImageStatusIcon(image),
          ),
          // MaHieu overlay
          if (image.maHieu != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  image.maHieu!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageStatusIcon(ImageItem image) {
    IconData icon;
    Color color;

    switch (image.status) {
      case ImageProcessingStatus.pending:
        icon = Icons.pending;
        color = Colors.grey;
        break;
      case ImageProcessingStatus.rotating:
        icon = Icons.rotate_right;
        color = Colors.blue;
        break;
      case ImageProcessingStatus.readingBarcode:
      case ImageProcessingStatus.readingOCR:
        icon = Icons.qr_code_scanner;
        color = Colors.orange;
        break;
      case ImageProcessingStatus.uploading:
        icon = Icons.cloud_upload;
        color = Colors.purple;
        break;
      case ImageProcessingStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case ImageProcessingStatus.error:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 12, color: Colors.white),
    );
  }

  Widget _buildBottomBar() {
    return Obx(() {
      if (controller.batches.isEmpty) return const SizedBox();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status message
            if (controller.statusMessage.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  controller.statusMessage.value,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),

            // Overall progress
            if (controller.isLoading.value) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: controller.totalProgress.value,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${controller.processedImages.value}/${controller.selectedTotalImages.value} ảnh',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.processSelectedBatches,
                icon: const Icon(Icons.cloud_upload),
                label: Text(
                  controller.isLoading.value
                      ? 'Đang xử lý...'
                      : 'Xử lý & Upload',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Hiển thị dialog cài đặt thư mục
  void _showFolderSettings(BuildContext context) {
    Get.dialog(
      Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_open, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Thư mục',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Chọn các thư mục chứa ảnh:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _FolderSelector(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget để chọn thư mục
class _FolderSelector extends StatefulWidget {
  @override
  _FolderSelectorState createState() => _FolderSelectorState();
}

class _FolderSelectorState extends State<_FolderSelector> {
  late List<String> selectedFolders;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  void _loadFolders() {
    final storage = GetStorage();
    final folders = storage.read<List<dynamic>>('selected_folders');
    selectedFolders = folders?.map((e) => e.toString()).toList() ?? [];
  }

  void _saveFolders() {
    GetStorage().write('selected_folders', selectedFolders);
  }

  Future<void> _pickFolder() async {
    try {
      // Sử dụng file_picker để chọn thư mục
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Chọn thư mục chứa ảnh',
        lockParentWindow: true,
      );

      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        final dir = Directory(selectedDirectory);
        if (await dir.exists()) {
          setState(() {
            if (!selectedFolders.contains(selectedDirectory)) {
              selectedFolders.add(selectedDirectory);
              _saveFolders();
            }
          });
          Get.snackbar(
            'Thành công',
            'Đã thêm thư mục:\n$selectedDirectory',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.snackbar(
            'Lỗi',
            'Thư mục không tồn tại: $selectedDirectory',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể mở file picker: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _removeFolder(int index) {
    setState(() {
      selectedFolders.removeAt(index);
      _saveFolders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Danh sách thư mục
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: selectedFolders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Chưa có thư mục nào',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: selectedFolders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.folder, color: Colors.amber),
                      title: Text(
                        selectedFolders[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeFolder(index),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        // Nút thêm thư mục
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickFolder,
            icon: const Icon(Icons.add),
            label: const Text('Thêm thư mục'),
          ),
        ),
      ],
    );
  }
}
