import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/portal_model.dart';

import '../../../../data/firebaseManager.dart';
import '../../home/khach_hangs_model.dart';
import '../../home/messageReceiveModel.dart';

class EditPageController extends GetxController {
  final portal = Portal().obs;

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

  addKL(int kl) {
    textKLController.text = kl.toString();
    addKhachHang();
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

  refreshSussgest() {
    susggestMHs.clear();
    for (var buugui in portal.value.buuGuiPs!) {
      susggestMHs.add(buugui.maHieu!);
    }
    if (buuGuis.isNotEmpty) {
      susggestMHs.removeWhere((element1) =>
          buuGuis.where((element) => element.maBuuGui == element1).isNotEmpty);
    }
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

  void addKhachHang() {
    susggestMHs.remove(textMHController.text);
    var bgTemp =
        BuuGuis(index: buuGuis.length + 1, maBuuGui: textMHController.text);
    bgTemp.id = portal.value.buuGuiPs
        ?.firstWhere((element) => element.maHieu == bgTemp.maBuuGui)
        .id!;
    if (textMHController.text.isNotEmpty) {
      if (isChangeKL.value) {
        if (textKLController.text.isNotEmpty) {
          bgTemp.khoiLuong = int.parse(textKLController.text);
        }
      } else {
        bgTemp.khoiLuong = int.parse(portal.value.buuGuiPs!
            .firstWhere((element) => textMHController.text == element.maHieu!)
            .weight!);
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

  void loadEditPage(Portal selectedPortal) {
    //thuc hien lay du lieu danh sach tu firebase
    portal.value = selectedPortal;
    FirebaseManager().addMessage(MessageReceiveModel(
        "getMaHieusFromEditPage", jsonEncode([portal.value.id])));
  }

  void onListenNotification(MessageReceiveModel message) {
    if (message.Lenh == "getMaHieusFromEditPage") {
      var listJson = jsonDecode(message.DoiTuong);
      portal.value.buuGuiPs =
          listJson.map<BuuGuiPs>((e) => BuuGuiPs.fromJson(e)).toList();
      refreshSussgest();
    }
  }

  editAll() {
    printInfo(info: "Đang edit portal");
    if (iBuuGui.value == -1) {
      return;
    }
    if (buuGuis.isEmpty) return;
    stateText.value = "Đang gửi thông tin";

    FirebaseManager().setListBG(buuGuis);

    FirebaseManager().addMessage(MessageReceiveModel(
        "edittoportal",
        '{'
                '"idPortal"'
                ': "${portal.value.id}", '
                '"maBG"'
                ':"${buuGuis[iBuuGui.value].maBuuGui}"}'
            .toString()));
  }
}
