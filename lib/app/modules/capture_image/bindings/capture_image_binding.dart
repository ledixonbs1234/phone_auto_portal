import 'package:get/get.dart';
import '../controllers/capture_image_controller.dart';

class CaptureImageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CaptureImageController>(() => CaptureImageController());
  }
}
