import 'package:get/get.dart';
import '../controllers/direction_scanning_controller.dart';

class DirectionScanningBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DirectionScanningController>(
      () => DirectionScanningController(),
    );
  }
}
