import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart'; // Import material.dart
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  // Sort state management
  final sortColumnIndex = 1.obs; // Default sort by name column
  final sortAscending = false.obs; // Default descending order

  // Method to handle sorting of portals
  void sortPortals(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;

    switch (columnIndex) {
      case 0: // Thứ Tự (Index) - not really sortable as it's just index
        break;
      case 1: // Tên (Name)
        portals.sort((a, b) {
          final aName = a.name ?? '';
          final bName = b.name ?? '';
          return ascending ? aName.compareTo(bName) : bName.compareTo(aName);
        });
        break;
      case 2: // SL (Số Lượng)
        portals.sort((a, b) {
          final aCount = a.soLuong ?? 0;
          final bCount = b.soLuong ?? 0;
          return ascending
              ? aCount.compareTo(bCount)
              : bCount.compareTo(aCount);
        });
        break;
      case 3: // State (Trạng Thái)
        portals.sort((a, b) {
          final aState = a.trangThai ?? '';
          final bState = b.trangThai ?? '';
          return ascending
              ? aState.compareTo(bState)
              : bState.compareTo(aState);
        });
        break;
    }
    update(); // Trigger UI update
  }

  final isPrinted = true.obs;

  var waitingCodes = "";

  final selectedDate = DateTime.now().obs;

  // Barcode scanning functionality
  final TextEditingController barcodeInputController = TextEditingController();
  final isScanning = false.obs;
  final isScanSectionVisible = false.obs;
  final Set<String> _scannedBarcodes =
      <String>{}; // Track unique barcodes during scanning session
  
  final scannedBarcodeCount = 0.obs; // Observable count for UI

  // Mobile Scanner Controller
  MobileScannerController? mobileScannerController;
  StreamSubscription<BarcodeCapture>? _barcodeSubscription;

  // --- START: LOGIC MỚI CHO DIALOG ---
  final selectedDialogItemCount = 0.obs;

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

    // Khởi tạo mobile scanner controller nếu chưa có
    mobileScannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [
        BarcodeFormat.qrCode,
        BarcodeFormat.code128,
        BarcodeFormat.code39
      ],
    );

    // Lắng nghe barcode từ mobile scanner
    _barcodeSubscription =
        mobileScannerController?.barcodes.listen((BarcodeCapture capture) {
      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        final String? code = barcode.rawValue;
        if (code != null && code.isNotEmpty) {
          final item = currentMaHieusInPortal
              .firstWhereOrNull((element) => element.code == code);

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
      }
    });

    // Hiển thị scanner dialog
    _showMobileScannerDialog();
  }

  void cancelBulkQRScanInDialog() {
    _barcodeSubscription?.cancel();
    _barcodeSubscription = null;
    mobileScannerController?.dispose();
    mobileScannerController = null;
  }

  void _showMobileScannerDialog() {
    Get.dialog(
      Dialog(
        child: Container(
          width: 300,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Quét mã QR/Barcode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: mobileScannerController != null
                    ? MobileScanner(
                        controller: mobileScannerController!,
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      cancelBulkQRScanInDialog();
                      Get.back();
                    },
                    child: const Text('Đóng'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      mobileScannerController?.toggleTorch();
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

  // Province counting variables
  Map<String, dynamic>? _provinceData;
  final provinceCounts = <String, Map<String, int>>{}.obs;

  // Load province data from JSON
  Future<void> _loadProvinceData() async {
    if (_provinceData == null) {
      try {
        final String jsonString =
            await rootBundle.loadString('assets/tinhthanh.json');
        _provinceData = jsonDecode(jsonString);
      } catch (e) {
        print('Error loading province data: $e');
        _provinceData = {'vo': [], 'ra': []};
      }
    }
  }

  // Count packages by categories using province codes
  Future<Map<String, int>> countPackagesByCategories() async {
    await _loadProvinceData();

    final counts = <String, int>{
      'RA': 0,
      'VÔ': 0,
      'Quảng Nam': 0,
      'Quảng Ngãi': 0,
    };

    if (_provinceData == null) return counts;

    // Extract province codes from the JSON structure
    final Set<String> voCodes = <String>{};
    final Set<String> raCodes = <String>{};
    final Set<String> quangNamCodes = <String>{};
    final Set<String> quangNgaiCodes = <String>{};

    // Process VO provinces
    if (_provinceData!['vo'] != null) {
      for (final province in _provinceData!['vo']) {
        if (province['ma_tinh'] != null) {
          for (final code in province['ma_tinh']) {
            voCodes.add(code.toString());
          }
        }
      }
    }

    // Process RA provinces
    if (_provinceData!['ra'] != null) {
      for (final province in _provinceData!['ra']) {
        if (province['ma_tinh'] != null) {
          for (final code in province['ma_tinh']) {
            raCodes.add(code.toString());
          }
        }
      }
    }

    // Process Quảng Nam codes
    if (_provinceData!['quangnam'] != null) {
      for (final province in _provinceData!['quangnam']) {
        if (province['ma_tinh'] != null) {
          for (final code in province['ma_tinh']) {
            quangNamCodes.add(code.toString());
          }
        }
      }
    }

    // Process Quảng Ngãi codes
    if (_provinceData!['quangngai'] != null) {
      for (final province in _provinceData!['quangngai']) {
        if (province['ma_tinh'] != null) {
          for (final code in province['ma_tinh']) {
            quangNgaiCodes.add(code.toString());
          }
        }
      }
    }

    // Count packages based on province codes
    for (final item in currentMaHieusInPortal) {
      if (item.provinceCode == null || item.provinceCode!.isEmpty) continue;

      final provinceCode = item.provinceCode!.trim();

      // Count RA (outbound) packages
      if (raCodes.contains(provinceCode)) {
        counts['RA'] = counts['RA']! + 1;
      }

      // Count VÔ (inbound) packages
      if (voCodes.contains(provinceCode)) {
        counts['VÔ'] = counts['VÔ']! + 1;
      }

      // Count Quảng Nam packages (regardless of direction)
      if (quangNamCodes.contains(provinceCode)) {
        counts['Quảng Nam'] = counts['Quảng Nam']! + 1;
      }

      // Count Quảng Ngãi packages (regardless of direction)
      if (quangNgaiCodes.contains(provinceCode)) {
        counts['Quảng Ngãi'] = counts['Quảng Ngãi']! + 1;
      }
    }

    return counts;
  }

  // === DIRECTION SCANNING NAVIGATION ===

  /// Điều hướng đến trang Direction Scanning
  void goToDirectionScanning() {
    // Kiểm tra có portal nào được chọn không
    final selectedPortals = getSelectedsPortal();
    if (selectedPortals.isEmpty) {
      Get.snackbar(
        'Cảnh báo',
        'Vui lòng chọn ít nhất một portal trước khi check hướng',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Lấy tất cả mã hiệu từ các portal đã chọn
    final selectedPortalIds = getSelectedsIdPortal();

    // Gửi request để lấy dữ liệu mã hiệu
    waitingCodes = "TODIRECTIONSCAN";
    stateText.value = "Đang lấy dữ liệu cho Direction Scanning...";

    FirebaseManager().addMessage(
        MessageReceiveModel("getMaHieus", jsonEncode(selectedPortalIds)));
  }

  /// Scans barcodes continuously using the device camera
  /// Supports multiple barcode scanning with duplicate prevention
  /// Automatically converts to uppercase and joins with commas
  Future<void> scanBarcode() async {
    try {
      isScanning.value = true;
      _scannedBarcodes.clear(); // Clear previous session
      scannedBarcodeCount.value = 0; // Reset count
      barcodeInputController.clear(); // Clear input field

      // Start continuous scanning using mobile scanner
      _barcodeSubscription?.cancel(); // Cancel any existing subscription

      // Khởi tạo mobile scanner controller
      mobileScannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: [
          BarcodeFormat.qrCode,
          BarcodeFormat.code128,
          BarcodeFormat.code39
        ],
      );

      _barcodeSubscription =
          mobileScannerController?.barcodes.listen((BarcodeCapture capture) {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          final String? code = barcode.rawValue;
          if (code != null && code.isNotEmpty) {
            _processScanResult(code);
          }
        }
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

      // Hiển thị scanner dialog cho continuous scanning
      _showContinuousScannerDialog();
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

  void _showContinuousScannerDialog() {
    Get.dialog(
      Dialog(
        child: Container(
          width: 300,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Quét mã liên tục',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Obx(() => Text(
                    'Đã quét: ${scannedBarcodeCount.value} mã',
                    style: const TextStyle(fontSize: 14),
                  )),
              const SizedBox(height: 16),
              Expanded(
                child: mobileScannerController != null
                    ? MobileScanner(
                        controller: mobileScannerController!,
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _onScanningComplete();
                      Get.back();
                    },
                    child: const Text('Hoàn thành'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      mobileScannerController?.toggleTorch();
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

    Get.snackbar(
      'Quét mã liên tục',
      'Quét nhiều mã barcode. Nhấn "Hoàn thành" để kết thúc.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
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
    scannedBarcodeCount.value = _scannedBarcodes.length; // Update count

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
        'Đã quét ${scannedBarcodeCount.value} mã. Đang cập nhật dữ liệu...',
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
    try {
      mobileScannerController?.dispose();
    } catch (e) {
      // Controller might not be initialized
    }
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
        case "TODIRECTIONSCAN":
          waitingCodes = "";
          stateText.value = "Chuẩn bị dữ liệu cho Direction Scanning...";

          // Cung cấp dữ liệu cho Direction Scanning module
          Get.toNamed(
            Routes.DIRECTION_SCANNING,
            arguments: {
              'packages': codes,
              'selectedPortals': getSelectedsPortal(),
            },
          );
          break;
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
        case "THONGKE":
          showProvinceStatistics(codes);
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

  sendThongKe() {
    stateText.value = "Đang gửi đi ngoài và chạy Thống Kê";

    var selectedPortals = getSelectedsIdPortal();

    if (selectedPortals.isEmpty) {
      FirebaseManager().showSnackBar("Chưa chọn portal nào để xem thống kê");
    }

    if (selectedPortals.isNotEmpty) {
      waitingCodes = "THONGKE";

      FirebaseManager().addMessage(
          MessageReceiveModel("getMaHieus", jsonEncode(selectedPortals)));
    }
  }

  // Show province statistics for selected portals
  Future<void> showProvinceStatistics(List<StateMaHieu> codes) async {
    // Aggregate statistics from all selected portals
    final aggregatedCounts = <String, int>{
      'RA': 0,
      'VÔ': 0,
      'Quảng Nam': 0,
      'Quảng Ngãi': 0,
    };

    await _loadProvinceData();
    if (_provinceData == null) return;

    // Extract province codes from the JSON structure
    final Set<String> voCodes = <String>{};
    final Set<String> raCodes = <String>{};
    final Set<String> quangNamCodes = <String>{};
    final Set<String> quangNgaiCodes = <String>{};

    // Process province codes (same logic as countPackagesByCategories)
    if (_provinceData!['vo'] != null) {
      for (final province in _provinceData!['vo']) {
        if (province['ma_tinh'] != null) {
          for (final code in province['ma_tinh']) {
            voCodes.add(code.toString());
          }
        }
      }
    }

    if (_provinceData!['ra'] != null) {
      for (final province in _provinceData!['ra']) {
        if (province['ma_tinh'] != null) {
          for (final code in province['ma_tinh']) {
            raCodes.add(code.toString());
          }
        }
      }
    }

    if (_provinceData!['quangnam'] != null) {
      for (final province in _provinceData!['quangnam']) {
        if (province['ma_tinh'] != null) {
          for (final code in province['ma_tinh']) {
            quangNamCodes.add(code.toString());
          }
        }
      }
    }

    if (_provinceData!['quangngai'] != null) {
      for (final province in _provinceData!['quangngai']) {
        if (province['ma_tinh'] != null) {
          for (final code in province['ma_tinh']) {
            quangNgaiCodes.add(code.toString());
          }
        }
      }
    }

    final portalPackages = codes; // This should be portal-specific

    for (final item in portalPackages) {
      if (item.provinceCode == null || item.provinceCode!.isEmpty) continue;

      final provinceCode = item.provinceCode!.trim();

      if (raCodes.contains(provinceCode)) {
        aggregatedCounts['RA'] = aggregatedCounts['RA']! + 1;
      }
      if (voCodes.contains(provinceCode)) {
        aggregatedCounts['VÔ'] = aggregatedCounts['VÔ']! + 1;
      }
      if (quangNamCodes.contains(provinceCode)) {
        aggregatedCounts['Quảng Nam'] = aggregatedCounts['Quảng Nam']! + 1;
      }
      if (quangNgaiCodes.contains(provinceCode)) {
        aggregatedCounts['Quảng Ngãi'] = aggregatedCounts['Quảng Ngãi']! + 1;
      }
    }

    // Show statistics dialog
    _showProvinceStatisticsDialog(portalPackages.length, aggregatedCounts);
  }

  void _showProvinceStatisticsDialog(int portalCount, Map<String, int> counts) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text(
              'Thống kê',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng hợp từ $portalCount portal đã chọn',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            // Only show RA row if count > 0
            if (counts['RA']! > 0) ...[
              _buildStatisticRow('RA (Đi ra)', counts['RA']!, Colors.red),
              const SizedBox(height: 8),
            ],
            // Only show VÔ row if count > 0
            if (counts['VÔ']! > 0) ...[
              _buildStatisticRow('VÔ (Đi vào)', counts['VÔ']!, Colors.green),
              const SizedBox(height: 8),
            ],
            // Only show Quảng Nam row if count > 0
            if (counts['Quảng Nam']! > 0) ...[
              _buildStatisticRow(
                  'Quảng Nam', counts['Quảng Nam']!, Colors.orange),
              const SizedBox(height: 8),
            ],
            // Only show Quảng Ngãi row if count > 0
            if (counts['Quảng Ngãi']! > 0) ...[
              _buildStatisticRow(
                  'Quảng Ngãi', counts['Quảng Ngãi']!, Colors.purple),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng cộng:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${counts.values.reduce((a, b) => a + b)} bưu gửi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
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

  void checkPortal() {
    FirebaseManager().addMessage(MessageReceiveModel("checkportal", ""));
  }
}
