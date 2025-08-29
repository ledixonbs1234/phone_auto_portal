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
          // Nếu tìm thấy, gán khối lượng
          bgTemp.khoiLuong = buuGuiFromKhachHang.khoiLuong;
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
