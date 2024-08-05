import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/khach_hangs_model.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/dingoaicodes_model.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';

import '../../home/messageReceiveModel.dart';

class CreatenewController extends GetxController {
  final khachHang = KhachHangs().obs;
  final buuGuis = <BuuGuis>[].obs;
  final isChangeKL = false.obs;
  final isDo = false.obs;
  late FocusNode focusKL = FocusNode();
  late FocusNode focusK1 = FocusNode();
  late FocusNode focusK2 = FocusNode();
  late FocusNode focusK3 = FocusNode();
  final stateText = "".obs;
  final listKichThuoc = <String>["", "", ""].obs;
  final iBuuGui = (-1).obs;
  final susggestMHs = <String>[].obs;
  final opacityLevel = 1.0.obs;
  final countBuuGuiConLai = 0.obs;

  TextEditingController textHintController = TextEditingController();
  TextEditingController k1 = TextEditingController();
  TextEditingController k2 = TextEditingController();
  TextEditingController k3 = TextEditingController();

  TextEditingController textMHController = TextEditingController();

  TextEditingController textKLController = TextEditingController();

  late FocusNode focusHint;
  final count = 0.obs;

  @override
  void onReady() {
    super.onReady();
    focusHint = FocusNode();
    focusKL = FocusNode();
    focusK1 = FocusNode();
    focusK2 = FocusNode();
    focusK3 = FocusNode();

    focusHint.addListener(() {
      if (focusHint.hasFocus) {
        k1.text = "";
        k2.text = "";
        k3.text = "";
      }
    });
  }

  void onFindedMH(String buuGuiTemp) async {
    //thuc hien tim kiem ma buu gui tu sau sang truoc
    //kiem tra currentMaHieu có phải là bưu gửi đang tồn tại trong buuguis không
    textMHController.text = buuGuiTemp.toUpperCase();
    textHintController.text = "";
    if (isChangeKL.value) {
      focusKL.requestFocus();

      sleep(const Duration(milliseconds: 300));
    } else if (isDo.value) {
      focusK1.requestFocus();
    } else {
      addKhachHang();
      focusHint.requestFocus();
      //show keyboard
    }
    update();
  }

  void addKhachHang() {
    susggestMHs.remove(textMHController.text);
    var bgTemp =
        BuuGuis(index: buuGuis.length + 1, maBuuGui: textMHController.text);
    if (textMHController.text.isNotEmpty) {
      if (isChangeKL.value) {
        if (textKLController.text.isNotEmpty) {
          bgTemp.khoiLuong = int.parse(textKLController.text);
        }
      } else {
        bgTemp.khoiLuong = khachHang.value.buuGuis!
            .firstWhere((element) => textMHController.text == element.maBuuGui)
            .khoiLuong;
      }
      if (isDo.value) {
        //kiem tra k1 k2 k3 co empty khong
        if (k1.text.isNotEmpty && k2.text.isNotEmpty && k3.text.isNotEmpty) {
          bgTemp.listDo = [k1.text, k2.text, k3.text];
        }
      }
      buuGuis.add(bgTemp);
    }
    buuGuis.sort((a, b) => b.index!.compareTo(a.index!));
    textMHController.text = "";
    textKLController.text = "";
    textHintController.text = "";
    k1.text = "";
    k2.text = "";
    k3.text = "";
    focusHint.requestFocus();
    update();
  }

  addKL(int kl) {
    textKLController.text = kl.toString();
    addKhachHang();
  }

  deleteSelected() {
    if (iBuuGui.value != -1) {
      buuGuis.removeAt(iBuuGui.value);
    }
    refreshSussgest();
    update();
  }

  deleteAll() {
    buuGuis.clear();
    refreshSussgest();
    update();
  }

  refreshSussgest() {
    susggestMHs.clear();
    for (var buugui in khachHang.value.buuGuis!) {
      if (buugui.trangThai == "Đang đi thu gom" ||
          buugui.trangThai == "Nhận hàng thành công" ||
          buugui.trangThai == "Đã phân hướng") {
        susggestMHs.add(buugui.maBuuGui!);
      }
    }
    if (buuGuis.isNotEmpty) {
      susggestMHs.removeWhere((element1) =>
          buuGuis.where((element) => element.maBuuGui == element1).isNotEmpty);
    }
  }

  void setUp(KhachHangs kh) {
    if (kh.tenKH != khachHang.value.tenKH) {
      khachHang.value = kh;
      refreshSussgest();
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
    opacityLevel.value = 0;
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

  void checkSelected() {
    //kiem tra listDo trong iBuugui co empty khong va hien len thong qua k1 k2 k3
    if (iBuuGui.value != -1) {
      var bg = buuGuis[iBuuGui.value];
      if (bg.listDo != null) {
        k1.text = bg.listDo![0];
        k2.text = bg.listDo![1];
        k3.text = bg.listDo![2];
      } else {
        k1.text = "";
        k2.text = "";
        k3.text = "";
      }
    }
  }

  printSelected() {
    //gui len in ma hieu duoc chon
    if (iBuuGui.value != -1) {
      FirebaseManager().addMessage(
          MessageReceiveModel("printBD1New", buuGuis[iBuuGui.value].maBuuGui!));
    }
  }

  void sendPrintBD1() {
    stateText.value = "Đang gửi mã hiệu";

    List<String> maHieus = buuGuis.map((e) => e.maBuuGui!).toList();

    FirebaseManager().addMessageToAppBD(
        FirebaseManager().keyData!,
        MessageReceiveModel(
            "dongdingoai",
            jsonEncode(Dingoaicodes(
                codes: maHieus,
                codeIDs: null,
                isAutoBD: false,
                isSorted: false,
                isPrinted: false)),
            nameMay: FirebaseManager().keyData!));
  }
}
