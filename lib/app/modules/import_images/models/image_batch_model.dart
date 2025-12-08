import 'package:phone_auto_portal/app/modules/import_images/models/image_item_model.dart';

/// Trạng thái của batch
enum BatchStatus {
  pending,
  processing,
  completed,
  error,
}

/// Model cho batch ảnh (nhóm ảnh cách nhau 2 phút)
class ImageBatch {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final List<ImageItem> images;

  bool isSelected;
  BatchStatus status;
  int processedCount;
  int errorCount;

  ImageBatch({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.images,
    this.isSelected = false,
    this.status = BatchStatus.pending,
    this.processedCount = 0,
    this.errorCount = 0,
  });

  ImageBatch copyWith({
    bool? isSelected,
    BatchStatus? status,
    int? processedCount,
    int? errorCount,
    List<ImageItem>? images,
  }) {
    return ImageBatch(
      id: id,
      startTime: startTime,
      endTime: endTime,
      images: images ?? this.images,
      isSelected: isSelected ?? this.isSelected,
      status: status ?? this.status,
      processedCount: processedCount ?? this.processedCount,
      errorCount: errorCount ?? this.errorCount,
    );
  }

  int get totalImages => images.length;

  double get progress => totalImages > 0 ? processedCount / totalImages : 0.0;

  String get timeRangeLabel {
    final startStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  bool get isCompleted => status == BatchStatus.completed;
  bool get hasErrors => errorCount > 0;
  bool get isProcessing => status == BatchStatus.processing;

  void updateProgress() {
    processedCount = images.where((img) => img.isProcessed).length;
    errorCount = images.where((img) => img.hasError).length;

    if (processedCount == totalImages) {
      status = BatchStatus.completed;
    } else if (errorCount > 0 && processedCount + errorCount == totalImages) {
      status = BatchStatus.error;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'totalImages': totalImages,
      'processedCount': processedCount,
      'errorCount': errorCount,
      'status': status.name,
      'images': images.map((img) => img.toJson()).toList(),
    };
  }
}
