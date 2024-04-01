import 'package:get/get.dart';

import '../controllers/createnew_controller.dart';

class CreatenewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreatenewController>(
      () => CreatenewController(),
    );
  }
}
