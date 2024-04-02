import 'dart:ffi';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:get_storage/get_storage.dart';

import 'package:phone_auto_portal/app/modules/createnew/controllers/createnew_controller.dart';

import 'package:phone_auto_portal/app/modules/detail/controllers/detail_controller.dart';

import 'package:phone_auto_portal/app/modules/home/hopdong_model.dart';

import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';

import 'package:phone_auto_portal/data/firebaseManager.dart';

import '../../portalinfo/controllers/portalinfo_controller.dart';

import '../khach_hangs_model.dart';

class HomeController extends GetxController {
  //TODO: Implement HomeController

  final count = 0.obs;

  final timeUpdate = "".obs;

  final khachHangs = <KhachHangs>[].obs;

  final seKhachHangs = KhachHangs().obs;

  final textMH = "".obs;

  final isHaveHopDong = false.obs;

  final isEditHopDong = false.obs;

  final stateText = "".obs;

  var textMHController = TextEditingController();

  var addressController = TextEditingController();

  var numberHopDongController = TextEditingController();

  var maKHController = TextEditingController();

  var keyController = TextEditingController();

  var capcharController = TextEditingController();

  final imageBytes = "".obs;

  final selectedMayChu = "maychu".obs;

  final maychus = <String>["maychu", "mayphu", "mayphusan", "maytest"].obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    // khachHangs.clear();

    keyController.text = GetStorage().read("key") ?? "maychu";

    // var temps = await FirebaseManager().getKhachHangs();

    numberHopDongController.text = "0";

    // if (temps.isNotEmpty) {

    //   seKhachHangs.value = temps[0];

    //   khachHangs.addAll(temps);

    // }

    super.onReady();
  }

  void increment() => count.value++;

  void getPortalData() async {
    imageBytes.value = "";

    FirebaseManager().showSnackBar("Đang lấy dữ liệu");

    stateText.value = "Đang lấy dữ liệu";

    FirebaseManager().addMessage(MessageReceiveModel("getpns", ""));
  }

  updateKhachHang() async {
    khachHangs.clear();

    var temps = await FirebaseManager().getKhachHangs();

    if (temps.isNotEmpty) {
      seKhachHangs.value = temps[0];

      khachHangs.addAll(temps);

      FirebaseManager().showSnackBar('Cập nhật dữ liệu thành công');

      stateText.value = "Cập nhật dữ liệu thành công";
    }
  }

  Future<void> onListenNotification(MessageReceiveModel message) async {
    switch (message.Lenh) {
      case "message":
        stateText.value = message.DoiTuong;

        break;

      case "showcapchar":
        imageBytes.value = message.DoiTuong.split(',')[1];

        stateText.value = "Nhập capchar";

        break;

      case "checkhopdong":
        if (message.DoiTuong == "ok") {
          FirebaseManager().showSnackBar("Chuẩn bị hợp đồng thành công");

          stateText.value = "Chuẩn bị hợp đồng thành công";
        } else {
          stateText.value = message.DoiTuong;
        }

        break;

      default:
    }
  }

  Future<void> findKhachHangsByMH(String value) async {
    int countFind = 0;

    KhachHangs? khachHangFinded;

    for (var khachHang in khachHangs) {
      var finded = khachHang.buuGuis!.firstWhereOrNull(
          (element) => element.maBuuGui?.indexOf(value) != -1);

      if (finded != null) {
        countFind++;

        khachHangFinded = khachHang;

        if (countFind > 1) return;
      }
    }

    if (khachHangFinded != null) {
      seKhachHangs.value = khachHangFinded;

      stateText.value = "Tìm thấy ${khachHangFinded.tenKH}";

      //pause 2 sencond

      // sleep(const Duration(milliseconds: 1000));

      textMHController.text = "";

      //unfocus textfield

      FocusScope.of(Get.context!).unfocus();
    }
  }

  void goToDetail() {
    var detail = Get.find<DetailController>();

    detail.setUp(seKhachHangs.value);

    Get.toNamed("/detail");
  }

  void goToCreateNew() {
    var detail = Get.find<CreatenewController>();

    detail.setUp(seKhachHangs.value);

    Get.toNamed("/createnew");
  }

  void editHopDong() {
    isEditHopDong.value = true;
  }

  void saveHopDong() {
    isEditHopDong.value = false;

    FirebaseManager().addHopDong(
        seKhachHangs.value,
        HopDong(
            address: addressController.text,
            maKH: maKHController.text,
            isChooseHopDong: isHaveHopDong.value,
            sTTHopDong: int.parse(numberHopDongController.text)));
  }

  Future<void> checkHopDong(KhachHangs value) async {
    //get hopdong from firebase

    var hopDong = await FirebaseManager().getHopDong(value.maKH!);

    isHaveHopDong.value = hopDong.isChooseHopDong!;

    addressController.text = hopDong.address!;

    numberHopDongController.text = hopDong.sTTHopDong.toString();

    maKHController.text = hopDong.maKH!;
  }

  khoiTaoPortal() {
    stateText.value = "Đang khởi tạo";

    FirebaseManager().addMessage(MessageReceiveModel(
        "khoitao",
        '{'
            '"maKH"'
            ': "${seKhachHangs.value.maKH}"}'));
  }

  void goToOption() {
    Get.toNamed("/options");
  }

  void saveKey(String e) {
    GetStorage().write("key", e);

    FirebaseManager().disposeFirebase();

    FirebaseManager().setUp();
  }

  Future<void> loginPNS() async {
    // thực hiện send capchar to firebase

    imageBytes.value = "";

    FirebaseManager()
        .addMessage(MessageReceiveModel("loginpns", capcharController.text));

    stateText.value = "Đang đăng nhập";

    //waiting 2s

    await Future.delayed(const Duration(seconds: 2));

    getPortalData();
  }

  void gotoPortalInfo() {
    Get.toNamed("/portalinfo");

    var portalInfo = Get.find<PortalinfoController>();

    portalInfo.refreshPortal();
  }
}
