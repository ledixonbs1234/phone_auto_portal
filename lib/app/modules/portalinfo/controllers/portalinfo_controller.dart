import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart'; // Import material.dart
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/createnew/controllers/createnew_controller.dart';
import 'package:phone_auto_portal/app/modules/edit_page/controllers/edit_page_controller.dart';

import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';

import 'package:phone_auto_portal/app/modules/portalinfo/dingoaicodes_model.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/portal_check_model.dart';

import 'package:phone_auto_portal/app/modules/portalinfo/portal_model.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/split_address.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/state_ma_hieu_model.dart';
import 'package:phone_auto_portal/app/routes/app_pages.dart';

import 'package:phone_auto_portal/data/firebaseManager.dart';

class PortalinfoController extends GetxController {
  final portals = <Portal>[].obs;
  final currentMaHieusInPortal = <StateMaHieu>[].obs;

  final iPotal = 0.obs;

  final maychus = <String>["maychu", "mayphu", "mayphusan", "maytest"].obs;

  final selectedMayChu = "maychu".obs;

  bool isAutoRunBD = false;
  final isShowEdit = false.obs;

  final stateText = "".obs;

  final isSortDiNgoai = false.obs;

  final countPortalSelected = 0.obs;

  final isPrinted = true.obs;

  var waitingCodes = "";

  final selectedDate = DateTime.now().obs;

  // Barcode scanning functionality
  final TextEditingController barcodeInputController = TextEditingController();
  final isScanning = false.obs;
  final isScanSectionVisible = false.obs;
  final Set<String> _scannedBarcodes =
      <String>{}; // Track unique barcodes during scanning session

  // --- START: LOGIC MỚI CHO DIALOG ---
  final selectedDialogItemCount = 0.obs;
  StreamSubscription? _barcodeSubscription;

  bool get isAnyItemSelectedInDialog =>
      currentMaHieusInPortal.any((item) => item.selected);

  void toggleItemSelectedInDialog(StateMaHieu item) {
    item.selected = !item.selected;
    _updateSelectedDialogItemCount(); // <<< THÊM DÒNG NÀY
    update(); // Cập nhật UI để hiển thị/ẩn nút xóa và thay đổi màu
  }

  void _updateSelectedDialogItemCount() {
    selectedDialogItemCount.value =
        currentMaHieusInPortal.where((item) => item.selected).length;
  }

  void startBulkQRScanInDialog() {
    _barcodeSubscription?.cancel(); // Hủy stream cũ nếu có

    _barcodeSubscription = FlutterBarcodeScanner.getBarcodeStreamReceiver(
            '#ff6666', 'Xong', true, ScanMode.QR)
        ?.listen((barcode) {
      if (barcode is String && barcode != '-1') {
        final item = currentMaHieusInPortal
            .firstWhereOrNull((element) => element.code == barcode);

        if (item != null) {
          if (!item.selected) {
            item.selected = true;
            HapticFeedback
                .lightImpact(); // Rung nhẹ để báo hiệu quét thành công
            _updateSelectedDialogItemCount();
            update(); // Cập nhật UI
          }
        } else {
          // Có thể thêm âm báo lỗi ở đây nếu muốn
        }
      }
    });
  }

  void cancelBulkQRScanInDialog() {
    _barcodeSubscription?.cancel();
    _barcodeSubscription = null;
  }

  void deleteSelectedBGs() {
    final itemsToDelete =
        currentMaHieusInPortal.where((item) => item.selected).toList();
    if (itemsToDelete.isEmpty) {
      Get.snackbar("Thông báo", "Chưa có bưu gửi nào được chọn để xóa.");
      return;
    }

    final idCodesToDelete = itemsToDelete.map((item) => item.IDCODE!).toList();
    printInfo(info: "Yêu cầu xóa nhiều bưu gửi: $idCodesToDelete");

    // Gửi yêu cầu xóa hàng loạt lên Firebase
    FirebaseManager().addMessage(
        MessageReceiveModel("xoanhieubg", jsonEncode(idCodesToDelete)));

    // Cập nhật UI ngay lập tức
    currentMaHieusInPortal.removeWhere((item) => item.selected);
    _updateSelectedDialogItemCount();
    update();

    Get.snackbar(
        "Thành công", "Đã gửi yêu cầu xóa ${itemsToDelete.length} bưu gửi.");
  }

  // --- END: LOGIC MỚI CHO DIALOG ---

