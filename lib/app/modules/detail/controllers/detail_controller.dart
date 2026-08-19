import 'dart:convert';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/khach_hangs_model.dart';
import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';

class DetailController extends GetxController {
  final khachHang = KhachHangs().obs;
  final isCheckedDangGom = false.obs;
  final isCheckPhanHuong = false.obs;
  final isCheckNhanHang = false.obs;
  final isCheckChapNhan = false.obs;
  final isDeletePhone = true.obs;
  final isShowTimeTrangThai = false.obs;
  final buuGuis = <BuuGuis>[].obs;
  final isEnableRunBtn = true.obs;
  final iSeBuuGui = (-1).obs;
  final count = 0.obs;
  final stateText = "".obs;
  String account = "";
  String password = "";
  void setUp(KhachHangs kh, String account, String password) {
    khachHang.value = kh;
    this.account = account;
    this.password = password;
    isCheckChapNhan.value = false;
    setDefaultInfo();
  }

  void setDefaultInfo() {
    buuGuis.clear();
    khachHang.value.countState?.countDangGom != 0
        ? isCheckedDangGom.value = true
        : isCheckedDangGom.value = false;

    khachHang.value.countState?.countNhanHang != 0
        ? isCheckNhanHang.value = true
        : isCheckNhanHang.value = false;

    khachHang.value.countState?.countPhanHuong != 0
        ? isCheckPhanHuong.value = true
        : isCheckPhanHuong.value = false;
    updateBuuguiFromCheck();

    update();
  }

    void updateBuuguiFromCheck() {
    buuGuis.clear();
    if (khachHang.value.buuGuis == null) {
      iSeBuuGui.value = -1;
      buuGuis.refresh();
      update();
      return;
    }
    final allBG = khachHang.value.buuGuis!;
    if (isCheckedDangGom.value) {
      buuGuis.addAll(allBG.where((element) =>
          element.trangThai == 'Đang đi thu gom' ||
          element.trangThai == 'Tạo đơn'));
    }
    if (isCheckNhanHang.value) {
      buuGuis.addAll(allBG.where((element) =>
          element.trangThai == 'Nhận hàng thành công' ||
          element.trangThai == 'Bưu tá nhận yêu cầu thu gom'));
    }
    if (isCheckPhanHuong.value) {
      buuGuis.addAll(allBG.where((element) =>
          element.trangThai == 'Đã phân hướng' ||
          element.trangThai == 'Đã lấy hàng'));
    }
    if (isCheckChapNhan.value) {
      buuGuis.addAll(allBG.where((element) => element.trangThai == 'Đã chấp nhận'));
    }
    if (buuGuis.isNotEmpty) {
      final small = buuGuis.where((m) => (m.khoiLuong ?? 0) < 2000).toList();
      small.removeWhere((element) => (element.maBuuGui ?? '').length < 13);
      final large = buuGuis.where((m) => (m.khoiLuong ?? 0) >= 2000).toList();
      large.removeWhere((element) => (element.maBuuGui ?? '').length < 13);
      small.sort((a, b) {
        try {
          if (a.maBuuGui!.substring(9, 11) == b.maBuuGui!.substring(9, 11)) {
            return int.parse(b.maBuuGui!.substring(8, 9)) -
                int.parse(a.maBuuGui!.substring(8, 9));
          } else {
            return int.parse(b.maBuuGui!.substring(9, 11)) -
                int.parse(a.maBuuGui!.substring(9, 11));
          }
        } catch (_) {
          return 0;
        }
      });
      large.sort((a, b) {
        try {
          if (a.maBuuGui!.substring(9, 11) == b.maBuuGui!.substring(9, 11)) {
            return int.parse(a.maBuuGui!.substring(8, 9)) -
                int.parse(b.maBuuGui!.substring(8, 9));
          } else {
            return int.parse(b.maBuuGui!.substring(9, 11)) -
                int.parse(a.maBuuGui!.substring(9, 11));
          }
        } catch (_) {
          return 0;
        }
      });
      buuGuis.value = large + small;
      for (var i = 0; i < buuGuis.length; i++) {
        buuGuis[i].index = i + 1;
      }
      iSeBuuGui.value = 0;
      FirebaseManager().getBlackList().then((value) {
        for (var bg in buuGuis) {
          bg.isBlackList = value.contains(bg.maBuuGui);
        }
        buuGuis.refresh();
        update();
      });
    } else {
      iSeBuuGui.value = -1;
    }
    buuGuis.refresh();
    update();
  }

