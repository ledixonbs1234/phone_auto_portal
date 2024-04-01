import 'package:get/get.dart';

import '../controllers/portalinfo_controller.dart';

class PortalinfoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PortalinfoController>(
      () => PortalinfoController(),
    );
  }
}
