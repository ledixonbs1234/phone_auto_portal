import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:phone_auto_portal/app/modules/createnew/controllers/createnew_controller.dart';
import 'package:phone_auto_portal/app/modules/detail/controllers/detail_controller.dart';
import 'package:phone_auto_portal/app/modules/edit_page/controllers/edit_page_controller.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/controllers/portalinfo_controller.dart';
import 'package:phone_auto_portal/app/modules/printPage/controllers/print_page_controller.dart';
import 'package:phone_auto_portal/app/routes/app_pages.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';
import 'package:phone_auto_portal/firebase_options.dart';
import 'package:url_strategy/url_strategy.dart';

import 'app/modules/home/controllers/home_controller.dart';

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

  Get.put(HomeController());
  Get.put(PortalinfoController());
  Get.put(CreatenewController());
  Get.put(DetailController());
  Get.put(PrintPageController());
  Get.put(EditPageController());
  // Get.put(DingoaiController());
  // Get.put(WebController());
  // Get.put(SavedMHController());
  // Get.put(AutoBdController());

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Application",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    ),
  );
}
