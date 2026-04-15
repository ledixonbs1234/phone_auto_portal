import 'package:get/get.dart';

import '../controllers/khoi_tao_moi_controller.dart';

class KhoiTaoMoiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<KhoiTaoMoiController>(
      () => KhoiTaoMoiController(),
    );
  }
}
