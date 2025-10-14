import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:phone_auto_portal/app/modules/createnew/model/dingoaistateinfo.dart';
import 'package:phone_auto_portal/app/modules/home/khach_hangs_model.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/dingoaicodes_model.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/portal_model.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/state_ma_hieu_model.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';
import 'package:phone_auto_portal/app/modules/createnew/model/contentchangeinfo.dart';

import '../../home/messageReceiveModel.dart';

class CreatenewController extends GetxController {
  final khachHang = KhachHangs().obs;
  String? hdrId; // Biến lưu hdrId lấy từ Firebase
  final hdrIdText = "".obs; // Biến observable để bind ra view
  final buuGuis = <BuuGuis>[].obs;
  final diNgoaiStates = <DiNgoaiStateInfo>[].obs;
  final isChangeKL = false.obs;
  final isNotCheckData = false.obs;
  final tenKH = "".obs;
  final isAutoWork = false.obs;
  final isDo = false.obs;
  final is1KG = false.obs;
  final isDeletePhone = true.obs;
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

  TextEditingController changeKLFromToController = TextEditingController();
  TextEditingController contentChangeController = TextEditingController();
  TextEditingController contentChangeKLController = TextEditingController();
  TextEditingController increaseKLController = TextEditingController();

  late FocusNode focusHint;
  final count = 0.obs;

  final selectedState = "CC".obs;

  var selectedOption = ''.obs;
  var changeKLFromTo = 0.obs;
  var contentChange = ''.obs;
  var contentChangeKL = 0.obs;
  var increaseKL = 0.obs;
  var useOptions = false.obs;

  // Mobile Scanner Controller
  late MobileScannerController mobileScannerController;
  StreamSubscription<BarcodeCapture>? onListenBarcode;
  final contentChanges = <ContentChangeInfo>[].obs;

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Biến cho quá trình lấy dữ liệu Portal
  var waitingForPortalData = false.obs;
  final tempPortals = <Portal>[].obs;

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
    // saveOptionsTest();

    loadOptions();