  /// Scans barcodes continuously using the device camera
  /// Supports multiple barcode scanning with duplicate prevention
  /// Automatically converts to uppercase and joins with commas
  Future<void> scanBarcode() async {
    try {
      isScanning.value = true;
      _scannedBarcodes.clear(); // Clear previous session
      barcodeInputController.clear(); // Clear input field

      // Start continuous scanning using getBarcodeStreamReceiver
      _barcodeSubscription?.cancel(); // Cancel any existing subscription

      _barcodeSubscription = FlutterBarcodeScanner.getBarcodeStreamReceiver(
        '#ff6666', // Color for scan line
        'Hoàn thành', // Cancel button text
        true, // Show flash icon
        ScanMode.DEFAULT, // Scan mode
      )?.listen((barcode) {
        if (barcode is String && barcode != '-1') {
          _processScanResult(barcode);
        }
      }, onDone: () {
        // Called when user cancels/exits scanning
        _onScanningComplete();
      }, onError: (error) {
        Get.snackbar(
          'Lỗi quét mã',
          'Lỗi trong quá trình quét: ${error.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isScanning.value = false;
      });

      // Show initial scanning message
      Get.snackbar(
        'Quét mã liên tục',
        'Quét nhiều mã barcode. Nhấn "Hoàn thành" để kết thúc.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi quét mã',
        'Không thể khởi động quét mã: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isScanning.value = false;
    }
  }

  /// Processes individual scan results during continuous scanning
  void _processScanResult(String barcode) {
    // Convert to uppercase and trim whitespace
    String processedBarcode = barcode.trim().toUpperCase();

    if (processedBarcode.isEmpty) return;

    // Check for duplicates
    if (_scannedBarcodes.contains(processedBarcode)) {
      // Show brief feedback for duplicate
      return;
    }

    // Add to unique set
    _scannedBarcodes.add(processedBarcode);

    // Update input field with comma-separated list
    barcodeInputController.text = _scannedBarcodes.join(',');

    // Provide haptic feedback for successful scan
    HapticFeedback.mediumImpact();

    // Optional: Show brief success indicator
    if (_scannedBarcodes.length % 5 == 0) {
      Get.snackbar(
        'Quét thành công',
        'Đã quét ${_scannedBarcodes.length} mã',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    }
  }

  /// Called when continuous scanning is completed (user cancels/exits)
  void _onScanningComplete() {
    isScanning.value = false;
    _barcodeSubscription?.cancel();

    if (_scannedBarcodes.isNotEmpty) {
      String scannedCodesString = _scannedBarcodes.join(',');
      barcodeInputController.text = scannedCodesString;

      Get.snackbar(
        'Quét hoàn thành',
        'Đã quét ${_scannedBarcodes.length} mã. Đang cập nhật dữ liệu...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Trigger refreshPortal with scanned barcodes
      refreshPortal(null);
    } else {
      Get.snackbar(
        'Quét hủy',
        'Không có mã nào được quét',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    }
  }

  /// Manually stops continuous scanning
  void stopScanning() {
    if (isScanning.value) {
      _onScanningComplete();
    }
  }

  /// Toggles the visibility of the barcode scanning section
  void toggleScanSection() {
    isScanSectionVisible.value = !isScanSectionVisible.value;
    // Clear input when hiding the section
    if (!isScanSectionVisible.value) {
      barcodeInputController.clear();
    }
  }

  @override
  void onClose() {
    barcodeInputController.dispose();
    _barcodeSubscription?.cancel(); // Cancel continuous scanning subscription
    cancelBulkQRScanInDialog();
    super.onClose();
  }

  Future<void> refreshPortal(DateTime? time) async {
    await FirebaseManager()
        .refreshPortal(time, maHieus: barcodeInputController.text);

    if (barcodeInputController.text.isNotEmpty) {
      stateText.value =
          "Đang cập nhật dữ liệu với ${barcodeInputController.text.split(',').length} mã đã quét";
    } else {
      stateText.value = "Đang cập nhật dữ liệu";
    }
  }

  List<Portal> getSelectedsPortal() {
    return portals.where((element) => element.selected).toList();
  }

  List<String?> getSelectedsIdPortal() {
    return getSelectedsPortal().map((e) => e.id).toList();
  }

  xacNhansPortal() {
    isAutoRunBD = false;

    List<String?> selecteds = getSelectedsIdPortal();
    if (selecteds.isNotEmpty) {
      FirebaseManager().addMessage(
          MessageReceiveModel("xacnhanportal", jsonEncode(selecteds)));
    }
  }

  sendDiNgoai() {
    isAutoRunBD = false;

    List<String?> selecteds = getSelectedsIdPortal();
    if (selecteds.isNotEmpty) {
      waitingCodes = "DONGDINGOAI";

      FirebaseManager()
          .addMessage(MessageReceiveModel("getMaHieus", jsonEncode(selecteds)));
    }
  }

  test() {
    FirebaseManager().addMessage(MessageReceiveModel("test", ""));
  }

  Future<void> printPageSelected() async {
    stateText.value = "Đang chuẩn bị In";
    List<String?> selecteds = getSelectedsIdPortal();

    if (selecteds.isNotEmpty) {
      FirebaseManager().addMessage(
          MessageReceiveModel("printSortTinhVaNoiDung", jsonEncode(selecteds)));
    }
  }

  Future<void> printPageSelectedAndSort() async {
    stateText.value = "Đang chuẩn bị In";
    List<String?> selecteds = getSelectedsIdPortal();

    if (selecteds.isNotEmpty) {
      FirebaseManager().addMessage(
          MessageReceiveModel("printPageSort", jsonEncode(selecteds)));
    }
  }

  void onListenNotification(MessageReceiveModel message) {
    if (message.Lenh == "getMaHieus") {
      var codes = (jsonDecode(message.DoiTuong) as List)
          .map((element) => StateMaHieu.fromJson(element))
          .toList();
      switch (waitingCodes) {
        case "DONGDINGOAI":
          waitingCodes = "";
          stateText.value = "Đang gửi đi ngoài tới PC ${selectedMayChu.value}";
          List<String> maHieus = codes.map((e) => e.code!).toList();
          //codeids
          List<String> codeIDs = codes.map((e) => e.IDCODE!).toList();

          FirebaseManager().addMessageToAppBD(
              selectedMayChu.value,
              MessageReceiveModel(
                  "dongdingoai",
                  jsonEncode(Dingoaicodes(
                      codes: maHieus,
                      codeIDs: codeIDs,
                      isAutoBD: isAutoRunBD,
                      isSorted: isSortDiNgoai.value,
                      isPrinted: isPrinted.value)),
                  nameMay: FirebaseManager().keyData!));
          break;
        case "XACNHANPORTAL":
          break;
        case "WAITINGCHECKDINGOAI":
          waitingCodes = "";
          stateText.value =
              "Đang gửi dữ liệu Check tới PC ${selectedMayChu.value}";
          List<String> maHieus = codes.map((e) => e.code!).toList();
          //codeids
          List<String> codeIDs = codes.map((e) => e.IDCODE!).toList();

          FirebaseManager().addMessageToAppBD(
              selectedMayChu.value,
              MessageReceiveModel(
                  "checkdingoais",
                  jsonEncode(Dingoaicodes(
                      codes: maHieus,
                      codeIDs: codeIDs,
                      isAutoBD: isAutoRunBD,
                      isSorted: isSortDiNgoai.value,
                      isPrinted: isPrinted.value)),
                  nameMay: FirebaseManager().keyData!));
          break;
        case "SPLITADDRESS":
          waitingCodes = "";
          stateText.value = "Đã lấy được mã hiệu và đang gửi";
          List<String> maHieus = codes.map((e) => e.code!).toList();
          //codeids
          var splits = codes.map<SplitAddress>((e) {
            return SplitAddress(e.code!, e.Address!, e.Name!);
          }).toList();
          var textSplit = jsonEncode(splits);

          FirebaseManager().addMessageToAppBD(
              selectedMayChu.value,
              MessageReceiveModel("splitAddress", textSplit,
                  nameMay: FirebaseManager().keyData!));
          break;
        case "CHECKMAHIEUDINGOAI":
          waitingCodes = "";
          //khi co danh sach gom mahieu va id kem theo thong tin Trang thai
          //gui codes to pc de check trang thai
          var checkInfo = (jsonDecode(message.DoiTuong) as List)
              .map((element) => PortalCheck.fromJson(element))
              .toList();
          //tao newcheckInfo voi trong list có ID giống nhau thì chỉ lấy PortalCheck đầu tiên
          var newCheckInfo = <PortalCheck>[];
          for (var check in checkInfo) {
            if (!newCheckInfo.any((element) => element.iD == check.iD)) {
              newCheckInfo.add(check);
            }
          }

          FirebaseManager().addMessageToAppBD(
              selectedMayChu.value,
              MessageReceiveModel("checkstateportal", jsonEncode(newCheckInfo),
                  nameMay: FirebaseManager().keyData!));
          break;
        case "CHECKCREATENEW":
          waitingCodes = "";
          var khoitao = Get.find<CreatenewController>();
          khoitao.syncCodes(codes);
          Get.toNamed(Routes.CREATENEW);
          break;
        case "SENDTEST":
          waitingCodes = "";
          List<String?> selecteds = codes.map((e) => e.code).toList();
          if (selecteds.isNotEmpty) {
            FirebaseManager().addMessage(MessageReceiveModel(
                "printMaHieusToFile", jsonEncode(selecteds)));
          }
          break;

        case "TOSHOW":
          waitingCodes = "";
          currentMaHieusInPortal.value = codes;
          isShowEdit.value = true;
          update();
          break;

        default:
      }
    } else if (message.Lenh == "message") {
      stateText.value = message.DoiTuong;
    } else if (message.Lenh == "showNotification") {
      stateText.value = message.DoiTuong;

      sendNotification();
    } else if (message.Lenh == "checkstateportal") {
      var codes = (jsonDecode(message.DoiTuong) as List)
          .map((element) => PortalCheck.fromJson(element))
          .toList();
      for (var portal in portals) {
        // kiểm tra số lượng codes có ID và State = true
        var countSame = codes
            .where((element) => element.iD == portal.id && element.isDongCT!)
            .toList();
        if (countSame[0].isDongCT!) {
          portal.isXuLyDiNgoai = true;
        }
      }
      update();

      FirebaseManager().showSnackBar("Cập nhật trạng thái thành công");
    } else if (message.Lenh == "printDone") {
      stateText.value = "In xong";
    }
  }

  void sendNotification() {
    AwesomeNotifications().isNotificationAllowed().then((value) {
      if (!value) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: 1,
      channelKey: "test",
      title: 'Lỗi',
      body: 'Có lỗi xảy ra khi chạy tự động bắn BĐ',
    ));
  }

  // --- HÀM MỚI: Xử lý xóa BG ---
  void deleteBG(StateMaHieu itemToDelete) {
    printInfo(info: "Yêu cầu xóa ${itemToDelete.IDCODE!}");
    // 1. Thực hiện logic xóa thực tế (API call, cập nhật DB,...)
    // ... (Thêm logic xóa của bạn ở đây) ...
    FirebaseManager().addMessage(
        MessageReceiveModel("xoabg", jsonEncode(itemToDelete.IDCODE!)));
    // 2. Cập nhật UI bằng cách xóa item khỏi list observable
    // dx.currentMaHieusInPortal.removeWhere((item) => item.code == itemToDelete.code);

    // 3. (Tùy chọn) Hiển thị thông báo thành công
    Get.snackbar("Thành công", "Đã xóa bưu gửi ${itemToDelete.code}");
  }

  void layDuLieu() {
    stateText.value = "Đang lấy dữ liệu";

    FirebaseManager().addMessageToAppBD(
        selectedMayChu.value,
        MessageReceiveModel("laydulieu200", "",
            nameMay: FirebaseManager().keyData!));
  }

  void layDuLieuLo() {
    stateText.value = "Đang lấy dữ liệu Lô";

    FirebaseManager().addMessageToAppBD(
        selectedMayChu.value,
        MessageReceiveModel("laydulieulo", "",
            nameMay: FirebaseManager().keyData!));
  }

  void editHangHoas() {
    String? id = getSelectedsIdPortal()[0];

    if (id?.isNotEmpty == true) {
      FirebaseManager().addMessage(MessageReceiveModel("edithanghoa", id!));
    }
  }

  void sendDiNgoaiAndRunBD() {
    stateText.value = "Đang gửi đi ngoài và chạy Auto BĐ";

    isAutoRunBD = true;

    List<String?> selecteds = getSelectedsIdPortal();

    if (selecteds.isNotEmpty) {
      waitingCodes = "DONGDINGOAI";

      FirebaseManager()
          .addMessage(MessageReceiveModel("getMaHieus", jsonEncode(selecteds)));
    }
  }

  void sendSplitAddress() {
    stateText.value = "Đang gửi đi ngoài và chạy Auto BĐ";

    isAutoRunBD = true;

    List<String?> selecteds = getSelectedsIdPortal();

    if (selecteds.isNotEmpty) {
      waitingCodes = "SPLITADDRESS";

      FirebaseManager()
          .addMessage(MessageReceiveModel("getMaHieus", jsonEncode(selecteds)));
    }
  }

  var listKHLon = <String>[
    "C005152833",
    "C002446626",
    "20210220115023",
    "C002760865",
    "59320A04000415000",
    "C004626705",
    "C0015048676",
    "C005325162",
    "20210220112811",
    "59320A04000685000",
    "59320A04000692000",
    "C006230404",
    "C008172528",
    "C006036737"
  ];

  void checkDongCT() {
    //lay danh sach tat ca portal
    //kiem tra xem co portal nao chua dong CT hay khong
    //neu co thi hien thi mau cam len portal do thong qua bien isDongCT
    var ids = <String>[];

    for (var portal in portals) {
      ids.add(portal.id!);
    }
    if (ids.isNotEmpty) {
      waitingCodes = "CHECKMAHIEUDINGOAI";
      FirebaseManager()
          .addMessage(MessageReceiveModel("getMaHieus", jsonEncode(ids)));
    }
  }

  void goToEditPage() {
    var selecteds = getSelectedsPortal();
    if (selecteds.length > 1) {
      FirebaseManager().showSnackBar("Chỉ chọn 1 portal để sửa");
      return;
    }
    if (selecteds.isEmpty) {
      FirebaseManager().showSnackBar("Chưa chọn portal để sửa");
      return;
    }

    Portal selectedPortal = selecteds[0];
    if (selectedPortal.trangThai != "2") {
      FirebaseManager().showSnackBar("Không phải trạng thái đang xử lý");
      return;
    }

    EditPageController editPortal = Get.find<EditPageController>();
    editPortal.loadEditPage(selectedPortal);
    Get.toNamed(Routes.EDIT_PAGE);
  }

  void getMaHieuToShow(int index) {
    isAutoRunBD = false;

    List<String?> selecteds = [];
    if (index == -1) {
      return;
    }

    waitingCodes = "TOSHOW";
    selecteds.add(portals[index].id);

    FirebaseManager()
        .addMessage(MessageReceiveModel("getMaHieus", jsonEncode(selecteds)));
  }

  void sendTest() {
    isAutoRunBD = false;

    // List<String?> selecteds = getSelectedsIdPortal();
    FirebaseManager().addMessage(MessageReceiveModel("SEND_TEST", "Test ok"));
    // if (selecteds.isNotEmpty) {
    //   WaitingCodes = "SENDTEST";
    // }
  }

  void checkCreateNew() {
    var selecteds = getSelectedsPortal();
    if (selecteds.length > 1) {
      FirebaseManager().showSnackBar("Chỉ chọn 1 portal để sửa");
      return;
    }
    if (selecteds.isEmpty) {
      FirebaseManager().showSnackBar("Chưa chọn portal để sửa");
      return;
    }

    Portal selectedPortal = selecteds[0];
    // if (selectedPortal.trangThai != "2") {
    //   FirebaseManager().showSnackBar("Không phải trạng thái đang xử lý");
    //   return;
    // }

    if (selectedPortal.id != null) {
      var ids = <String>[];
      ids.add(selectedPortal.id!);
      waitingCodes = "CHECKCREATENEW";
      FirebaseManager()
          .addMessage(MessageReceiveModel("getMaHieus", jsonEncode(ids)));
    }
  }

  // Hàm cập nhật trọng lượng
  void updateWeight(StateMaHieu item, String newWeight) {
    // TODO: Implement logic to update weight (e.g., API call, update local list)
    printInfo(info: "Cập nhật trọng lượng cho ${item.code} thành $newWeight");
    // Cập nhật trọng lượng trong danh sách hiển thị tạm thời
    final index = currentMaHieusInPortal
        .indexWhere((element) => element.IDCODE == item.IDCODE);
    //create new object to update

    if (index != -1) {
      currentMaHieusInPortal[index].Weight = newWeight;
      FirebaseManager().addMessage(MessageReceiveModel(
          "updatekl", jsonEncode(currentMaHieusInPortal[index])));
    }

    // Gửi yêu cầu cập nhật trọng lượng lên server/API
    // FirebaseManager().addMessage(
    //     MessageReceiveModel("updateWeight", jsonEncode({"id": item.IDCODE, "weight": newWeight})));

    Get.snackbar("Thành công", "Đã cập nhật trọng lượng cho ${item.code}");
  }
}
