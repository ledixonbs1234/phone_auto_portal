import 'package:get/get.dart';
import '../controllers/nhaphang_controller.dart';

class NhapHangBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NhapHangController>(() => NhapHangController());
  }
}
