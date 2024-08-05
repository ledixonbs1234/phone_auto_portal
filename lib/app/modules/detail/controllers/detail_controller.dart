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
  final buuGuis = <BuuGuis>[].obs;
  final isEnableRunBtn = true.obs;
  final iSeBuuGui = (-1).obs;
  final count = 0.obs;
  final stateText = "".obs;

  void setUp(KhachHangs kh) {
    khachHang.value = kh;
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
    if (isCheckedDangGom.value) {
      buuGuis.addAll(khachHang.value.buuGuis!
          .where((element) => element.trangThai == 'Đang đi thu gom'));
    }
    if (isCheckNhanHang.value) {
      buuGuis.addAll(khachHang.value.buuGuis!
          .where((element) => element.trangThai == 'Nhận hàng thành công'));
    }
    if (isCheckPhanHuong.value) {
      buuGuis.addAll(khachHang.value.buuGuis!
          .where((element) => element.trangThai == 'Đã phân hướng'));
    }
    if (isCheckChapNhan.value) {
      buuGuis.addAll(khachHang.value.buuGuis!
          .where((element) => element.trangThai == 'Đã chấp nhận'));
    }

    if (buuGuis.isNotEmpty) {
      final small = buuGuis.where((m) => m.khoiLuong! < 2000).toList();
      //remove in small if m.maBuuGui.Length < 13
      small.removeWhere((element) => element.maBuuGui!.length < 13);
      final large = buuGuis.where((m) => m.khoiLuong! >= 2000).toList();
      large.removeWhere((element) => element.maBuuGui!.length < 13);
      small.sort((a, b) {
        if (a.maBuuGui!.substring(9, 11) == b.maBuuGui!.substring(9, 11)) {
          return int.parse(b.maBuuGui!.substring(8, 9)) -
              int.parse(a.maBuuGui!.substring(8, 9));
        } else {
          return int.parse(b.maBuuGui!.substring(9, 11)) -
              int.parse(a.maBuuGui!.substring(9, 11));
        }
      });
      large.sort((a, b) {
        if (a.maBuuGui!.substring(9, 11) == b.maBuuGui!.substring(9, 11)) {
          return int.parse(a.maBuuGui!.substring(8, 9)) -
              int.parse(b.maBuuGui!.substring(8, 9));
        } else {
          return int.parse(b.maBuuGui!.substring(9, 11)) -
              int.parse(a.maBuuGui!.substring(9, 11));
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

        update();
      });
    }
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

      default:
    }
  }

  void sendToPortal() {
    //thực hiện send to portal
    printInfo(info: "Send to portal");
    if (iSeBuuGui.value == -1) {
      return;
    }
    if (buuGuis.isEmpty) return;
    stateText.value = "Đang gửi thông tin";

//setListBG where buuGuis isBlackList = false

    FirebaseManager().setListBG(
        // ignore: invalid_use_of_protected_member
        buuGuis.value.where((element) => !element.isBlackList).toList());
    FirebaseManager().addMessage(MessageReceiveModel(
        "sendtoportal",
        '{'
                '"maKH"'
                ': "${khachHang.value.maKH}", '
                '"maBG"'
                ':"${buuGuis[iSeBuuGui.value].maBuuGui}"}'
            .toString()));
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
}
