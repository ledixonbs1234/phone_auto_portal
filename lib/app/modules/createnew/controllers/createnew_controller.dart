import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/createnew/model/dingoaistateinfo.dart';
import 'package:phone_auto_portal/app/modules/home/khach_hangs_model.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/dingoaicodes_model.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/state_ma_hieu_model.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';

import '../../home/messageReceiveModel.dart';

class CreatenewController extends GetxController {
  final khachHang = KhachHangs().obs;
  final buuGuis = <BuuGuis>[].obs;
  final diNgoaiStates = <DiNgoaiStateInfo>[].obs;
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
  String account = "";
  String password = "";

  TextEditingController textHintController = TextEditingController();
  TextEditingController k1 = TextEditingController();
  TextEditingController k2 = TextEditingController();
  TextEditingController k3 = TextEditingController();

  TextEditingController textMHController = TextEditingController();

  TextEditingController textKLController = TextEditingController();

  late FocusNode focusHint;
  final count = 0.obs;

  final selectedState = "CC".obs;

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

  void printAll() {
    if (buuGuis.isEmpty) return;

    // Collecting maHieu values from buuGuis
    List<String?> maHieus = buuGuis.map((buuGui) => buuGui.maBuuGui).toList();

    // Sending the list of maHieus as a message
    FirebaseManager()
        .addMessage(MessageReceiveModel("printMaHieus", jsonEncode(maHieus)));
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

  void refreshSussgest() {
    // Xóa danh sách mã hiệu MH gợi ý hiện tại
    susggestMHs.clear();

    // Lặp qua danh sách các đối tượng bưu gửi liên quan đến khách hàng
    for (var buugui in khachHang.value.buuGuis!) {
      // Kiểm tra xem trạng thái của đối tượng bưu gửi có khớp với bất kỳ trạng thái nào được chỉ định không
      if (buugui.trangThai ==
              "Đang đi thu gom" || // "In collection" (Đang đi thu gom)
          buugui.trangThai ==
              "Nhận hàng thành công" || // "Successful delivery" (Nhận hàng thành công)
          buugui.trangThai == "Đã phân hướng") {
        // "Directed" (Đã phân hướng)
        // Thêm mã bưu gửi vào danh sách gợi ý
        susggestMHs.add(buugui.maBuuGui!);
      }
    }

    // Nếu có bất kỳ đối tượng bưu gửi nào trong danh sách buuGuis
    if (buuGuis.isNotEmpty) {
      // Xóa bất kỳ mã hiệu MH gợi ý nào đã có trong danh sách buuGuis
      susggestMHs.removeWhere((element1) =>
          buuGuis.where((element) => element.maBuuGui == element1).isNotEmpty);
      //thay thế index trong buuGuis bằng index của bưu gửi + 1
      int index = buuGuis.length;
      for (var buuGui in buuGuis.toList()) {
        buuGui.index = index;
        index--;
      }
    }
  }

  khoiTaoPortal() {
    stateText.value = "Đang khởi tạo";
    FirebaseManager().addMessage(MessageReceiveModel(
        "khoitao",
        const JsonEncoder().convert({
          "maKH": khachHang.value.maKH,
          "account": account,
          "password": password
        })));
  }

  void setUp(KhachHangs kh, String account, String password) {
    // if (kh.tenKH != khachHang.value.tenKH) {
    khachHang.value = kh;
    this.account = account;
    this.password = password;
    refreshSussgest();
    // }
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

    FirebaseManager().setListBG(buuGuis);

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
      case "message":
        stateText.value = message.DoiTuong;

        break;
      case "showdetailmessage":
        stateText.value = message.DoiTuong;
        break;
      case "printDone":
        stateText.value = "In xong";
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

  bool isValidMaHieu(String maHieu) {
    const pattern = r'^[c|C|r|R|e|E|p|P][a-zA-Z]\d{9}[v|V][n|N]$';

    final regExp = RegExp(pattern);

    return regExp.hasMatch(maHieu);
  }

  StreamSubscription? onListenBarcode;
  void addKhachHangAsQR() {
    try {
      printInfo(info: "Scan multi code");
      if (onListenBarcode != null) {
        onListenBarcode!.cancel();
      }
      List<String> notMHs = [];

      onListenBarcode = FlutterBarcodeScanner.getBarcodeStreamReceiver(
              "#ff6666", 'Cancel', true, ScanMode.DEFAULT)
          ?.listen((barcode) async {
        String barcodeFilled = barcode.trim().toString().toUpperCase();

        bool isValid = isValidMaHieu(barcodeFilled);
        if (isValid) {
          if (susggestMHs.contains(barcodeFilled)) {
            if (selectedState.value == "CC") {
              susggestMHs.remove(barcodeFilled);

              printInfo(info: "Code is $barcodeFilled");

              // Get.snackbar("Thông báo", "Added $barcodeFilled",
              //     duration: const Duration(seconds: 1));

              var bgTemp =
                  BuuGuis(index: buuGuis.length + 1, maBuuGui: barcodeFilled);
              bgTemp.khoiLuong = khachHang.value.buuGuis!
                  .firstWhere((element) => barcodeFilled == element.maBuuGui)
                  .khoiLuong;
              buuGuis.add(bgTemp);
              buuGuis.sort((a, b) => b.index!.compareTo(a.index!));

              update();
              if (buuGuis.length < 100) {
                await AssetsAudioPlayer.newPlayer().open(
                  Audio("assets/${buuGuis.length}.wav"),
                );
              } else {
                await AssetsAudioPlayer.newPlayer().open(
                  Audio("assets/beep.mp3"),
                );
              }
            } else {
              var diNgoai = diNgoaiStates
                  .firstWhereOrNull((e) => e.maHieu == barcodeFilled);
              if (diNgoai != null) {
                susggestMHs.remove(barcodeFilled);

              printInfo(info: "Code is $barcodeFilled");

              // Get.snackbar("Thông báo", "Added $barcodeFilled",
              //     duration: const Duration(seconds: 1));

              var bgTemp =
                  BuuGuis(index: buuGuis.length + 1, maBuuGui: barcodeFilled);
              bgTemp.khoiLuong = khachHang.value.buuGuis!
                  .firstWhere((element) => barcodeFilled == element.maBuuGui)
                  .khoiLuong;
              buuGuis.add(bgTemp);
              buuGuis.sort((a, b) => b.index!.compareTo(a.index!));

              update();
              if (buuGuis.length < 100) {
                await AssetsAudioPlayer.newPlayer().open(
                  Audio("assets/${buuGuis.length}.wav"),
                );
              } else {
                await AssetsAudioPlayer.newPlayer().open(
                  Audio("assets/beep.mp3"),
                );
              }
              }else{
                await AssetsAudioPlayer.newPlayer().open(
                  Audio("assets/kocobg.mp3"),
                );
              }
            }
          } else if (!notMHs.contains(barcodeFilled)) {
            notMHs.add(barcodeFilled);
            await AssetsAudioPlayer.newPlayer().open(
              Audio("assets/kocobg.mp3"),
            );
          }
        }
      });
    } on PlatformException {
      Get.snackbar("Thông báo", "Lỗi barcode");
    }
  }

  void dieuTin() {
    if (buuGuis.isEmpty) return;

    // Collecting maHieu values from buuGuis
    List<String?> maHieus = buuGuis.map((buuGui) => buuGui.maBuuGui).toList();

    // Sending the list of maHieus as a message
    FirebaseManager()
        .addMessage(MessageReceiveModel("dieuTin", jsonEncode(maHieus)));
  }

  void hoanTatTin() {
    if (buuGuis.isEmpty) return;

    // Collecting maHieu values from buuGuis
    List<String?> maHieus = buuGuis.map((buuGui) => buuGui.maBuuGui).toList();

    // Sending the list of maHieus as a message
    FirebaseManager()
        .addMessage(MessageReceiveModel("hoanTatTin", jsonEncode(maHieus)));
  }

  void checkItemDone() {
    //thực hiện việc lấy mã đơn hiện tại
  }

  void syncCodes(List<StateMaHieu> codes) {
    //kiểm tra bưu gửi có trong danh sách codes không
    // nếu có thì chuyển state thành "Đã nhập"
    for (var code in codes) {
      var bg =
          buuGuis.firstWhereOrNull((element) => element.maBuuGui == code.code);
      if (bg != null) {
        bg.trangThai = "OK";
      }
    }
  }

  Future<void> getDiNgoaisTempFromFirebase() async {
    diNgoaiStates.value = await FirebaseManager().getDiNgoaisTemp();
    stateText.value = "Đã lấy ${diNgoaiStates.length} mã hiệu";
    susggestMHs.clear();
    for (var diNgoai in diNgoaiStates) {
      susggestMHs.add(diNgoai.maHieu!);
    }
    khachHang.value.tenKH = "Kiểm tra Hàng";
  }
}
