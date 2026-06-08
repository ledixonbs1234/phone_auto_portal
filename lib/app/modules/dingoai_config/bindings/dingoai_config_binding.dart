import 'package:get/get.dart';
import '../controllers/dingoai_config_controller.dart';

class DingoaiConfigBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DingoaiConfigController>(
      () => DingoaiConfigController(),
    );
  }
}
