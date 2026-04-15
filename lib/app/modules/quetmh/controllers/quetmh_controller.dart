import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';

class QuetmhController extends GetxController {
  final isScanning = true.obs;
  final lastScannedCode = ''.obs;
  final totalScanned = 0.obs;

  // Map để lưu thời gian quét của từng mã
  final Map<String, DateTime> _scannedCodesTimestamp = {};
  final Duration _blockDuration = const Duration(seconds: 4);

  late MobileScannerController scannerController;

  @override
  void onInit() {
    super.onInit();
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void onClose() {
    scannerController.dispose();
    super.onClose();
  }

  Future<void> onBarcodeDetect(BarcodeCapture capture) async {
    if (!isScanning.value) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        // Kiểm tra xem mã này đã được quét gần đây chưa
        final lastScanTime = _scannedCodesTimestamp[code];
        final now = DateTime.now();

        if (lastScanTime != null) {
          final difference = now.difference(lastScanTime);

          // Nếu chưa đủ 4 giây, bỏ qua
          if (difference < _blockDuration) {
            final remainingSeconds = (_blockDuration - difference).inSeconds;
            'Mã $code bị chặn, còn $remainingSeconds giây'.printInfo();
            return;
          }
        }

        // Lưu thời gian quét mới
        _scannedCodesTimestamp[code] = now;
        lastScannedCode.value = code;
        totalScanned.value++;

        // Phát tiếng beep
        await _playBeep();

        // Gửi lên Firebase ngay lập tức
        _sendToFirebase("$code\n");

        Get.snackbar(
          'Đã quét #${totalScanned.value}',
          'Mã: $code',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
        );

        // Dọn dẹp map để tránh memory leak (xóa các mã cũ hơn 5 phút)
        _cleanupOldScans();
      }
    }
  }

  void _cleanupOldScans() {
    final now = DateTime.now();
    _scannedCodesTimestamp.removeWhere((code, timestamp) {
      return now.difference(timestamp) > const Duration(minutes: 5);
    });
  }

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playBeep() async {
    try {
      final audioPath = "assets/beep.mp3";
      await _playAudio(audioPath);
    } catch (e) {
      'Không thể phát âm thanh: $e'.printInfo();
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      await _audioPlayer.setAsset(path);
      await _audioPlayer.play();
    } catch (e) {
      // Ignore audio errors
    }
  }

  void _sendToFirebase(String code) {
    try {
      final maychu = FirebaseManager().readKey();

      FirebaseManager().addMessageToAppBD(
        maychu,
        MessageReceiveModel('quetmh', code),
      );
    } catch (e) {
      'Lỗi gửi Firebase: $e'.printInfo();
    }
  }

  void toggleScanning() {
    isScanning.value = !isScanning.value;

    Get.snackbar(
      isScanning.value ? 'Đã bật quét' : 'Đã tắt quét',
      '',
      backgroundColor: isScanning.value ? Colors.green : Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }

  void sendMokntb() {
    _sendCommand('mokntb');
  }

  void sendMoemsntb() {
    _sendCommand('moemsntb');
  }

  void sendInbd8() {
    _sendCommand('inbd8');
  }

  void _sendCommand(String command) {
    try {
      final maychu = FirebaseManager().readKey();

      FirebaseManager().addMessageToAppBD(
        maychu,
        MessageReceiveModel('quetmh', command),
      );

      Get.snackbar(
        'Thành công',
        'Đã gửi lệnh $command',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể gửi lệnh: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void resetCounter() {
    totalScanned.value = 0;
    lastScannedCode.value = '';
    _scannedCodesTimestamp.clear(); // Xóa lịch sử quét

    Get.snackbar(
      'Đã reset',
      'Đã reset bộ đếm và lịch sử quét',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }

  void toggleCamera() {
    scannerController.switchCamera();
  }

  void toggleFlash() {
    scannerController.toggleTorch();
  }
}
