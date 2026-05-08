import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:phone_auto_portal/app/modules/createnew/controllers/createnew_controller.dart';
import 'package:phone_auto_portal/app/modules/detail/controllers/detail_controller.dart';
import 'package:phone_auto_portal/app/modules/edit_page/controllers/edit_page_controller.dart';
import 'package:phone_auto_portal/app/modules/myview/controllers/myview_controller.dart';
import 'package:phone_auto_portal/app/modules/nhaphang/controllers/nhaphang_controller.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/controllers/portalinfo_controller.dart';
import 'package:phone_auto_portal/app/modules/printPage/controllers/print_page_controller.dart';
import 'package:phone_auto_portal/app/modules/taodon/controllers/taodon_controller.dart';
import 'package:phone_auto_portal/app/routes/app_pages.dart';
import 'package:phone_auto_portal/data/UpdateService.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';
import 'package:phone_auto_portal/firebase_options.dart';
import 'package:url_strategy/url_strategy.dart';

import 'app/modules/home/controllers/home_controller.dart';
import 'app/modules/khoi_tao_moi/controllers/khoi_tao_moi_controller.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/theme_controller.dart';

// --- HÀM CHO SERVICE NỀN ---
String lastTimeStamp = "";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cameras early to ensure plugin is ready
  try {
    await availableCameras();
  } catch (e) {
    // Camera initialization warning: $e
  }

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

  // Theme controller must be registered first
  final themeController = Get.put(ThemeController());

  Get.put(HomeController());
  Get.put(PortalinfoController());
  Get.put(CreatenewController());
  Get.put(DetailController());
  Get.put(PrintPageController());
  Get.put(EditPageController());
  Get.put(MyviewController());
  Get.put(KhoiTaoMoiController());
  Get.put(TaodonController());
  Get.put(NhapHangController());
  // Get.put(DingoaiController());
  // Get.put(WebController());
  // Get.put(SavedMHController());
  // Get.put(AutoBdController());
  Get.put(UpdateService());

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Application",
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    ),
  );
}
