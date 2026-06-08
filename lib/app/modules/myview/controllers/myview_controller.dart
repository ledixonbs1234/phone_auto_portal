import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/controllers/home_controller.dart';

import '../../../../data/firebaseManager.dart';
import '../../createnew/controllers/createnew_controller.dart';
import '../../detail/controllers/detail_controller.dart';
import '../../home/khach_hangs_model.dart';
import '../../home/messageReceiveModel.dart';

class MyviewController extends GetxController {
  final khachHangs = <KhachHangs>[].obs;
  var lastSelectKH = "";
  var textController = TextEditingController();
  final seKhachHangs = KhachHangs().obs;
  final stateText = "".obs;
  final timeUpdate = "".obs;
  @override
  void onReady() {
    super.onReady();
    khachHangs.add(KhachHangs(
      maKH: "C015304312",
      tenKH: "Nhu Trinh",
      tenNguoiGui: "Nhu Trinh",
      countState: CountState(
        countChapNhan: 0,
        countDangGom: 0,
        countNhanHang: 0,
        countPhanHuong: 0,
      ),
    ));
    khachHangs.add(KhachHangs(
      maKH: "C017709920",
      tenKH: "Mắm Hồ Duy",
      tenNguoiGui: "Mắm Hồ Duy",
      countState: CountState(
        countChapNhan: 0,
        countDangGom: 0,
        countNhanHang: 0,
        countPhanHuong: 0,
      ),
    ));
  }

  void getMyPostData() async {
    var home = Get.find<HomeController>();
    String day = "-2";
    if (home.dayLastController.text != "2" &&
        home.dayLastController.text.isNotEmpty) {
      day = (int.parse(home.dayLastController.text) * (-1)).toString();
    }

    FirebaseManager().addMessage(MessageReceiveModel(
        "getmypostdata",
        const JsonEncoder().convert(
          {"day": day},
        )));

    FirebaseManager().showSnackBar("Đang lấy dữ liệu");
    stateText.value = "Đang lấy dữ liệu";
  }

  Future<void> onListenNotification(MessageReceiveModel message) async {
    switch (message.Lenh) {
      case "message":
        stateText.value = message.DoiTuong;
        break;
      case "":
      default:
    }
  }

  updateKhachHang() async {
    var temps = await FirebaseManager().getKhachHangsVnPost();

    if (temps.isNotEmpty) {
      // 1. Chuyển list hiện tại thành Map để tra cứu/cập nhật nhanh (O(1))
      final khachHangMap = {for (var kh in khachHangs) kh.maKH: kh};

      // 2. Lặp qua dữ liệu mới và cập nhật Map.
      for (final newKh in temps) {
        khachHangMap[newKh.maKH] = newKh;
      }

      // 3. Chuyển Map đã cập nhật trở lại thành List quan sát
      khachHangs.assignAll(khachHangMap.values.toList());

      // 4. Selected lại khách hàng
      KhachHangs? currentKH;
      if (lastSelectKH.isNotEmpty) {
        currentKH = khachHangs
            .firstWhereOrNull((element) => element.maKH == lastSelectKH);
      }

      if (currentKH != null) {
        seKhachHangs.value = currentKH;
      } else {
        seKhachHangs.value = khachHangs[0];
      }
      FirebaseManager().showSnackBar('Cập nhật dữ liệu thành công');

      stateText.value = "Cập nhật dữ liệu thành công";
    }
  }

  void goToDetail() {
    var detail = Get.find<DetailController>();
    //nếu lastSelectedMaKH khác null thì kiểm tra có trùng với Ma KH của selectedKH không
    var home = Get.find<HomeController>();
    var selectedUser = home.selectedUser.value;

    detail.setUp(
      seKhachHangs.value,
      selectedUser!.username,
      selectedUser.password,
    );

    Get.toNamed("/detail");
  }

  void goToCreateNew() {
    var createNew = Get.find<CreatenewController>();

    var home = Get.find<HomeController>();
    var selectedUser = home.selectedUser.value;
    if (seKhachHangs.value.maKH == null) {
      FirebaseManager().showSnackBar("Chưa chọn khách hàng");
      return;
    }
    createNew.setUp(
        seKhachHangs.value, selectedUser!.username, selectedUser.password);

    Get.toNamed("/createnew");
  }

  void findKhachHang(String value) {
    var home = Get.find<HomeController>();
    String day = "-2";
    if (home.dayLastController.text != "2" &&
        home.dayLastController.text.isNotEmpty) {
      day = (int.parse(home.dayLastController.text) * (-1)).toString();
    }
    FirebaseManager().addMessage(MessageReceiveModel(
        "getmypostdata",
        const JsonEncoder().convert(
          {"day": day},
        )));

    FirebaseManager().showSnackBar("Đang lấy dữ liệu");
    stateText.value = "Đang lấy dữ liệu";
  }
}
