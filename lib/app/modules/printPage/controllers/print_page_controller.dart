import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/khach_hangs_model.dart';
import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';

class PrintPageController extends GetxController {
  TextEditingController editMHC = TextEditingController();
  final khachHang = KhachHangs().obs;
  final buuGui = "".obs;
  void onChangeMH(String maHieu) {
    int count = 0;

    String currentMaHieu = "";

    for (var buugui in khachHang.value.buuGuis!) {
      if (buugui.maBuuGui!.lastIndexOf(maHieu) != -1) {
        currentMaHieu = buugui.maBuuGui!;
        count++;
        if (count > 1) {
          break;
        }
      }
    }

    if (count == 1) {
      buuGui.value = currentMaHieu;
      editMHC.text = "";
    } else {
      if (maHieu.length == 13) {
        buuGui.value = maHieu.toUpperCase();
        editMHC.text = "";
      }
    }
  }

  void printMaHieu() {
    if (editMHC.text.isNotEmpty) {
      if (buuGui.value.isNotEmpty) {
        FirebaseManager()
            .addMessage(MessageReceiveModel("printBD1New", buuGui.value));
      }
    }
  }
}