    // Chỉ tải danh sách bưu gửi nếu có khách hàng hợp lệ và không rỗng
    // Việc tải dữ liệu sẽ được thực hiện trong setUp() khi khách hàng được thiết lập
    printInfo(
        info:
            "CreatenewController onReady - Current customer: ${khachHang.value.maKH}");
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
          bgTemp.trangThai = khachHang.value.buuGuis!
              .firstWhere(
                  (element) => textMHController.text == element.maBuuGui)
              .trangThai;
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
      if (isAutoWork.value) {
        FirebaseManager().sendListScannedToPortal(buuGuis);
      }
    }
    buuGuis.sort((a, b) => a.index!.compareTo(b.index!));

    // Lưu danh sách bưu gửi cho khách hàng hiện tại
    saveBuuGuisForCurrentCustomer();

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

    // Lưu danh sách bưu gửi sau khi xóa
    saveBuuGuisForCurrentCustomer();

    refreshSussgest();
    update();
  }

  deleteAll() {
    buuGuis.clear();

    // Lưu danh sách trống cho khách hàng hiện tại
    saveBuuGuisForCurrentCustomer();

    hdrIdText.value = "";
    hdrId = null;
    if (isAutoWork.value) {
      FirebaseManager().sendListScannedToPortal([]);
    }
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
      if (buugui.trangThai == "Đang đi thu gom" ||
          buugui.trangThai == "Nhận hàng thành công" ||
          buugui.trangThai == "Đã phân hướng" ||
          buugui.trangThai == "Tạo đơn" ||
          buugui.trangThai == "Bưu tá nhận yêu cầu thu gom" ||
          buugui.trangThai == "Đã lấy hàng") {
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
      // int index = buuGuis.length;
      // for (var buuGui in buuGuis.toList()) {
      //   buuGui.index = index;
      //   index--;
      // }
    }
  }

  khoiTaoPortal() {
    stateText.value = "Đang khởi tạo";
    if (khachHang.value.maKH == "") {
      stateText.value = "Chưa chọn khách hàng";
      return;
    }
    FirebaseManager().addMessage(MessageReceiveModel(
        "khoitao",
        const JsonEncoder().convert({
          "maKH": khachHang.value.maKH,
          "account": account,
          "password": password,
          "isDeletePhone": isDeletePhone.value.toString()
        })));
  }

  String lastKH = "";

  void setUp(KhachHangs kh, String account, String password) {
    // if (kh.tenKH != khachHang.value.tenKH) {
    if (selectedState.value == "CC") {
      // Lưu danh sách bưu gửi của khách hàng trước đó (nếu có)
      if (khachHang.value.maKH != null && khachHang.value.maKH!.isNotEmpty) {
        saveBuuGuisForCurrentCustomer();
      }

      // Xóa danh sách bưu gửi hiện tại trước khi thiết lập khách hàng mới
      buuGuis.clear();

      khachHang.value = kh;
      tenKH.value = kh.tenKH!;
      if (lastKH != kh.tenKH) {
        lastKH = kh.tenKH!;
        isAutoWork.value = false;
        hdrIdText.value = "";
        hdrId = null;
      }
      this.account = account;
      this.password = password;

      // Tải danh sách bưu gửi đã lưu của khách hàng mới (chỉ sau khi đã set khách hàng mới)
      loadBuuGuisForCurrentCustomer();

      refreshSussgest();
      selectedState.value = "CC";
      loadOptions();
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
          buugui.trangThai == "Đã phân hướng" ||
          buugui.trangThai == "Tạo đơn" ||
          buugui.trangThai == "Bưu tá nhận yêu cầu thu gom" ||
          buugui.trangThai == "Đã lấy hàng") {
        count++;
      }
    }
    count -= buuGuis.length;
    opacityLevel.value = 0;
    return count;
  }

  String lastmaKH = "";

  void sendToPC() {
    printInfo(info: "Send to portal");
    if (iBuuGui.value == -1) {
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

    // Kiểm tra bưu gửi có khối lượng dưới 100g
    final under100gItems = buuGuis
        .where((bg) =>
            bg.khoiLuong != null && bg.khoiLuong! < 100 && bg.khoiLuong! > 0)
        .toList();

    if (under100gItems.isNotEmpty) {
      printInfo(
          info:
              "Found ${under100gItems.length} items under 100g, showing dialog");
      _showWeightModificationDialog(under100gItems, isFirst);
      return; // Dừng việc gửi cho đến khi người dùng xác nhận
    }

    _continueSendToPC(isFirst);
  }

  void _continueSendToPC(bool isFirst) {
    FirebaseManager().sendListBDToPortal(buuGuis);

    Map<String, dynamic> messageData = {
      'maKH': khachHang.value.maKH,
      'maBG': buuGuis[iBuuGui.value].maBuuGui,
      'hdrId': hdrId ?? "",
      'isFirst': isFirst.toString(),
      'account': account,
      'password': password,
      'isDeletePhone': isDeletePhone.value,
    };

    if (useOptions.value) {
      final options = {
        'selectedOption': selectedOption.value,
        'changeKLFromTo': changeKLFromTo.value,
        'increaseKL': increaseKL.value,
        'contentChanges': contentChanges
            .map((e) => {
                  'content': removeDiacritics(e.content.toLowerCase()),
                  'khoiLuong': e.khoiLuong
                })
            .toList(),
      };
      messageData['options'] = options;
    }

    FirebaseManager().addMessage(MessageReceiveModel(
      "sendautotoportal",
      jsonEncode(messageData),
    ));
    //Thực hiện xóa state từ vị trí iBuuGui.value đến cuối danh sách
    for (int i = buuGuis.length - 1; i >= iBuuGui.value; i--) {
      buuGuis[i].trangThaiRequest = null;
    }
    update();
  }

  Future<void> onListenNotification(MessageReceiveModel message) async {
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
      case "messageContinue":
        //nếu barcode đang mở thì thoát ra
        if (onListenBarcode != null) {
          await onListenBarcode!.cancel();
          onListenBarcode = null;
          await Future.delayed(
              const Duration(milliseconds: 1000)); // Tăng thời gian nếu cần
        }
        stateText.value = message.DoiTuong;
        //Hiện thông báo có muốn tiếp tục không
        Get.defaultDialog(
          title: "Thông báo",
          content: Text("${message.DoiTuong}\nBạn có muốn tiếp tục không?"),
          onConfirm: () {
            //Gửi yêu cầu tiếp tục
            FirebaseManager().addMessage(
                MessageReceiveModel("continueAuto", message.DoiTuong));
            Get.back();
          },
          onCancel: () {
            isAutoWork.value = false;
            stateText.value = "Đã dừng tự động";
          },
        );

        break;
      case "showdetailmessage":
        stateText.value = message.DoiTuong;
        break;
      case "printDone":
        stateText.value = "In xong";
        break;
      case "sendhdr":
        // Lấy dữ liệu hdrId từ message.DoiTuong (dạng JSON)
        try {
          final data = jsonDecode(message.DoiTuong);
          if (khachHang.value.maKH == data['maKH']) {
            hdrId = data['hdrId']?.toString();
            hdrIdText.value = hdrId ?? "";
          }
          // Nếu muốn cập nhật ra view, có thể dùng hdrIdText.value
          stateText.value = "Đã nhận HDR: ${hdrIdText.value}";
        } catch (e) {
          stateText.value = "Lỗi nhận HDR";
        }
        update();
        break;
      case "getMaHieus":
        // Xử lý khi nhận được mã hiệu từ Portal
        if (waitingForPortalData.value) {
          var codes = (jsonDecode(message.DoiTuong) as List)
              .map((element) => StateMaHieu.fromJson(element))
              .toList();

          printInfo(info: "CreateNew nhận được ${codes.length} mã hiệu");
          processMaHieusFromPortal(codes);
        }
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

  void addKhachHangAsQR() {
    try {
      printInfo(info: "Scan multi code");

      // Cancel any existing barcode listener
      onListenBarcode?.cancel();

      List<String> notMHs = [];

      // Khởi tạo mobile scanner controller
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
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          final String? code = barcode.rawValue;
          if (code != null && code.isNotEmpty) {
            String barcodeFilled = code.trim().toUpperCase();

            if (isValidMaHieu(barcodeFilled)) {
              await _handleValidBarcode(barcodeFilled, notMHs);
            }
          }
        }
      });

      // Hiển thị scanner dialog
      _showMobileScannerDialogForCreatenew();
    } on PlatformException {
      Get.snackbar("Thông báo", "Lỗi barcode");
    } catch (e) {
      Get.snackbar("Thông báo", "Lỗi khi khởi tạo scanner: ${e.toString()}");
    }
  }

  void _showMobileScannerDialogForCreatenew() {
    Get.dialog(
      Dialog(
        child: Container(
          width: 300,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Quét mã QR/Barcode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Obx(() => Text(
                    'Đã quét: ${buuGuis.length} bưu gửi',
                    style: const TextStyle(fontSize: 14),
                  )),
              const SizedBox(height: 16),
              Expanded(
                child: MobileScanner(
                  controller: mobileScannerController,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      onListenBarcode?.cancel();
                      mobileScannerController.dispose();
                      Get.back();
                    },
                    child: const Text('Dừng'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      mobileScannerController.toggleTorch();
                    },
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

  Future<void> _handleValidBarcode(
      String barcodeFilled, List<String> notMHs) async {
    if (!isNotCheckData.value) {
      if (susggestMHs.contains(barcodeFilled)) {
        await _processSuggestedBarcode(barcodeFilled, notMHs);
      } else if (buuGuis.any((element) => element.maBuuGui == barcodeFilled)) {
      } else if (!notMHs.contains(barcodeFilled)) {
        notMHs.add(barcodeFilled);
        await _playAudio("assets/kocobg.wav");
      } else {
        // await _playAudio("assets/kocobg.wav");
      }
    } else {
      if (!buuGuis.any((element) => element.maBuuGui == barcodeFilled)) {
        await _processSuggestedBarcode(barcodeFilled, notMHs);
      }
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
      // Sửa lại đoạn code gây lỗi:
      if (existingDiNgoais == null) {
        // Tìm bưu gửi trong danh sách khách hàng một cách an toàn
        final buuGuiFromKhachHang = khachHang.value.buuGuis
            ?.firstWhereOrNull((element) => barcodeFilled == element.maBuuGui);

        if (buuGuiFromKhachHang != null) {
          //nếu khối lượng là 10 thì thay đổi thành 3000
          if (buuGuiFromKhachHang.khoiLuong == 10) {
            buuGuiFromKhachHang.khoiLuong = 3000;
          } else {
            // Nếu tìm thấy, gán khối lượng
            bgTemp.khoiLuong = buuGuiFromKhachHang.khoiLuong;
          }
        } else {
          // Nếu KHÔNG tìm thấy, bạn phải quyết định làm gì
          // Ví dụ: Gán một giá trị mặc định hoặc báo lỗi
          bgTemp.khoiLuong = 0; // Gán mặc định là 0
          // Hoặc có thể bạn muốn dừng xử lý ở đây
          // await _playAudio("assets/error.wav");
          // return;
        }
      } else {
        bgTemp.khoiLuong = int.tryParse(existingDiNgoais.khoiLuong!) ?? 0;
      }
      var existingBG =
          buuGuis.firstWhereOrNull((m) => m.maBuuGui == barcodeFilled);

      final shouldAdd = existingDiNgoais == null ||
          existingDiNgoais.keyExactly == selectedState.value;

      if (shouldAdd && existingBG == null) {
        if (is1KG.value) {
          if (bgTemp.khoiLuong! < 2000) {
            await _playAudio("assets/hang_duoi_2kg.wav");
            return;
          }
        }
        susggestMHs.remove(barcodeFilled);
        HapticFeedback.lightImpact(); // Rung nhẹ để báo hiệu quét thành công
        buuGuis
          ..add(bgTemp)
          ..sort((a, b) => a.index!.compareTo(b.index!));
        if (isAutoWork.value) {
          FirebaseManager().sendListScannedToPortal(buuGuis);
        }

        // Lưu danh sách bưu gửi sau khi thêm mới
        saveBuuGuisForCurrentCustomer();

        update();

        final length = buuGuis.length;
        final audioPath =
            length < 100 ? "assets/$length.wav" : "assets/beep.mp3";
        await _playAudio(audioPath);
      } else {
        if (existingBG == null) {
          await _playAudio("assets/lachuong.mp3");
        } else {
          //nếu vị trí tồn tại bg nhỏ hơn vị trí cuối cùng trừ 5 thì phát âm thanh trùng đơn
          if (existingBG.index! < buuGuis.length - 5) {
            await _playAudio("assets/trungdon.wav");
          }
        }
      }
    } else {
      if (existingDiNgoais == null) {
        await _playAudio("assets/kocobg.mp3");
      }
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      await _audioPlayer.setAsset(path);
      await _audioPlayer.play();
    } catch (e) {
      // Ignore audio errors
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
    // 1. Kiểm tra nhanh nếu danh sách gốc trống
    if (buuGuis.isEmpty) {
      FirebaseManager().showSnackBar(
        "Danh sách bưu gửi trống. Vui lòng thêm bưu gửi trước.",
      );
      return;
    }

    // 2. Lọc danh sách: Chỉ giữ lại những bưu gửi có trạng thái
    //    KHÁC 'nhận hàng thành công' (không phân biệt hoa thường)
    final List<BuuGuis> buuGuisCanHoanTat = buuGuis.where((buuGui) {
      // Lấy trạng thái, chuyển về chữ thường, nếu null thì coi như ''
      final trangThaiLower = buuGui.trangThai?.toLowerCase() ?? '';
      // Giữ lại nếu trạng thái KHÔNG PHẢI là 'nhận hàng thành công'
      return trangThaiLower != 'nhận hàng thành công';
    }).toList(); // Chuyển kết quả lọc thành List

    // 3. Kiểm tra xem danh sách sau khi lọc có trống không
    if (buuGuisCanHoanTat.isEmpty) {
      // Hiển thị thông báo cho người dùng
      FirebaseManager().showSnackBar(
        "Tất cả bưu gửi đều đã nhận hàng thành công.",
      );
      return; // Thoát khỏi hàm
    }

    // 4. Nếu danh sách lọc không trống, lấy danh sách maHieu từ danh sách đã lọc
    List<String?> maHieus = buuGuisCanHoanTat
        .map((buuGui) => buuGui.maBuuGui) // Chỉ lấy maBuuGui
        .toList();

    // 5. Gửi danh sách maHieu đã lọc lên Firebase
    try {
      FirebaseManager().addMessage(
        MessageReceiveModel("hoanTatTin", jsonEncode(maHieus)),
      );
      FirebaseManager().showSnackBar(
        "Đã gửi yêu cầu hoàn tất cho ${maHieus.length} bưu gửi.",
      );
    } catch (e) {
      // Xử lý lỗi nếu có trong quá trình encode hoặc gửi
      FirebaseManager().showSnackBar(
        "Lỗi khi gửi yêu cầu hoàn tất: ${e.toString()}",
      );
    }
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
    // Bước 1: Bắt đầu lấy dữ liệu Portal
    waitingForPortalData.value = true;
    stateText.value = "Đang lấy dữ liệu Portal...";

    // Bước 2: Gọi refreshPortal với time = Now
    await FirebaseManager().refreshPortal(DateTime.now());

    // Chờ một chút để dữ liệu được cập nhật
    await Future.delayed(const Duration(seconds: 2));

    // Bước 3: Lọc Portal theo maKH
    final targetMaKHs = ["C002446626", "C015304312"];
    final filteredPortals = tempPortals.where((portal) {
      return targetMaKHs.contains(portal.maKH);
    }).toList();

    if (filteredPortals.isEmpty) {
      stateText.value = "Không tìm thấy Portal phù hợp";
      waitingForPortalData.value = false;
      return;
    }

    // Bước 4: Lấy danh sách ID
    final ids = filteredPortals.map((portal) => portal.id).toList();

    printInfo(info: "Đã lọc được ${ids.length} portal: $ids");
    stateText.value = "Đang lấy mã hiệu từ ${ids.length} portal...";

    // Bước 5: Gọi getMaHieus
    FirebaseManager()
        .addMessage(MessageReceiveModel("getMaHieus", jsonEncode(ids)));

    // waitingCodes sẽ được set để xử lý trong onListenNotification
    // (Sẽ thêm logic xử lý ở phần sau)
  }

  /// Xử lý dữ liệu Portal khi được cập nhật từ Firebase
  void onPortalDataUpdated(List<Portal> portals) {
    if (!waitingForPortalData.value) {
      return; // Không xử lý nếu không đang chờ
    }

    tempPortals.value = portals;
    printInfo(info: "CreateNew nhận được ${portals.length} portal từ Firebase");
  }

  /// Xử lý mã hiệu sau khi lấy từ Portal
  void processMaHieusFromPortal(List<StateMaHieu> codes) {
    printInfo(info: "Nhận được ${codes.length} mã hiệu từ Portal");

    // Load dữ liệu tỉnh thành để phân loại
    _loadProvinceDataAndClassify(codes);
  }

  /// Loại bỏ dấu tiếng Việt từ chuỗi
  String _removeDiacritics(String str) {
    var withDia =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    var withoutDia =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiioooooooooooooooooouuuuuuuuuuuyyyyyd';

    var result = str.toLowerCase();
    for (var i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }

  /// Kiểm tra xem địa chỉ có chứa địa danh đặc biệt của Bình Định không
  bool _isBinhDinhSpecialLocation(String? address) {
    if (address == null || address.isEmpty) return false;

    final normalizedAddress = _removeDiacritics(address);
    final specialLocations = [
      'hoai nhon',
      'tam quan',
      'hoai an',
      'an lao',
      'an hao',
      'an my',
      'binh duong',
      'phu my',
      'phu cat'
    ];

    for (final location in specialLocations) {
      if (normalizedAddress.contains(location)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadProvinceDataAndClassify(List<StateMaHieu> codes) async {
    try {
      // Load dữ liệu tỉnh thành từ JSON
      final String jsonString =
          await rootBundle.loadString('assets/tinhthanh.json');
      final provinceData = jsonDecode(jsonString);

      // Lấy mã tỉnh cho từng hướng
      final Set<String> namTrungBoCodes = <String>{};
      final Set<String> daNangCodes = <String>{};

      // Xử lý Nam Trung Bộ (VÔ)
      if (provinceData['vo'] != null) {
        for (final province in provinceData['vo']) {
          if (province['ma_tinh'] != null) {
            for (final code in province['ma_tinh']) {
              namTrungBoCodes.add(code.toString());
            }
          }
        }
      }

      // Xử lý Đà Nẵng (RA)
      if (provinceData['ra'] != null) {
        for (final province in provinceData['ra']) {
          if (province['ma_tinh'] != null) {
            for (final code in province['ma_tinh']) {
              daNangCodes.add(code.toString());
            }
          }
        }
      }

      // Phân loại mã hiệu
      final namTrungBoList = <DiNgoaiStateInfo>[];
      final daNangList = <DiNgoaiStateInfo>[];
      final conLaiList = <DiNgoaiStateInfo>[];

      for (final code in codes) {
        final provinceCode = code.provinceCode?.trim() ?? '';
        final diNgoaiState = DiNgoaiStateInfo(
          maHieu: code.code,
          khoiLuong: code.Weight,
          maBuuCucNhan: provinceCode,
          address: code.Address,
        );

        if (namTrungBoCodes.contains(provinceCode)) {
          // Kiểm tra trường hợp đặc biệt: Bình Định (mã 55) với địa danh đặc biệt
          if (provinceCode == '55' &&
              _isBinhDinhSpecialLocation(code.Address)) {
            // Chuyển sang Còn Lại nếu là địa danh đặc biệt của Bình Định
            diNgoaiState.keyExactly = "Còn Lại";
            conLaiList.add(diNgoaiState);
          } else {
            // Các trường hợp Nam Trung Bộ bình thường
            diNgoaiState.keyExactly = "Nam Trung Bộ";
            namTrungBoList.add(diNgoaiState);
          }
        } else if (daNangCodes.contains(provinceCode)) {
          diNgoaiState.keyExactly = "Đà Nẵng";
          daNangList.add(diNgoaiState);
        } else {
          diNgoaiState.keyExactly = "Còn Lại";
          conLaiList.add(diNgoaiState);
        }
      }

      // Lọc theo lựa chọn của user
      List<DiNgoaiStateInfo> filteredList = [];
      String selectedLabel = "";

      switch (selectedState.value) {
        case "NTB":
          filteredList = namTrungBoList;
          selectedLabel = "Nam Trung Bộ";
          break;
        case "DN":
          filteredList = daNangList;
          selectedLabel = "Đà Nẵng";
          break;
        case "CL":
          filteredList = conLaiList;
          selectedLabel = "Còn Lại";
          break;
        default:
          // Nếu "CC" (Chưa Chọn) hoặc giá trị khác, hiển thị tất cả
          filteredList = [...namTrungBoList, ...daNangList, ...conLaiList];
          selectedLabel = "Tất cả";
      }

      // Cập nhật dữ liệu với danh sách đã lọc
      diNgoaiStates.value = filteredList;

      // Cập nhật gợi ý
      susggestMHs.clear();
      for (var diNgoai in diNgoaiStates) {
        susggestMHs.add(diNgoai.maHieu!);
      }

      tenKH.value = "Lấy hàng Lẻ";
      waitingForPortalData.value = false;

      stateText.value = "Đã lọc $selectedLabel: ${filteredList.length} mã hiệu "
          "(Tổng: NTB=${namTrungBoList.length}, DN=${daNangList.length}, CL=${conLaiList.length})";

      update();

      printInfo(
          info: "Đã lọc $selectedLabel: ${filteredList.length} mã hiệu - "
              "Phân loại: Nam Trung Bộ=${namTrungBoList.length}, "
              "Đà Nẵng=${daNangList.length}, Còn lại=${conLaiList.length}");
    } catch (e) {
      printInfo(info: "Lỗi khi load dữ liệu tỉnh thành: $e");
      stateText.value = "Lỗi khi phân loại hướng";
      waitingForPortalData.value = false;
    }
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
    await FirebaseManager().deleteBuuGuis(buuGuis);
    if (susggestMHs.isEmpty) {
      _playAudio("assets/dusoluong.wav");
    }
  }

  void showAll() {
    for (var diNgoaiS in diNgoaiStates) {
      var bgTemp = BuuGuis(
        index: buuGuis.length + 1,
        maBuuGui: diNgoaiS.maHieu,
      );
      bgTemp.khoiLuong = int.tryParse(diNgoaiS.khoiLuong!) ?? 0;
      buuGuis
        ..add(bgTemp)
        ..sort((a, b) => b.index!.compareTo(a.index!));
    }
    update();
  }

  void saveOptions() {
    final options = {
      'selectedOption': selectedOption.value,
      'changeKLFromTo': changeKLFromTo.value,
      'increaseKL': increaseKL.value,
      'useOptions': useOptions.value,
      'contentChanges': contentChanges
          .map((e) => {'content': e.content, 'khoiLuong': e.khoiLuong})
          .toList(),
    };
    GetStorage().write('options_${khachHang.value.maKH}', options);
    //update useOptions from getx
  }

  void loadOptions() {
    final options = GetStorage()
        .read<Map<String, dynamic>>('options_${khachHang.value.maKH}');
    selectedOption.value = options?['selectedOption'] ?? '';
    changeKLFromTo.value = options?['changeKLFromTo'] ?? 0;
    increaseKL.value = options?['increaseKL'] ?? 0;
    useOptions.value = options?['useOptions'] ?? false;

    changeKLFromToController.text = changeKLFromTo.value.toString();
    contentChangeController.text = contentChange.value;
    contentChangeKLController.text = contentChangeKL.value.toString();
    increaseKLController.text = increaseKL.value.toString();

    final contentChangesList =
        options?['contentChanges'] as List<dynamic>? ?? [];
    contentChanges.value = contentChangesList
        .map((e) =>
            ContentChangeInfo(content: e['content'], khoiLuong: e['khoiLuong']))
        .toList();
  }

  void addContentChange() {
    final content = contentChangeController.text;
    final khoiLuong = int.tryParse(contentChangeKLController.text) ?? 0;
    contentChanges
        .add(ContentChangeInfo(content: content, khoiLuong: khoiLuong));
    contentChangeController.clear();
    contentChangeKLController.clear();
  }

  autoWork() {
    stateText.value = "Đang tự động tạo và gửi bưu gửi";
    Map<String, dynamic> messageData = {
      'maKH': khachHang.value.maKH,
      'account': account,
      'password': password,
      'isDeletePhone': isDeletePhone.value.toString(),
    };

    if (useOptions.value) {
      final options = {
        'selectedOption': selectedOption.value,
        'changeKLFromTo': changeKLFromTo.value,
        'increaseKL': increaseKL.value,
        'contentChanges': contentChanges
            .map((e) => {
                  'content': removeDiacritics(e.content.toLowerCase()),
                  'khoiLuong': e.khoiLuong
                })
            .toList(),
      };
      messageData['options'] = options;
    }

    FirebaseManager().addMessage(MessageReceiveModel(
      "savekhoptions",
      jsonEncode(messageData),
    ));
  }

  void sendEndAndPrint() {
    FirebaseManager().addMessage(MessageReceiveModel(
      "sendtoendandprint",
      "",
    ));
  }

  /// Lưu danh sách bưu gửi của khách hàng hiện tại vào GetStorage
  void saveBuuGuisForCurrentCustomer() {
    if (khachHang.value.maKH != null && khachHang.value.maKH!.isNotEmpty) {
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

      final String storageKey = 'buuGuis_${khachHang.value.maKH}';
      GetStorage().write(storageKey, buuGuisData);

      printInfo(
          info:
              "Saved ${buuGuis.length} buuGuis for customer: ${khachHang.value.maKH} - ${khachHang.value.tenKH}");
    } else {
      printInfo(info: "Cannot save buuGuis: No customer selected");
    }
  }

  /// Tải danh sách bưu gửi đã lưu của khách hàng hiện tại từ GetStorage
  void loadBuuGuisForCurrentCustomer() {
    if (khachHang.value.maKH != null && khachHang.value.maKH!.isNotEmpty) {
      final String storageKey = 'buuGuis_${khachHang.value.maKH}';
      final savedData = GetStorage().read<List<dynamic>>(storageKey);

      printInfo(
          info:
              "Loading buuGuis for customer: ${khachHang.value.maKH} - ${khachHang.value.tenKH}");

      if (savedData != null && savedData.isNotEmpty) {
        printInfo(
            info:
                "Found ${savedData.length} saved buuGuis for customer ${khachHang.value.maKH}");

        // Đảm bảo xóa danh sách cũ trước khi tải dữ liệu mới
        buuGuis.clear();

        for (var item in savedData) {
          final bg = BuuGuis(
            index: item['index'],
            maBuuGui: item['maBuuGui'],
          );

          bg.khoiLuong = item['khoiLuong'];
          bg.trangThai = item['trangThai'];
          bg.trangThaiRequest = item['trangThaiRequest'];
          bg.money = item['money'];

          if (item['listDo'] != null) {
            bg.listDo = List<String>.from(item['listDo']);
          }

          buuGuis.add(bg);
        }

        // Sắp xếp lại theo index
        buuGuis.sort((a, b) => a.index!.compareTo(b.index!));
        printInfo(
            info:
                "Successfully loaded ${buuGuis.length} buuGuis for customer ${khachHang.value.maKH}");
        update();
      } else {
        printInfo(
            info:
                "No saved buuGuis found for customer ${khachHang.value.maKH}");
        // Đảm bảo danh sách trống nếu không có dữ liệu đã lưu
        buuGuis.clear();
        update();
      }
    } else {
      printInfo(info: "No customer selected, clearing buuGuis list");
      buuGuis.clear();
      update();
    }
  }

  /// Xóa danh sách bưu gửi đã lưu của khách hàng cụ thể
  void clearSavedBuuGuisForCustomer(String maKH) {
    GetStorage().remove('buuGuis_$maKH');
  }

  /// Xóa tất cả dữ liệu bưu gửi đã lưu của tất cả khách hàng
  void clearAllSavedBuuGuis() {
    final storage = GetStorage();
    final keys = storage.getKeys();

    for (String key in keys) {
      if (key.startsWith('buuGuis_')) {
        storage.remove(key);
      }
    }
  }

  void _showWeightModificationDialog(
      List<BuuGuis> under100gItems, bool isFirst) {
    Get.dialog(
      _WeightModificationDialog(
        under100gItems: under100gItems,
        onConfirm: (updatedItems) {
          // Cập nhật khối lượng cho các items
          for (int i = 0; i < under100gItems.length; i++) {
            if (updatedItems.containsKey(i)) {
              final newWeight = updatedItems[i];
              if (newWeight != null && newWeight > 0) {
                printInfo(
                    info:
                        "Updating ${under100gItems[i].maBuuGui} weight from ${under100gItems[i].khoiLuong} to $newWeight");
                under100gItems[i].khoiLuong = newWeight;
              }
            }
          }

          printInfo(info: "User confirmed weight changes, continuing to send");
          Get.back(); // Đóng dialog
          _continueSendToPC(isFirst); // Tiếp tục gửi
        },
        onCancel: () {
          printInfo(
              info: "User chose not to change weights, continuing to send");
          Get.back(); // Đóng dialog
          _continueSendToPC(isFirst); // Tiếp tục gửi mà không thay đổi
        },
      ),
      barrierDismissible: false,
    );
  }

  @override
  void onClose() {
    // Lưu danh sách bưu gửi trước khi đóng controller
    saveBuuGuisForCurrentCustomer();

    onListenBarcode?.cancel();
    try {
      mobileScannerController.dispose();
    } catch (e) {
      // Controller might not be initialized
    }
    _audioPlayer.dispose();
    super.onClose();
  }
}

class _WeightModificationDialog extends StatefulWidget {
  final List<BuuGuis> under100gItems;
  final Function(Map<int, int>) onConfirm;
  final VoidCallback onCancel;

  const _WeightModificationDialog({
    required this.under100gItems,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  _WeightModificationDialogState createState() =>
      _WeightModificationDialogState();
}

class _WeightModificationDialogState extends State<_WeightModificationDialog> {
  late List<TextEditingController> weightControllers;
  final Map<int, int> updatedWeights = {};

  @override
  void initState() {
    super.initState();
    weightControllers = [];

    // Tạo controller cho mỗi item dưới 100g
    for (int i = 0; i < widget.under100gItems.length; i++) {
      final controller = TextEditingController(
          text: widget.under100gItems[i].khoiLuong?.toString() ?? "");
      weightControllers.add(controller);

      // Lưu trữ giá trị ban đầu
      if (widget.under100gItems[i].khoiLuong != null) {
        updatedWeights[i] = widget.under100gItems[i].khoiLuong!;
      }
    }
  }

  @override
  void dispose() {
    // Dispose tất cả controllers khi widget bị dispose
    for (var controller in weightControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header với icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.scale,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Thông báo khối lượng",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Bạn có ${widget.under100gItems.length} bưu gửi dưới 100g",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tiêu đề bảng
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Mã bưu gửi",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "KL hiện tại (g)",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "KL mới (g)",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Danh sách bưu gửi
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.under100gItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.under100gItems[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.maBuuGui ?? "",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Text(
                                "${item.khoiLuong ?? 0}",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: weightControllers[index],
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                final newWeight = int.tryParse(value);
                                if (newWeight != null && newWeight > 0) {
                                  updatedWeights[index] = newWeight;
                                } else {
                                  updatedWeights.remove(index);
                                }
                              },
                              decoration: InputDecoration(
                                hintText: "Nhập KL",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                      color: Colors.blue, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    child: const Text(
                      "Không thay đổi",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onConfirm(updatedWeights),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Xác nhận thay đổi",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String removeDiacritics(String str) {
  const withDiacritics =
      'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ';
  const withoutDiacritics =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  for (int i = 0; i < withDiacritics.length; i++) {
    str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
  }
  return str;
}
