import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/data/tms_automation_bridge.dart';

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Code to execute when notification is created
  }

  /// Use this method to detect when a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // Code to execute when notification is displayed
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Code to execute when notification is dismissed
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    final payload = receivedAction.payload;
    if (payload != null && payload.containsKey('code')) {
      final code = payload['code'] ?? '';
      final buttonKey = receivedAction.buttonKeyPressed;

      if (buttonKey == 'COPY_ONLY') {
        if (code.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: code));
          Get.snackbar('Đã sao chép', 'Mã BD10: $code',
              snackPosition: SnackPosition.BOTTOM);
        }
        return;
      }

      // Mặc định (nhấp vào thông báo hoặc nút BẮT ĐẦU TỰ ĐỘNG):
      // Kích hoạt chuỗi hành động tự động hóa TMS qua Accessibility Service
      await TmsAutomationBridge.startAutomation(
        code: code,
        targetApp: 'TMS',
      );
    }
  }
}
