import 'package:get/get.dart';
import '../controllers/taodon_controller.dart';

class TaodonBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaodonController>(() => TaodonController());
  }
}
