import 'package:get/get.dart';

import '../controllers/myview_controller.dart';

class MyviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyviewController>(
      () => MyviewController(),
    );
  }
}
