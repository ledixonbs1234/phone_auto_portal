import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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
  final tenKH = "".obs;
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
        if (selectedState.value == "CC") {
          bgTemp.khoiLuong = khachHang.value.buuGuis!
              .firstWhere(
                  (element) => textMHController.text == element.maBuuGui)
              .khoiLuong;
        } else {
          bgTemp.khoiLuong = 1000;
        }
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
    if (selectedState.value == "CC") {
      refreshSussgest();
    } else {
      getDiNgoaisTempFromFirebase();
    }
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
    if (selectedState.value == "CC") {
      khachHang.value = kh;
      tenKH.value = kh.tenKH!;
      this.account = account;
      this.password = password;
      refreshSussgest();
      selectedState.value = "CC";
    } else {}
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

      // Cancel any existing barcode listener
      onListenBarcode?.cancel();

      List<String> notMHs = [];

      onListenBarcode = FlutterBarcodeScanner.getBarcodeStreamReceiver(
              "#ff6666", 'Cancel', true, ScanMode.DEFAULT)
          ?.listen((barcode) async {
        String barcodeFilled = barcode.trim().toUpperCase();

        if (isValidMaHieu(barcodeFilled)) {
          await _handleValidBarcode(barcodeFilled, notMHs);
        }
      });
    } on PlatformException {
      Get.snackbar("Thông báo", "Lỗi barcode");
    }
  }

  Future<void> _handleValidBarcode(
      String barcodeFilled, List<String> notMHs) async {
    if (susggestMHs.contains(barcodeFilled)) {
      await _processSuggestedBarcode(barcodeFilled, notMHs);
    } else if (buuGuis.any((element) => element.maBuuGui == barcodeFilled)) {
    } else if (!notMHs.contains(barcodeFilled)) {
      notMHs.add(barcodeFilled);
      await _playAudio("assets/kocobg.wav");
    } else {
      // await _playAudio("assets/kocobg.wav");
    }
  }

  Future<void> _processSuggestedBarcode(
      String barcodeFilled, List<String> notMHs) async {
    var existingDiNgoais =
        diNgoaiStates.firstWhereOrNull((m) => m.maHieu == barcodeFilled);
    if (selectedState.value == "CC" || existingDiNgoais != null) {
      printInfo(info: "Code is $barcodeFilled");

      var bgTemp = BuuGuis(
        index: buuGuis.length + 1,
        maBuuGui: barcodeFilled,
      );

// Xử lý khối lượng
      existingDiNgoais == null
          ? bgTemp.khoiLuong = khachHang.value.buuGuis!
              .firstWhere((element) => barcodeFilled == element.maBuuGui)
              .khoiLuong
          : bgTemp.khoiLuong = 1000;
      var existingBG =
          buuGuis.firstWhereOrNull((m) => m.maBuuGui == barcodeFilled);

      final shouldAdd = existingDiNgoais == null ||
          existingDiNgoais.keyExactly == selectedState.value;

      if (shouldAdd && existingBG == null) {
        susggestMHs.remove(barcodeFilled);
        buuGuis
          ..add(bgTemp)
          ..sort((a, b) => b.index!.compareTo(a.index!));
        update();

        final length = buuGuis.length;
        final audioPath =
            length < 100 ? "assets/$length.wav" : "assets/beep.mp3";
        await _playAudio(audioPath);
      } else {
        if (existingBG == null) await _playAudio("assets/lachuong.mp3");
      }
    } else {
      if (existingDiNgoais == null) {
        await _playAudio("assets/kocobg.mp3");
      }
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      await AssetsAudioPlayer.newPlayer().open(Audio(path));
    } catch (e) {}
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
    tenKH.value = "Kiểm tra Hàng";
    update();
  }

  void preparePrint() {
    //thực hiện việc send Message để chuẩn bị in toàn bộ cho nó tự chạy

    // Collecting maHieu values from buuGuis
    List<String?> maHieus =
        diNgoaiStates.map((buuGui) => buuGui.maHieu).toList();
    if (maHieus.isEmpty) {
      stateText.value = "Không có mã hiệu";
      return;
    }

    // Sending the list of maHieus as a message
    FirebaseManager().addMessage(
        MessageReceiveModel("preparePrintMaHieus", jsonEncode(maHieus)));
    stateText.value = "Đang chuẩn bị in";
  }

  Future<void> printAllAndDelete() async {
    printAll();
    await deleteBuuGuisOnFirebase();
  }

  Future<void> deleteBuuGuisOnFirebase() async {
    await FirebaseManager().deleteBuuGuis(buuGuis.value);
    if (susggestMHs.isEmpty) {
      _playAudio("assets/dusoluong.wav");
    }
  }
}
