import 'package:get/get.dart';
import '../controllers/danhsachbd_controller.dart';

class DanhSachBDBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DanhSachBDController>(
      () => DanhSachBDController(),
    );
  }
}
