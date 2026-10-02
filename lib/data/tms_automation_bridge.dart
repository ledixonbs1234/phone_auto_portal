import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class TmsAutomationStepItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const TmsAutomationStepItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.color = Colors.blue,
  });
}

class TmsAutomationBridge {
  static const MethodChannel _channel =
      MethodChannel('com.example.phone_auto_portal/tms_automation');
  static const MethodChannel _fallbackChannel =
      MethodChannel('com.example.phone_auto_portal/volume');

  /// Danh sách 16 cảnh/bước tự động hóa TMS để người dùng linh hoạt chọn điểm bắt đầu kiểm thử
  static const List<TmsAutomationStepItem> supportedSteps = [
    TmsAutomationStepItem(
      id: 'STEP_1_ACCEPT_ORDER',
      title: '1. Nhận Lệnh & Xác nhận (Tab Lệnh mới)',
      description: 'Bấm [NHẬN LỆNH] -> Bấm popup [Đồng ý]',
      icon: Icons.assignment_turned_in_rounded,
      color: Color(0xFF0284C7),
    ),
    TmsAutomationStepItem(
      id: 'STEP_2_VIEW_DETAIL',
      title: '2. Mở Chi Tiết Chuyến (Tab Đã nhận)',
      description: 'Màn hình Đã nhận lệnh -> Bấm nút [CHI TIẾT]',
      icon: Icons.pageview_rounded,
      color: Color(0xFF0D9488),
    ),
    TmsAutomationStepItem(
      id: 'STEP_3_START_TRIP',
      title: '3. Bắt Đầu Chuyến Đi',
      description: 'Chi tiết chuyến -> Bấm nút cam [BẮT ĐẦU]',
      icon: Icons.play_arrow_rounded,
      color: Color(0xFFEA580C),
    ),
    TmsAutomationStepItem(
      id: 'STEP_3B_CLICK_POINT_593200',
      title: '3B. Nhấn nút [593200]',
      description: 'Màn hình Lộ trình -> Bấm chọn điểm bưu cục [593200]',
      icon: Icons.touch_app_rounded,
      color: Color(0xFFF59E0B),
    ),
    TmsAutomationStepItem(
      id: 'STEP_4_SELECT_FIRST_POINT',
      title: '4. Chọn Điểm 1 trong Lộ Trình',
      description: 'Màn hình Lộ trình -> Chọn điểm bưu cục thứ 1',
      icon: Icons.place_rounded,
      color: Color(0xFF4F46E5),
    ),
    TmsAutomationStepItem(
      id: 'STEP_5_CLICK_VAO_POINT_1',
      title: '5. Điểm 1: Bấm [VÀO]',
      description: 'Xác nhận đến và vào điểm thứ 1',
      icon: Icons.login_rounded,
      color: Color(0xFF16A34A),
    ),
    TmsAutomationStepItem(
      id: 'STEP_6_CLICK_SCAN_BD10_1',
      title: '6. Điểm 1: Bấm [SCAN BD10]',
      description: 'Mở popup quét mã BD10 điểm 1',
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFF06B6D4),
    ),
    TmsAutomationStepItem(
      id: 'STEP_7_INPUT_BD10_CODE',
      title: '7. Điểm 1: Nhập Mã BD10 & Bấm [Thêm]',
      description: 'Điền mã BD10 vào ô và bấm nút [Thêm]',
      icon: Icons.edit_rounded,
      color: Color(0xFFD97706),
    ),
    TmsAutomationStepItem(
      id: 'STEP_8_CONFIRM_BD10_1',
      title: '8. Điểm 1: Bấm [Xác nhận] modal BD10',
      description: 'Bấm nút [Xác nhận] lưu danh sách BD10 điểm 1',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF16A34A),
    ),
    TmsAutomationStepItem(
      id: 'STEP_9_CLICK_RA_POINT_1',
      title: '9. Điểm 1: Bấm [RA] xuất phát',
      description: 'Rời điểm 1 để di chuyển sang điểm tiếp theo',
      icon: Icons.logout_rounded,
      color: Color(0xFFE11D48),
    ),
    TmsAutomationStepItem(
      id: 'STEP_10_SELECT_SECOND_POINT',
      title: '10. Chọn Điểm 2 trong Lộ Trình',
      description: 'Màn hình Lộ trình -> Chọn điểm bưu cục giao/trả 2',
      icon: Icons.pin_drop_rounded,
      color: Color(0xFF4F46E5),
    ),
    TmsAutomationStepItem(
      id: 'STEP_11_CLICK_VAO_POINT_2',
      title: '11. Điểm 2: Bấm [VÀO]',
      description: 'Xác nhận đến điểm thứ 2',
      icon: Icons.login_rounded,
      color: Color(0xFF16A34A),
    ),
    TmsAutomationStepItem(
      id: 'STEP_12_CLICK_SCAN_BD10_2',
      title: '12. Điểm 2: Bấm [SCAN BD10]',
      description: 'Mở màn hình quét BD10 tại điểm 2',
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFF06B6D4),
    ),
    TmsAutomationStepItem(
      id: 'STEP_13_CLICK_DS_BD10_LEN',
      title: '13. Điểm 2: Bấm [DS BD10 lên]',
      description: 'Bấm nút xanh lá [DS BD10 lên] để nạp danh sách',
      icon: Icons.list_alt_rounded,
      color: Color(0xFF0D9488),
    ),
    TmsAutomationStepItem(
      id: 'STEP_14_SELECT_ALL_AND_ADD',
      title: '14. Điểm 2: Chọn Tất Cả & Bấm [Thêm]',
      description: 'Chọn toàn bộ mã BD10 và bấm nút [Thêm]',
      icon: Icons.select_all_rounded,
      color: Color(0xFF9333EA),
    ),
    TmsAutomationStepItem(
      id: 'STEP_15_CONFIRM_BD10_2',
      title: '15. Điểm 2: Bấm [Xác nhận] modal',
      description: 'Bấm nút [Xác nhận] hoàn tất trả hàng điểm 2',
      icon: Icons.check_circle_outline_rounded,
      color: Color(0xFF16A34A),
    ),
    TmsAutomationStepItem(
      id: 'STEP_16_CLICK_RA_POINT_2',
      title: '16. Điểm 2: Bấm [RA] (Kết Thúc Chuyến)',
      description: 'Bấm [RA] tại điểm cuối để hoàn tất chuyến đi',
      icon: Icons.flag_rounded,
      color: Color(0xFFDC2626),
    ),
  ];

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

  /// Kiểm tra xem tiến trình tự động hóa có đang chạy không
  static Future<bool> isAutomationRunning() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isAutomationRunning');
      return result ?? false;
    } catch (e) {
      return false;
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

  /// Khởi chạy quy trình tự động hóa TMS với mã BD10 và bước bắt đầu tuỳ chọn
  static Future<bool> startAutomation({
    required String code,
    String targetApp = 'TMS',
    String startStep = 'STEP_1_ACCEPT_ORDER',
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
        'startStep': startStep,
      });

      final stepItem = supportedSteps.firstWhere(
        (s) => s.id == startStep,
        orElse: () => supportedSteps.first,
      );

      if (success == true) {
        Get.snackbar(
          'TMS Automation',
          'Bắt đầu tự động từ: ${stepItem.title}',
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
          'startStep': startStep,
        });
        return fallbackSuccess ?? false;
      } catch (err) {
        // Fallback cuối cùng: mở app TMS
        await launchApp(targetApp);
        return false;
      }
    }
  }

  /// Dừng quy trình tự động hóa thủ công
  static Future<void> stopAutomation() async {
    try {
      await _channel.invokeMethod('stopTmsAutomation');
      Get.snackbar(
        'Đã Dừng Tự Động',
        'Đã dừng chuỗi thao tác tự động hóa TMS.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      try {
        await _fallbackChannel.invokeMethod('stopTmsAutomation');
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
