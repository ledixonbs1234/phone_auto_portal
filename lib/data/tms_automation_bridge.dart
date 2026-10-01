import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class TmsAutomationBridge {
  static const MethodChannel _channel =
      MethodChannel('com.example.phone_auto_portal/tms_automation');
  static const MethodChannel _fallbackChannel =
      MethodChannel('com.example.phone_auto_portal/volume');

  /// Kiểm tra xem Accessibility Service đã được cấp quyền và đang chạy chưa
  static Future<bool> isAccessibilityEnabled() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi kiểm tra Accessibility qua channel chính: $e');
      }
      try {
        final bool? fallbackResult =
            await _fallbackChannel.invokeMethod<bool>('isAccessibilityEnabled');
        return fallbackResult ?? false;
      } catch (err) {
        if (kDebugMode) {
          print('Lỗi kiểm tra Accessibility qua fallback channel: $err');
        }
        return false;
      }
    }
  }

  /// Mở màn hình Cài đặt Trợ năng (Accessibility Settings) trên Android
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      try {
        await _fallbackChannel.invokeMethod('openAccessibilitySettings');
      } catch (err) {
        if (kDebugMode) {
          print('Lỗi mở Accessibility Settings: $err');
        }
      }
    }
  }

  /// Khởi chạy quy trình tự động hóa TMS với mã BD10
  static Future<bool> startAutomation({
    required String code,
    String targetApp = 'TMS',
  }) async {
    try {
      // 1. Sao chép mã vào Clipboard đề phòng
      if (code.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: code));
      }

      // 2. Kiểm tra quyền Accessibility Service
      final isEnabled = await isAccessibilityEnabled();
      if (!isEnabled) {
        Get.snackbar(
          'Yêu cầu cấp quyền Trợ năng',
          'Vui lòng bật dịch vụ "TMS Automation Service" trong Cài đặt để app có thể tự động thao tác trên TMS.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () => openAccessibilitySettings(),
            child: const Text(
              'CÀI ĐẶT',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        await openAccessibilitySettings();
        return false;
      }

      // 3. Gửi lệnh bắt đầu tự động hóa tới Android Service
      final bool? success = await _channel.invokeMethod<bool>('startTmsAutomation', {
        'code': code,
        'targetApp': targetApp,
      });

      if (success == true) {
        Get.snackbar(
          'TMS Automation',
          'Đang tự động mở và thực hiện các bước trên App TMS...',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return true;
      } else {
        // Nếu native trả về false (service chưa sẵn sàng), fallback mở app trực tiếp
        await launchApp(targetApp);
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi kích hoạt TMS Automation: $e');
      }
      try {
        final bool? fallbackSuccess =
            await _fallbackChannel.invokeMethod<bool>('startTmsAutomation', {
          'code': code,
          'targetApp': targetApp,
        });
        return fallbackSuccess ?? false;
      } catch (err) {
        // Fallback cuối cùng: mở app TMS
        await launchApp(targetApp);
        return false;
      }
    }
  }

  /// Dừng quy trình tự động hóa
  static Future<void> stopAutomation() async {
    try {
      await _channel.invokeMethod('stopAutomation');
    } catch (e) {
      try {
        await _fallbackChannel.invokeMethod('stopAutomation');
      } catch (_) {}
    }
  }

  /// Mở ứng dụng theo tên/tiền tố
  static Future<bool> launchApp(String appName) async {
    try {
      final bool? res = await _channel.invokeMethod<bool>('launchApp', {'appName': appName});
      return res ?? false;
    } catch (e) {
      try {
        final bool? res =
            await _fallbackChannel.invokeMethod<bool>('launchApp', {'appName': appName});
        return res ?? false;
      } catch (err) {
        if (kDebugMode) {
          print('Lỗi mở app $appName: $err');
        }
        return false;
      }
    }
  }
}
