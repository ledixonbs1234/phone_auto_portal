import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';

class NotificationController {
  static const MethodChannel _channel = MethodChannel('com.example.phone_auto_portal/volume');

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
      final code = payload['code'];
      if (code != null && code.isNotEmpty) {
        // Copy to clipboard
        await Clipboard.setData(ClipboardData(text: code));
        
        // Launch STM Max app
        try {
          await _channel.invokeMethod('launchApp', {'appName': 'STM Max'});
        } catch (e) {
          // Fallback or print log
          print("Error launching STM Max: $e");
        }
      }
    }
  }
}
