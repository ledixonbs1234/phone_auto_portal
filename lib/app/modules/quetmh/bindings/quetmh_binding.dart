import 'package:get/get.dart';

import '../controllers/quetmh_controller.dart';

class QuetmhBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QuetmhController>(
      () => QuetmhController(),
    );
  }
}