  void increment() => count.value++;

  void onListenNotification(MessageReceiveModel message) {
    switch (message.Lenh) {
      case "checkstatemh":
        var splitText = message.DoiTuong.split("|");
        var bg = buuGuis
            .firstWhereOrNull((element) => element.maBuuGui == splitText[0]);
        bg?.trangThaiRequest = "Xong";
        bg?.money = splitText[1];

        update();
      case "showdetailmessage":
        stateText.value = message.DoiTuong;
        break;
      case "printDone":
        stateText.value = "In xong";
        break;
      case "message":
        stateText.value = message.DoiTuong;
        break;
      default:
    }
  }

  String lastmaKH = "";

  void sendToPortal({bool isAuto = false}) {
    //thực hiện send to portal
    printInfo(info: "Send to portal");
    if (iSeBuuGui.value == -1) {
      return;
    }
    if (buuGuis.isEmpty) return;
    stateText.value = "Đang gửi thông tin";
    bool isFirst = true;

    if (lastmaKH.isNotEmpty) {
      if (lastmaKH == khachHang.value.maKH) {
        isFirst = false;
      }
    }

//setListBG where buuGuis isBlackList = false
    var list = buuGuis.where((element) => !element.isBlackList).toList();
    if (list.isEmpty) {
      stateText.value = "Không có mã nào để gửi";
      return;
    }

    FirebaseManager().sendListBDToPortal(list);
    final String maKHValue = khachHang.value.maKH!;
    final String maBGValue = buuGuis[iSeBuuGui.value].maBuuGui!;

    final Map<String, dynamic> messageData = {
      'maKH': maKHValue,
      'maBG': maBGValue,
      'isFirst': isFirst.toString(),
      'account': account,
      'password': password,
      'isDeletePhone': isDeletePhone.value
    };
// Truyền thẳng Map vào, không cần encode/decode
    FirebaseManager().addMessage(MessageReceiveModel(
      !isAuto ? "sendtoportal" : "sendautotoportal",
      const JsonEncoder().convert(messageData),
    ));
  }

  void stopToPortal() {
    FirebaseManager().addMessage(MessageReceiveModel("stoptoportal", ''));
  }

  addMHToBlackList(int index) {
    if (buuGuis.isEmpty) return;
    buuGuis[index].isBlackList = true;
    FirebaseManager().pushBlackList(buuGuis[index].maBuuGui!);
    update();
  }

  removeMHFromBlackList(int index) {
    if (buuGuis.isEmpty) return;
    buuGuis[index].isBlackList = false;
    FirebaseManager().deleteBlackList(buuGuis[index].maBuuGui!);
    update();
  }

  void printBD1() {
    if (buuGuis.isEmpty) return;
    FirebaseManager().addMessage(MessageReceiveModel("printbd1", ""));
  }

  void printAll() {
    if (buuGuis.isEmpty) return;

    // Collecting maHieu values from buuGuis khác blacklist
    List<String?> maHieus = buuGuis
        .where((element) => !element.isBlackList)
        .map((buuGui) => buuGui.maBuuGui)
        .toList();

    // Sending the list of maHieus as a message
    FirebaseManager()
        .addMessage(MessageReceiveModel("printMaHieus", jsonEncode(maHieus)));
  }

  void updateWeight(int index, int newWeight) {
    if (index >= 0 && index < buuGuis.length) {
      buuGuis[index].khoiLuong = newWeight;
      update();
    }
  }
}
