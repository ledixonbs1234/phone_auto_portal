import 'package:get/get.dart';
import '../controllers/dingoai_rt_controller.dart';

class DiNgoaiRtBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DiNgoaiRtController>(
      () => DiNgoaiRtController(),
    );
  }
}
