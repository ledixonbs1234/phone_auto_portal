import 'dart:convert';

import 'package:get/get.dart';

import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/dingoaicodes_model.dart';

import 'package:phone_auto_portal/app/modules/portalinfo/portal_model.dart';

import 'package:phone_auto_portal/data/firebaseManager.dart';

class PortalinfoController extends GetxController {
  final portals = <Portal>[].obs;

  final iPotal = 0.obs;

  final maychus = <String>["maychu", "mayphu", "mayphusan", "maytest"].obs;

  final selectedMayChu = "maychu".obs;

  final stateText = "".obs;

  final isSortDiNgoai = false.obs;
  final isPrinted = true.obs;

  var isWaitingCodes = false;

  Future<void> refreshPortal() async {
    await FirebaseManager().refreshPortal();

    stateText.value = "Đang cập nhật dữ liệu";
  }

  sendDiNgoai() {
    //thuc hien send di ngoai can co may chu hien thi danh sach may chu can send

    //key sendingoai item doi tuong maychu

    //  var listMaHieu = selecteds.map<String>((ThongTin r) => r.maHieu!).toList();

    // if (iPotal.value != -1) {

    //   isWaitingCodes = true;

    //   FirebaseManager().addMessage(

    //       MessageReceiveModel("getMaHieus", portals[iPotal.value].id!));

    // }

    List<String> selecteds = [];

    for (var portal in portals) {
      if (portal.selected) {
        selecteds.add(portal.id!);
      }
    }

    if (selecteds.isNotEmpty) {
      isWaitingCodes = true;

      FirebaseManager()
          .addMessage(MessageReceiveModel("getMaHieus", jsonEncode(selecteds)));
    }

    // FirebaseManager()

    // .addMessageToAppBD(selectedMayChu.value, MessageReceiveModel("", ""));
  }

  Future<void> printPageSelected() async {
    List<String> selecteds = [];

    for (var portal in portals) {
      if (portal.selected) {
        selecteds.add(portal.id!);
      }
    }

    if (selecteds.isNotEmpty) {
      isWaitingCodes = true;

      FirebaseManager()
          .addMessage(MessageReceiveModel("printPage", jsonEncode(selecteds)));
    }
  }

  void onListenNotification(MessageReceiveModel message) {
    if (message.Lenh == "getMaHieus") {
      if (isWaitingCodes) {
        isWaitingCodes = false;

        //json decode string to List<string>

        stateText.value = "Đã lấy được mã hiệu và đang gửi";

        var codes = List<String>.from(json.decode(message.DoiTuong));

        final reCodes = codes.reversed;

        FirebaseManager().addMessageToAppBD(
            selectedMayChu.value,
            MessageReceiveModel(
                "dongdingoai",
                jsonEncode(Dingoaicodes(
                    codes: codes,
                    isSorted: isSortDiNgoai.value,
                    isPrinted: isPrinted.value))));
      }
    } else if (message.Lenh == "message") {
      stateText.value = message.DoiTuong;
    }
  }

  void layDuLieu() {
    stateText.value = "Đang lấy dữ liệu";

    FirebaseManager().addMessageToAppBD(
        selectedMayChu.value, MessageReceiveModel("laydulieu200", ""));
  }

  void layDuLieuLo() {
    stateText.value = "Đang lấy dữ liệu Lô";

    FirebaseManager().addMessageToAppBD(
        selectedMayChu.value, MessageReceiveModel("laydulieulo", ""));
  }

  void editHangHoas() {
    String id = "";

    for (var portal in portals) {
      if (portal.selected) {
        id = portal.id!;

        break;
      }
    }

    if (id.isNotEmpty) {
      FirebaseManager().addMessage(MessageReceiveModel("edithanghoa", id));
    }
  }
}
