import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/khach_hangs_model.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';

import '../../home/messageReceiveModel.dart';

class CreatenewController extends GetxController {
  final khachHang = KhachHangs().obs;
  final buuGuis = <BuuGuis>[].obs;
  final isChangeKL = false.obs;
  late FocusNode focusKL;
  final stateText = "".obs;
  final iBuuGui = (-1).obs;

  TextEditingController textHintController = TextEditingController();

  TextEditingController textMHController = TextEditingController();

  TextEditingController textKLController = TextEditingController();

  late FocusNode focusHint;
  final count = 0.obs;

  @override
  void onReady() {
    super.onReady();
    focusHint = FocusNode();
    focusKL = FocusNode();
  }

  void onChangeHintMH(String hintNumber) async {
    //thuc hien tim kiem ma buu gui tu sau sang truoc

    int count = 0;

    String currentMaHieu = "";

    for (var buugui in khachHang.value.buuGuis!) {
      if (buugui.maBuuGui!.lastIndexOf(hintNumber) != -1) {
        currentMaHieu = buugui.maBuuGui!;
        count++;
        if (count > 1) break;
      }
    }

    if (count == 1) {
      //kiem tra currentMaHieu có phải là bưu gửi đang tồn tại trong buuguis không
      if (buuGuis
          .where((element) => element.maBuuGui == currentMaHieu)
          .isNotEmpty) {
        textHintController.text = "";
        return;
      }
      textMHController.text = currentMaHieu.toUpperCase();
      if (isChangeKL.value) {
        focusKL.requestFocus();

        sleep(const Duration(milliseconds: 300));
      } else {
        addKhachHang();
      }
    }
  }

  void addKhachHang() {
    if (isChangeKL.value) {
      if (textMHController.text.isNotEmpty &&
          textKLController.text.isNotEmpty) {
        buuGuis.add(BuuGuis(
            index: buuGuis.length + 1,
            maBuuGui: textMHController.text,
            khoiLuong: int.parse(textKLController.text)));
      }
    } else {
      if (textMHController.text.isNotEmpty) {
        buuGuis.add(BuuGuis(
            index: buuGuis.length + 1,
            maBuuGui: textMHController.text,
            khoiLuong: khachHang.value.buuGuis!
                .firstWhere(
                    (element) => textMHController.text == element.maBuuGui)
                .khoiLuong));
      }
    }
    buuGuis.sort((a, b) => b.index!.compareTo(a.index!));
    textMHController.text = "";
    textKLController.text = "";
    textHintController.text = "";
    update();
  }

  addKL(int kl) {
    textKLController.text = kl.toString();
    addKhachHang();
    focusHint.requestFocus();
  }

  deleteSelected() {
    if (iBuuGui.value != -1) {
      buuGuis.removeAt(iBuuGui.value);
    }
    update();
  }

  deleteAll() {
    buuGuis.clear();
    update();
  }

  void setUp(KhachHangs kh) {
    if (kh.tenKH != khachHang.value.tenKH) {
      buuGuis.clear();
      iBuuGui.value = -1;
      khachHang.value = kh;
    }
    // isCheckChapNhan.value = false;
    // setDefaultInfo();
  }

  int getSLBuuGui() {
    //đếm số lượng buugui trong buuguis ở trangthai = "Đang đi thu gom"

    int count = 0;

    for (var buugui in khachHang.value.buuGuis!) {
      if (buugui.trangThai == "Đang đi thu gom" ||
          buugui.trangThai == "Nhận hàng thành công" ||
          buugui.trangThai == "Đã phân hướng") {
        count++;
      }
    }
    count -= buuGuis.length;
    return count;
  }

  sendToPC() {
    printInfo(info: "Send to portal");
    if (iBuuGui.value == -1) {
      return;
    }
    if (buuGuis.isEmpty) return;
    stateText.value = "Đang gửi thông tin";

    FirebaseManager().setListBG(buuGuis.value);

    FirebaseManager().addMessage(MessageReceiveModel(
        "sendtoportal",
        '{'
                '"maKH"'
                ': "${khachHang.value.maKH}", '
                '"maBG"'
                ':"${buuGuis[iBuuGui.value].maBuuGui}"}'
            .toString()));
  }

  void onListenNotification(MessageReceiveModel message) {
    switch (message.Lenh) {
      case "checkstatemh":
        var splitText = message.DoiTuong.split("|");
        var bg = buuGuis
            .firstWhereOrNull((element) => element.maBuuGui == splitText[0]);
        bg?.trangThaiRequest = "Xong";
        bg?.money = splitText[1];

        update();

        break;
      case "showdetailmessage":
        stateText.value = message.DoiTuong;
        break;
      default:
    }
  }
}
