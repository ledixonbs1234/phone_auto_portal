import 'dart:io';

/// Trạng thái xử lý của từng ảnh
enum ImageProcessingStatus {
  pending,
  rotating,
  readingBarcode,
  readingOCR,
  uploading,
  completed,
  error,
}

/// Model cho từng ảnh trong batch
class ImageItem {
  final String id;
  final File file;
  final DateTime timestamp;

  String? maHieu;
  String? firebaseUrl;
  int rotationAngle;
  ImageProcessingStatus status;
  String? errorMessage;
  double uploadProgress;

  ImageItem({
    required this.id,
    required this.file,
    required this.timestamp,
    this.maHieu,
    this.firebaseUrl,
    this.rotationAngle = 0,
    this.status = ImageProcessingStatus.pending,
    this.errorMessage,
    this.uploadProgress = 0.0,
  });

  ImageItem copyWith({
    File? file,
    String? maHieu,
    String? firebaseUrl,
    int? rotationAngle,
    ImageProcessingStatus? status,
    String? errorMessage,
    double? uploadProgress,
  }) {
    return ImageItem(
      id: id,
      file: file ?? this.file,
      timestamp: timestamp,
      maHieu: maHieu ?? this.maHieu,
      firebaseUrl: firebaseUrl ?? this.firebaseUrl,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maHieu': maHieu,
      'firebaseUrl': firebaseUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'rotationAngle': rotationAngle,
      'status': status.name,
      'uploadProgress': uploadProgress,
    };
  }

  bool get isProcessed => status == ImageProcessingStatus.completed;
  bool get hasError => status == ImageProcessingStatus.error;
  bool get isProcessing =>
      status != ImageProcessingStatus.pending &&
      status != ImageProcessingStatus.completed &&
      status != ImageProcessingStatus.error;
}
