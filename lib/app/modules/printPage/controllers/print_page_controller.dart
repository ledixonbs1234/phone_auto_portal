import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';

class PrintPageController extends GetxController {
  // TextEditingController cho nhập mã hiệu thủ công
  final TextEditingController maHieuController = TextEditingController();

  // Danh sách mã hiệu đã quét (sử dụng List<String> đơn giản)
  final RxList<String> scannedMaHieus = <String>[].obs;

  // Mobile Scanner Controller
  MobileScannerController? mobileScannerController;
  StreamSubscription<BarcodeCapture>? _barcodeSubscription;

  // Trạng thái quét
  final RxBool isScanning = false.obs;

  @override
  void onClose() {
    maHieuController.dispose();
    _barcodeSubscription?.cancel();
    mobileScannerController?.dispose();
    super.onClose();
  }

  /// Thêm mã hiệu từ TextField
  void addMaHieuFromInput() {
    final maHieu = maHieuController.text.trim().toUpperCase();
    if (maHieu.isNotEmpty && !scannedMaHieus.contains(maHieu)) {
      scannedMaHieus.add(maHieu);
      maHieuController.clear();

      Get.snackbar(
        'Thành công',
        'Đã thêm mã hiệu: $maHieu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    } else if (scannedMaHieus.contains(maHieu)) {
      Get.snackbar(
        'Thông báo',
        'Mã hiệu đã tồn tại trong danh sách',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    }
  }

  /// Xóa một mã hiệu khỏi danh sách
  void removeMaHieu(String maHieu) {
    scannedMaHieus.remove(maHieu);
  }

  /// Xóa tất cả mã hiệu
  void clearAllMaHieus() {
    if (scannedMaHieus.isNotEmpty) {
      Get.defaultDialog(
        title: "Xác nhận",
        content: const Text("Bạn có chắc muốn xóa tất cả mã hiệu?"),
        onConfirm: () {
          scannedMaHieus.clear();
          Get.back();
          Get.snackbar(
            'Thành công',
            'Đã xóa tất cả mã hiệu',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 1),
          );
        },
        onCancel: () => Get.back(),
      );
    }
  }

  /// Bắt đầu quét QR trong dialog
  void startBulkQRScanInDialog() {
    _barcodeSubscription?.cancel(); // Hủy stream cũ nếu có

    // Khởi tạo mobile scanner controller nếu chưa có
    mobileScannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [
        BarcodeFormat.qrCode,
        BarcodeFormat.code128,
        BarcodeFormat.code39
      ],
    );

    // Lắng nghe barcode từ mobile scanner
    _barcodeSubscription =
        mobileScannerController?.barcodes.listen((BarcodeCapture capture) {
      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        final String? code = barcode.rawValue;
        if (code != null && code.isNotEmpty) {
          final maHieu = code.trim().toUpperCase();

          // Kiểm tra và thêm mã hiệu nếu chưa tồn tại
          if (!scannedMaHieus.contains(maHieu)) {
            scannedMaHieus.add(maHieu);
            HapticFeedback
                .lightImpact(); // Rung nhẹ để báo hiệu quét thành công
          }
        }
      }
    });

    isScanning.value = true;
    // Hiển thị scanner dialog
    _showMobileScannerDialog();
  }

  /// Hủy quét QR
  void cancelBulkQRScanInDialog() {
    _barcodeSubscription?.cancel();
    _barcodeSubscription = null;
    mobileScannerController?.dispose();
    mobileScannerController = null;
    isScanning.value = false;
  }

  /// Hiển thị dialog quét QR
  void _showMobileScannerDialog() {
    Get.dialog(
      Dialog(
        child: Container(
          width: 300,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Quét mã QR/Barcode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Obx(() => Text(
                    'Đã quét: ${scannedMaHieus.length} mã',
                    style: const TextStyle(fontSize: 14),
                  )),
              const SizedBox(height: 16),
              Expanded(
                child: mobileScannerController != null
                    ? MobileScanner(
                        controller: mobileScannerController!,
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      cancelBulkQRScanInDialog();
                      Get.back();
                    },
                    child: const Text('Đóng'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      mobileScannerController?.toggleTorch();
                    },
                    child: const Text('Đèn flash'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    ).then((_) {
      // Đảm bảo cleanup khi dialog đóng
      cancelBulkQRScanInDialog();
    });
  }

  /// In tất cả mã hiệu
  void printAllMaHieus() {
    if (scannedMaHieus.isEmpty) {
      Get.snackbar(
        'Thông báo',
        'Không có mã hiệu nào để in',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Gửi danh sách mã hiệu để in
    FirebaseManager().addMessage(MessageReceiveModel(
        "printMaHieus", jsonEncode(scannedMaHieus.toList())));

    Get.snackbar(
      'Thành công',
      'Đã gửi yêu cầu in ${scannedMaHieus.length} mã hiệu',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Kiểm tra mã hiệu có hợp lệ không (tùy chọn)
  bool isValidMaHieu(String maHieu) {
    const pattern = r'^[c|C|r|R|e|E|p|P][a-zA-Z]\d{9}[v|V][n|N]$';
    final regExp = RegExp(pattern);
    return regExp.hasMatch(maHieu);
  }
}
