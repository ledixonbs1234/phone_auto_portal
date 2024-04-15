import 'package:get/get.dart';

import '../controllers/print_page_controller.dart';

class PrintPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrintPageController>(
      () => PrintPageController(),
    );
  }
}
