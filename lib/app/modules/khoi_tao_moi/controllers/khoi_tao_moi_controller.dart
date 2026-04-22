import 'dart:async';
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';
import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';
import 'package:phone_auto_portal/app/modules/home/khach_hangs_model.dart';
import 'package:phone_auto_portal/app/modules/home/controllers/home_controller.dart';
import '../models/suggestion_item.dart';

class KhoiTaoMoiController extends GetxController {
  String? hdrId;
  final hdrIdText = "".obs;
  final buuGuis = <BuuGuis>[].obs;
  final stateText = "".obs;
  final iBuuGui = (-1).obs;
  String account = "";
  String password = "";
  String lastmaKH = "";
  final isLoading = true.obs;

  final isLockedCustomer = false.obs;
  final lockedMaKH = "".obs;
  final lockedTenKH = "".obs;
  final allSuggestMHs = <SuggestionItem>[].obs;
  final suggestMHs = <SuggestionItem>[].obs;
  late TextEditingController textHintController;
  late FocusNode focusHint;

  late MobileScannerController mobileScannerController;
  StreamSubscription<BarcodeCapture>? onListenBarcode;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    textHintController = TextEditingController();
    focusHint = FocusNode();

    loadFromFirebase();
  }

  @override
  void onReady() {
    super.onReady();
    printInfo(info: "KhoiTaoMoiController onReady");
  }

  static const List<String> validStatuses = [
    "Đang đi thu gom",
    "Nhận hàng thành công",
    "Đã phân hướng",
    "Tạo đơn",
    "Bưu tá nhận yêu cầu thu gom",
    "Đã lấy hàng",
  ];

  bool _isValidStatus(String? status) {
    if (status == null) return false;
    return validStatuses.contains(status);
  }

  void loadAllSuggestions() {
    try {
      final homeController = Get.find<HomeController>();
      allSuggestMHs.clear();
      for (var kh in homeController.khachHangs) {
        if (kh.buuGuis != null) {
          for (var bg in kh.buuGuis!) {
            if (bg.maBuuGui != null &&
                bg.maBuuGui!.isNotEmpty &&
                _isValidStatus(bg.trangThai)) {
              allSuggestMHs.add(SuggestionItem(
                maBuuGui: bg.maBuuGui!,
                maKH: kh.maKH ?? '',
                tenKH: kh.tenKH ?? '',
                khoiLuong: bg.khoiLuong,
              ));
            }
          }
        }
      }
      refreshSuggestions();
    } catch (e) {
      'Error loading suggestions: $e'.printInfo();
    }
  }

  void refreshSuggestions() {
    if (isLockedCustomer.value && lockedMaKH.value.isNotEmpty) {
      suggestMHs.value =
          allSuggestMHs.where((item) => item.maKH == lockedMaKH.value).toList();
    } else {
      suggestMHs.value = allSuggestMHs.toList();
    }
  }

  void toggleLockCustomer(String maKH, String tenKH) {
    if (isLockedCustomer.value && lockedMaKH.value == maKH) {
      isLockedCustomer.value = false;
      lockedMaKH.value = "";
      lockedTenKH.value = "";
    } else {
      isLockedCustomer.value = true;
      lockedMaKH.value = maKH;
      lockedTenKH.value = tenKH;
    }
    refreshSuggestions();
  }

  void unlockCustomer() {
    isLockedCustomer.value = false;
    refreshSuggestions();
  }

  bool isMaHieuExists(String maBuuGui) {
    return buuGuis
        .any((bg) => bg.maBuuGui?.toUpperCase() == maBuuGui.toUpperCase());
  }

  int? getKhoiLuongFromSuggestion(String maBuuGui) {
    final upperMaBuuGui = maBuuGui.toUpperCase();
    final found = allSuggestMHs.firstWhereOrNull(
        (item) => item.maBuuGui.toUpperCase() == upperMaBuuGui);
    return found?.khoiLuong;
  }

  void onSelectedSuggestion(SuggestionItem item) {
    if (!isLockedCustomer.value) {
      toggleLockCustomer(item.maKH, item.tenKH);
    }
    addMaHieuFromText(item.maBuuGui, khoiLuong: item.khoiLuong);
  }

  void setUpGlobal(String account, String password) {
    this.account = account;
    this.password = password;
    hdrIdText.value = "";
    hdrId = null;
  }

  Future<void> loadFromFirebase() async {
    isLoading.value = true;
    try {
      final db = FirebaseManager();
      final snapshot = await db.rootPath.child('khoi_tao_moi').once();
      if (snapshot.snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        buuGuis.clear();
        if (data['buuGuis'] != null) {
          final List<dynamic> buuGuisList = data['buuGuis'] as List<dynamic>;
          for (var item in buuGuisList) {
            final bg = BuuGuis();
            bg.index = item['index'];
            bg.maBuuGui = item['maBuuGui'];
            bg.khoiLuong = item['khoiLuong'];
            bg.trangThai = item['trangThai'];
            bg.trangThaiRequest = item['trangThaiRequest'];
            bg.money = item['money']?.toString();
            if (item['listDo'] != null) {
              bg.listDo = List<String>.from(item['listDo']);
            }
            buuGuis.add(bg);
          }
          buuGuis.sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
        }
      } else {
        buuGuis.clear();
      }
    } catch (e) {
      'Error loading khoi_tao_moi: $e'.printInfo();
    } finally {
      isLoading.value = false;
      update();
    }
  }

  void _saveToFirebase() {
    final buuGuisData = buuGuis
        .map((bg) => {
              'index': bg.index,
              'maBuuGui': bg.maBuuGui,
              'khoiLuong': bg.khoiLuong,
              'trangThai': bg.trangThai,
              'trangThaiRequest': bg.trangThaiRequest,
              'money': bg.money,
              'listDo': bg.listDo,
            })
        .toList();
    FirebaseManager().rootPath.child('khoi_tao_moi').set({
      'buuGuis': buuGuisData,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void addKhachHangAsQR() {
    try {
      printInfo(info: "Scan multi code BM");
      onListenBarcode?.cancel();
      WakelockPlus.enable();

      mobileScannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: [
          BarcodeFormat.qrCode,
          BarcodeFormat.code128,
          BarcodeFormat.code39
        ],
      );

      onListenBarcode = mobileScannerController.barcodes
          .listen((BarcodeCapture capture) async {
        for (final barcode in capture.barcodes) {
          final String? code = barcode.rawValue;
          if (code != null && code.isNotEmpty) {
            String barcodeFilled = code.trim().toUpperCase();
            if (isValidMaHieu(barcodeFilled)) {
              await _handleValidBarcode(barcodeFilled);
            }
          }
        }
      });

      _showMobileScannerDialogForKhoiTaoMoi();
    } catch (e) {
      Get.snackbar("Thông báo", "Lỗi khi khởi tạo scanner: ${e.toString()}");
      WakelockPlus.disable();
    }
  }

  void _showMobileScannerDialogForKhoiTaoMoi() {
    Get.dialog(
      Dialog(
        child: Container(
          width: 300,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Quét mã QR/Barcode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Obx(() => Text('Đã quét: ${buuGuis.length} bưu gửi',
                  style: const TextStyle(fontSize: 14))),
              const SizedBox(height: 16),
              Expanded(
                  child: MobileScanner(controller: mobileScannerController)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      onListenBarcode?.cancel();
                      mobileScannerController.dispose();
                      WakelockPlus.disable();
                      Get.back();
                    },
                    child: const Text('Dừng'),
                  ),
                  ElevatedButton(
                    onPressed: () => mobileScannerController.toggleTorch(),
                    child: const Text('Đèn flash'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _handleValidBarcode(String barcodeFilled,
      {int? khoiLuong}) async {
    if (buuGuis.any((element) => element.maBuuGui == barcodeFilled)) {
      var existingBG =
          buuGuis.firstWhereOrNull((m) => m.maBuuGui == barcodeFilled);
      if (existingBG != null && existingBG.index! < buuGuis.length - 5) {
        await _playAudio("assets/trungdon.wav");
      }
      return;
    }

    final resolvedKhoiLuong =
        khoiLuong ?? getKhoiLuongFromSuggestion(barcodeFilled);
    var bgTemp = BuuGuis(index: buuGuis.length + 1, maBuuGui: barcodeFilled);
    bgTemp.khoiLuong = resolvedKhoiLuong ?? 0;
    buuGuis.add(bgTemp);
    buuGuis.sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));

    _saveToFirebase();
    update();

    HapticFeedback.lightImpact();
    final length = buuGuis.length;
    final audioPath = length < 100 ? "assets/$length.wav" : "assets/beep.mp3";
    await _playAudio(audioPath);
  }

  Future<void> _playAudio(String path) async {
    try {
      await _audioPlayer.setAsset(path);
      await _audioPlayer.play();
    } catch (e) {}
  }

  bool isValidMaHieu(String maHieu) {
    const pattern = r'^[c|C|r|R|e|E|p|P][a-zA-Z]\d{9}[v|V][n|N]$';
    return RegExp(pattern).hasMatch(maHieu);
  }

  Future<void> addMaHieuFromText(String maHieu, {int? khoiLuong}) async {
    final trimmedCode = maHieu.trim().toUpperCase();
    if (trimmedCode.isEmpty) return;

    if (isValidMaHieu(trimmedCode)) {
      await _handleValidBarcode(trimmedCode, khoiLuong: khoiLuong);
    } else {
      Get.snackbar("Lỗi", "Mã không hợp lệ: $trimmedCode",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> captureImage() async {
    try {
      final pickedImage =
          await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedImage != null) {
        final inputImage = InputImage.fromFilePath(pickedImage.path);
        final textRecognizer = TextRecognizer();
        final recognizedText =
            await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        for (final text in recognizedText.blocks) {
          for (final line in text.lines) {
            String a = line.text.replaceAll(' ', '').toUpperCase();
            if (a.contains('VN')) {
              String maHieu = _fillMaHieu(a);
              if (maHieu.isNotEmpty && isValidMaHieu(maHieu)) {
                await _handleValidBarcode(maHieu);
              }
            }
          }
        }
      }
    } catch (e) {
      Get.snackbar("Thông báo", "Lỗi khi chụp ảnh: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  String _fillMaHieu(String text) {
    final pattern = RegExp(r'[cCreEpP][a-zA-Z]\d{9}[vV][nN]');
    final match = pattern.firstMatch(text);
    return match?.group(0) ?? '';
  }

  void deleteSelected() {
    if (iBuuGui.value != -1) {
      buuGuis.removeAt(iBuuGui.value);
      for (int i = 0; i < buuGuis.length; i++) {
        buuGuis[i].index = i + 1;
      }
      _saveToFirebase();
      update();
    }
  }

  void deleteAll() {
    buuGuis.clear();
    _saveToFirebase();
    hdrIdText.value = "";
    hdrId = null;
    update();
  }

  void sendToPC() {
    if (iBuuGui.value == -1 || buuGuis.isEmpty) return;
    stateText.value = "Đang gửi thông tin";

    try {
      FirebaseManager().sendListBDToPortal(buuGuis.toList());

      Map<String, dynamic> messageData = {
        'maBG': buuGuis[iBuuGui.value].maBuuGui,
        'hdrId': hdrId ?? "",
        'isFirst': "true",
        'account': account,
        'password': password,
        'isDeletePhone': "true",
      };

      FirebaseManager().addMessage(MessageReceiveModel(
        "sendautokhoitao",
        jsonEncode(messageData),
      ));

      for (int i = buuGuis.length - 1; i >= iBuuGui.value; i--) {
        buuGuis[i].trangThaiRequest = null;
      }
      update();
    } catch (e) {
      stateText.value = "Lỗi gửi dữ liệu: $e";
      'Error in sendToPC: $e'.printInfo();
    }
  }

  void printAll() {
    if (buuGuis.isEmpty) return;
    List<String?> maHieus = buuGuis.map((buuGui) => buuGui.maBuuGui).toList();
    FirebaseManager()
        .addMessage(MessageReceiveModel("printMaHieus", jsonEncode(maHieus)));
  }

  Future<void> onListenNotification(MessageReceiveModel message) async {
    switch (message.Lenh) {
      case "checkstatemh":
        var splitText = message.DoiTuong.split("|");
        var bg = buuGuis
            .firstWhereOrNull((element) => element.maBuuGui == splitText[0]);
        bg?.trangThaiRequest = "Xong";
        bg?.money = splitText[1];
        _saveToFirebase();
        update();
        break;
      case "message":
      case "showdetailmessage":
      case "info":
      case "warning":
        stateText.value = message.DoiTuong;
        break;
      case "error":
        stateText.value = "❌ ${message.DoiTuong}";
        Get.snackbar(
          "Lỗi từ Extension",
          message.DoiTuong,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFD32F2F),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 5),
        );
        break;
      // case "messageContinue":
      //   stateText.value = message.DoiTuong;
      //   Get.defaultDialog(
      //     title: "Thông báo lỗi",
      //     content: Text("${message.DoiTuong}\nBạn có muốn tiếp tục?"),
      //     onConfirm: () {
      //       FirebaseManager().addMessage(
      //         MessageReceiveModel("continueAuto", message.DoiTuong),
      //       );
      //       stateText.value = "Đang tiếp tục...";
      //       Get.back();
      //     },
      //     onCancel: () {
      //       stateText.value = "Đã dừng tự động";
      //     },
      //   );
      //   break;
      case "printDone":
        stateText.value = "In xong";
        break;
      case "sendhdr":
        try {
          final data = jsonDecode(message.DoiTuong);
          hdrId = data['hdrId']?.toString();
          hdrIdText.value = hdrId ?? "";
          stateText.value = "Đã nhận HDR: ${hdrIdText.value}";
        } catch (e) {
          stateText.value = "Lỗi nhận HDR";
        }
        update();
        break;
    }
  }

  @override
  void onClose() {
    onListenBarcode?.cancel();
    try {
      mobileScannerController.dispose();
    } catch (e) {}
    textHintController.dispose();
    focusHint.dispose();
    _audioPlayer.dispose();
    WakelockPlus.disable();
    super.onClose();
  }
}
