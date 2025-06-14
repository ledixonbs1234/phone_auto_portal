import 'package:get/get.dart';

import '../../home/khach_hangs_model.dart';

class MyviewController extends GetxController {
  final khachHangs = <KhachHangs>[].obs;
  var lastSelectKH = "";
  final seKhachHangs = KhachHangs().obs;
}
