import 'package:get/get.dart';

import '../controllers/edit_page_controller.dart';

class EditPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditPageController>(
      () => EditPageController(),
    );
  }
}
