import 'package:flutter/material.dart';

/// Model để lưu trữ thông tin bưu gửi được quét
class ScannedPackage {
  final String barcode;
  final DateTime scannedTime;
  final String? foundInDirection; // RA, VÔ, Quảng Nam, Quảng Ngãi
  final bool isFoundInCurrentDirection;
  final String currentDirection;

  ScannedPackage({
    required this.barcode,
    required this.scannedTime,
    this.foundInDirection,
    required this.isFoundInCurrentDirection,
    required this.currentDirection,
  });

  factory ScannedPackage.fromJson(Map<String, dynamic> json) {
    return ScannedPackage(
      barcode: json['barcode'],
      scannedTime: DateTime.parse(json['scannedTime']),
      foundInDirection: json['foundInDirection'],
      isFoundInCurrentDirection: json['isFoundInCurrentDirection'],
      currentDirection: json['currentDirection'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'scannedTime': scannedTime.toIso8601String(),
      'foundInDirection': foundInDirection,
      'isFoundInCurrentDirection': isFoundInCurrentDirection,
      'currentDirection': currentDirection,
    };
  }

  /// Trạng thái hiển thị cho UI
  String get statusText {
    if (isFoundInCurrentDirection) {
      return 'Đã xử lý ✓';
    } else if (foundInDirection != null) {
      return 'Có trong hướng: $foundInDirection';
    } else {
      return 'Không tìm thấy';
    }
  }

  /// Màu sắc cho UI
  Color get statusColor {
    if (isFoundInCurrentDirection) {
      return Colors.green;
    } else if (foundInDirection != null) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

/// Model để quản lý việc quét theo hướng
class DirectionScanSession {
  final String direction;
  final DateTime startTime;
  final List<ScannedPackage> scannedPackages;
  final int totalPackagesInDirection;
  int processedCount = 0;

  DirectionScanSession({
    required this.direction,
    required this.startTime,
    required this.scannedPackages,
    required this.totalPackagesInDirection,
  });

  /// Tiến độ xử lý (%)
  double get progress {
    if (totalPackagesInDirection == 0) return 0;
    return (processedCount / totalPackagesInDirection) * 100;
  }

  /// Số bưu gửi chưa xử lý
  int get remainingCount => totalPackagesInDirection - processedCount;

  /// Danh sách bưu gửi không tìm thấy
  List<ScannedPackage> get notFoundPackages {
    return scannedPackages.where((p) => !p.isFoundInCurrentDirection).toList();
  }

  /// Danh sách bưu gửi đã xử lý thành công
  List<ScannedPackage> get processedPackages {
    return scannedPackages.where((p) => p.isFoundInCurrentDirection).toList();
  }
}
