import 'dart:async';
import 'dart:ui';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart'
    as android;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:phone_auto_portal/app/modules/createnew/controllers/createnew_controller.dart';
import 'package:phone_auto_portal/app/modules/detail/controllers/detail_controller.dart';
import 'package:phone_auto_portal/app/modules/edit_page/controllers/edit_page_controller.dart';
import 'package:phone_auto_portal/app/modules/myview/controllers/myview_controller.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/controllers/portalinfo_controller.dart';
import 'package:phone_auto_portal/app/modules/printPage/controllers/print_page_controller.dart';
import 'package:phone_auto_portal/app/routes/app_pages.dart';
import 'package:phone_auto_portal/data/UpdateService.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';
import 'package:phone_auto_portal/firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter/services.dart';

import 'app/modules/home/controllers/home_controller.dart';
import 'app/modules/home/messageReceiveModel.dart';

// --- HÀM CHO SERVICE NỀN ---
String lastTimeStamp = "";
String lastCalledNumber = '';
// String lastCalledNumber = '';
// Hàm này sẽ được gọi khi service bắt đầu
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Báo cho Dart Engine biết đây là một entry point cho background
  DartPluginRegistrant.ensureInitialized();

  // QUAN TRỌNG: Khởi tạo lại Firebase trong service isolate
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("Background Service đã bắt đầu.");
  // Thêm GetStorage nếu bạn cần đọc key từ đó trong service
  await GetStorage.init();
  service.on('stopService').listen((event) {
    print("Nhận được lệnh dừng service...");
    service.stopSelf();
  });
  // Lắng nghe sự kiện từ Realtime Database
  // var keyData = FirebaseManager().readKey();
  var keyData = 'maytest';
  keyData = FirebaseManager().readKey();
  print("Key data: $keyData");
  var dbRef =
      FirebaseDatabase.instance.ref("PORTAL/CHILD/${keyData}/message/tophone");
  dbRef.onValue.listen((DatabaseEvent event) {
    if (event.snapshot.value == null) return;
    Map<dynamic, dynamic> value = event.snapshot.value as Map<dynamic, dynamic>;

    MessageReceiveModel message = MessageReceiveModel.fromJson(value);
    if (lastTimeStamp == "") {
      lastTimeStamp = message.TimeStamp;
      return;
    }
    if (message.TimeStamp != lastTimeStamp) {
      lastTimeStamp = message.TimeStamp;
      if (message.Lenh == "phonecall") {
        final phoneNumber = message.DoiTuong;
        //xoa dấu . hoặc dấu cách trong số điện thoại
        final cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[.\s]'), '');
        if (cleanedPhoneNumber != lastCalledNumber) {
          lastCalledNumber = cleanedPhoneNumber;
          print("New call request received for: $cleanedPhoneNumber");
          _openDialer(cleanedPhoneNumber);

          // (Tùy chọn) Xóa yêu cầu sau khi đã xử lý
          // callRef.remove();
        }
      }
      // final data = event.snapshot.value as Map<dynamic, dynamic>?;
      // if (data != null && data.containsKey('phoneNumber')) {
      //   final phoneNumber = data['phoneNumber'] as String;
      //   print('Service nền nhận được số điện thoại: $phoneNumber');
      //   _openDialer(phoneNumber);

      // (Tùy chọn) Xóa yêu cầu sau khi đã xử lý để không gọi lại
      // event.snapshot.ref.remove();
    }
  });

  // Bạn có thể giữ service "sống" bằng một timer nếu cần
  Timer.periodic(const Duration(seconds: 60), (timer) {
    print("Background service đang chạy...");
  });
}

// Hàm helper để mở giao diện gọi điện (giống như trước)
// Hàm helper để mở giao diện gọi điện
Future<void> _openDialer(String phoneNumber) async {
  // Chỉ thực thi trên Android
  final AndroidIntent intent = AndroidIntent(
    action: 'android.intent.action.DIAL', // ACTION_DIAL
    data: 'tel:$phoneNumber',
    // ĐÂY LÀ CHÌA KHÓA GIẢI QUYẾT VẤN ĐỀ
    flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
  );
  try {
    final AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.DIAL', // ACTION_DIAL
      data: 'tel:$phoneNumber',
      // ĐÂY LÀ CHÌA KHÓA GIẢI QUYẾT VẤN ĐỀ
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    try {
      print("Launching intent to dial: $phoneNumber");
      await intent.launch();
      print("Intent to dial has been launched.");
    } catch (e) {
      print("Failed to launch intent: $e");
    }
    await intent.launch();
    print("Intent to dial has been launched.");
  } catch (e) {
    print("Failed to launch intent: $e");
  }
}

// // Hàm khởi tạo service
Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      foregroundServiceTypes: [AndroidForegroundType.connectedDevice],
      isForegroundMode: true, // Bắt buộc để chạy lâu dài
      autoStart: false, // Tự khởi động service khi ứng dụng mở
      notificationChannelId: 'my_app_service', // ID của kênh thông báo
      initialNotificationTitle: 'Ứng dụng đang chạy nền',
      initialNotificationContent: 'Đang lắng nghe yêu cầu gọi điện.',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      // iOS không hỗ trợ chế độ này một cách đáng tin cậy.
      // Chỉ nên dùng autoStart và onForeground/onBackground cho các tác vụ ngắn.
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null,
      [
        NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'test',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white)
      ],
      // Channel groups are only visual and are not required

      debug: true);
  await GetStorage.init();
  // AwesomeNotifications().initialize(
  //     // set the icon to null if you want to use the default app icon
  //     null,
  //     // [
  //     //   NotificationChannel(
  //     //       channelGroupKey: 'basic_channel_group',
  //     //       channelKey: 'test',
  //     //       channelName: 'Basic notifications',
  //     //       channelDescription: 'Notification channel for basic tests',
  //     //       defaultColor: const Color(0xFF9D50DD),
  //     //       ledColor: Colors.white)
  //     // ],
  //     // Channel groups are only visual and are not required

  //     debug: true);
  // await GetStorage.init();
  setPathUrlStrategy();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseManager().setUp();
  // FirebaseDatabase.instance.setLoggingEnabled(true);
  await initializeService();

  Get.put(HomeController());
  Get.put(PortalinfoController());
  Get.put(CreatenewController());
  Get.put(DetailController());
  Get.put(PrintPageController());
  Get.put(EditPageController());
  Get.put(MyviewController());
  // Get.put(DingoaiController());
  // Get.put(WebController());
  // Get.put(SavedMHController());
  // Get.put(AutoBdController());
  Get.put(UpdateService());

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Application",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    ),
  );
}
