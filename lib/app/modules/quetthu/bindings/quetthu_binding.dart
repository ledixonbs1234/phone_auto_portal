import 'package:get/get.dart';
import '../controllers/quetthu_controller.dart';

class QuetThuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QuetThuController>(
      () => QuetThuController(),
    );
  }
}
