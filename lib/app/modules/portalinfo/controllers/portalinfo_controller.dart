import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart'; // Import material.dart
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/createnew/controllers/createnew_controller.dart';
import 'package:phone_auto_portal/app/modules/dingoai_config/controllers/dingoai_config_controller.dart';
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
  final isDetailedView = false.obs; // false: Đơn giản, true: Chi tiết
  final showDirection = false
      .obs; // false: Không hiển thị hướng, true: Hiển thị hướng RA/VÔ/Quảng Nam/Quảng Ngãi
  final similarIdCodes =
      <String>{}.obs; // Set chứa IDCODE của các mục trùng tên
  final selectedMayChu = "mayphu".obs;

  bool isAutoRunBD = false;
  final isShowEdit = false.obs;

  final stateText = "".obs;

  // Variables for custom di ngoai config
  final dingoaiCustomConfig = <Map<String, dynamic>>[].obs;
  final selectedMayChuForCustom = "mayphu".obs;

  final isSortDiNgoai = false.obs;

  final countPortalSelected = 0.obs;

  // Sort state management
  final sortColumnIndex = 1.obs; // Default sort by name column
  final sortAscending = false.obs; // Default descending order

  // 2. Hàm chuyển đổi chế độ xem
  void toggleViewMode(bool value) {
    isDetailedView.value = value;
    update(); // Cập nhật UI dialog
  }

  // 2b. Hàm chuyển đổi hiển thị hướng
  Future<void> toggleDirectionView(bool value) async {
    showDirection.value = value;
    if (value) {
      await _initProvinceDirectionMap();
    }
    update(); // Cập nhật UI dialog
  }

  Map<String, String>? _provinceDirectionMap;

  Future<void> _initProvinceDirectionMap() async {
    if (_provinceDirectionMap != null) return;
    await _loadProvinceData();
    if (_provinceData == null) return;

    _provinceDirectionMap = {};

    void addCodes(String key, String direction) {
      if (_provinceData![key] != null) {
        for (final province in _provinceData![key]) {
          if (province['ma_tinh'] != null) {
            for (final code in province['ma_tinh']) {
              _provinceDirectionMap![code.toString()] = direction;
            }
          }
        }
      }
    }

    addCodes('vo', 'VÔ');
    addCodes('ra', 'RA');
    addCodes('quangnam', 'Quảng Nam');
    addCodes('quangngai', 'Quảng Ngãi');
  }

  String? getPackageDirection(StateMaHieu item) {
    if (!showDirection.value || _provinceDirectionMap == null) return null;
    if (item.provinceCode == null || item.provinceCode!.isEmpty) return null;

    final provinceCode = item.provinceCode!.trim();
    if (provinceCode == '55') {
      if (_isBinhDinhSpecialLocation(item.Address)) {
        return _extractBinhDinhLocation(item.Address);
      } else {
        return 'VÔ';
      }
    }
    return _provinceDirectionMap![provinceCode];
  }

  // 3. Hàm chuẩn hóa chuỗi (bỏ dấu, lowercase) để so sánh chính xác hơn
  String _normalizeString(String str) {
    const withDiacritics =
        'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ';
    const withoutDiacritics =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

    String lower = str.toLowerCase().trim();
    for (int i = 0; i < withDiacritics.length; i++) {
      lower = lower.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return lower;
  }

  // 4. Thuật toán Levenshtein Distance để tính khoảng cách giữa 2 chuỗi
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.filled(s2.length + 1, 0);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s2.length + 1; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1.codeUnitAt(i) == s2.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost]
            .reduce((curr, next) => curr < next ? curr : next);
      }
      for (int j = 0; j < s2.length + 1; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  // 5. Tính phần trăm giống nhau (0.0 -> 1.0)
  double _calculateSimilarity(String s1, String s2) {
    String norm1 = _normalizeString(s1);
    String norm2 = _normalizeString(s2);

    if (norm1.isEmpty && norm2.isEmpty) return 1.0;
    if (norm1.isEmpty || norm2.isEmpty) return 0.0;

    int maxLength = norm1.length > norm2.length ? norm1.length : norm2.length;
    if (maxLength == 0) return 1.0;

    int distance = _levenshteinDistance(norm1, norm2);
    return 1.0 - (distance / maxLength);
  }

  // 6. Hàm chính: Tìm và đánh dấu các tên giống nhau >= 90%
  void findSimilarNames() {
    similarIdCodes.clear();

    for (int i = 0; i < currentMaHieusInPortal.length; i++) {
      for (int j = i + 1; j < currentMaHieusInPortal.length; j++) {
        final item1 = currentMaHieusInPortal[i];
        final item2 = currentMaHieusInPortal[j];

        // Lấy tên, nếu null thì bỏ qua
        final name1 = item1.Name ?? "";
        final name2 = item2.Name ?? "";

        // Bỏ qua nếu tên quá ngắn (dưới 3 ký tự) để tránh báo ảo
        if (name1.length < 3 || name2.length < 3) continue;

        double similarity = _calculateSimilarity(name1, name2);

        // Ngưỡng 70% (0.7)
        if (similarity >= 0.9) {
          similarIdCodes.add(item1.IDCODE!);
          similarIdCodes.add(item2.IDCODE!);

          // Debug log
          printInfo(
              info:
                  "Similar found (${(similarity * 100).toStringAsFixed(1)}%): $name1 <-> $name2");
        }
      }
    }

    if (similarIdCodes.isNotEmpty) {
      // Sắp xếp lại danh sách để đưa các mục trùng lên đầu (Tùy chọn, ở đây mình chỉ highlight)
      // currentMaHieusInPortal.sort((a, b) {
      //   bool aSim = similarIdCodes.contains(a.IDCODE);
      //   bool bSim = similarIdCodes.contains(b.IDCODE);
      //   if (aSim && !bSim) return -1;
      //   if (!aSim && bSim) return 1;
      //   return 0;
      // });

      Get.snackbar("Kết quả tìm kiếm",
          "Tìm thấy ${similarIdCodes.length} mục có tên tương tự nhau.",
          backgroundColor: Colors.amber, colorText: Colors.black);
    } else {
      Get.snackbar("Thông báo", "Không tìm thấy tên nào giống nhau trên 70%.");
    }

    update(); // Refresh UI
  }

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

  final isPrinted = false.obs;

  var waitingCodes = "";

  final selectedDate = DateTime.now().obs;

  // Date range filter
  final fromDate = DateTime.now().obs;
  final toDate = DateTime.now().obs;

  // Recipient name filter
  final recipientNameFilter = "".obs;
  final TextEditingController recipientNameController = TextEditingController();

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
  final dialogSortOption = "Chưa chọn".obs; // Sorting option for dialog list
  final dialogSortAscending = false.obs; // Track sort direction

  // Search state for improved dialog
  final dialogSearchText = "".obs;
  final dialogSearchMatches = <int>[].obs;
  final dialogCurrentMatchIndex = (-1).obs;
  ScrollController? dialogScrollController;
  TextEditingController? dialogSearchTextController;
  List<GlobalKey> dialogItemKeys = [];

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

  // Helper method to remove Vietnamese accents (không dấu)
  String _removeSignVietnamese(String str) {
    var unsigned = str.toLowerCase();
    const signs = [
      'a',
      'áàảãạăắằẳẵặâấầẩẫậ',
      'e',
      'éèẻẽẹêếềểễệ',
      'o',
      'óòỏõọôốồổỗộơớờởỡợ',
      'u',
      'úùủũụưứừửữự',
      'i',
      'íìỉĩị',
      'd',
      'đ',
      'y',
      'ýỳỷỹỵ'
    ];
    for (int i = 0; i < signs.length; i += 2) {
      final replaceChar = signs[i];
      final originalChars = signs[i + 1];
      for (int j = 0; j < originalChars.length; j++) {
        unsigned = unsigned.replaceAll(originalChars[j], replaceChar);
      }
    }
    return unsigned;
  }

  void searchInDialog(String query) {
    dialogSearchText.value = query;
    dialogSearchMatches.clear();
    dialogCurrentMatchIndex.value = -1;

    if (query.trim().isEmpty) {
      update();
      return;
    }

    final unsignedQuery = _removeSignVietnamese(query.trim());

    // Find all matching indices in currentMaHieusInPortal
    for (int i = 0; i < currentMaHieusInPortal.length; i++) {
      final item = currentMaHieusInPortal[i];
      final itemName = item.Name ?? "";
      final unsignedName = _removeSignVietnamese(itemName);
      if (unsignedName.contains(unsignedQuery)) {
        dialogSearchMatches.add(i);
      }
    }

    if (dialogSearchMatches.isNotEmpty) {
      dialogCurrentMatchIndex.value = 0;
    }
    // Update UI first so widgets rebuild, then scroll after frame
    update();
    if (dialogSearchMatches.isNotEmpty) {
      scrollToMatch(0);
    }
  }

  void nextMatch() {
    if (dialogSearchMatches.isEmpty) {
      return;
    }
    dialogCurrentMatchIndex.value =
        (dialogCurrentMatchIndex.value + 1) % dialogSearchMatches.length;
    update();
    scrollToMatch(dialogCurrentMatchIndex.value);
  }

  void previousMatch() {
    if (dialogSearchMatches.isEmpty) {
      return;
    }
    dialogCurrentMatchIndex.value =
        (dialogCurrentMatchIndex.value - 1 + dialogSearchMatches.length) %
            dialogSearchMatches.length;
    update();
    scrollToMatch(dialogCurrentMatchIndex.value);
  }

  void scrollToMatch(int matchIdx) {
    if (matchIdx < 0 || matchIdx >= dialogSearchMatches.length) {
      return;
    }

    final itemIndex = dialogSearchMatches[matchIdx];

    // Chờ khung hình hiện tại được dựng xong để đảm bảo viewport đã sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (dialogScrollController != null &&
          dialogScrollController!.hasClients) {
        // Định nghĩa chiều cao cố định giống hệt bên UI
        final double itemHeight = isDetailedView.value ? 130.0 : 55.0;
        const double separatorHeight = 1.0; // Đồng bộ với Divider(height: 1)
        final double itemStep = itemHeight + separatorHeight;

        // Lấy chiều cao vùng hiển thị thực tế của ListView (Viewport)
        final double viewportHeight =
            dialogScrollController!.position.viewportDimension;

        // Công thức toán học tính toán offset chính xác để đưa dòng được chọn vào chính giữa màn hình
        double targetOffset =
            (itemIndex * itemStep) - (viewportHeight / 2) + (itemHeight / 2);

        // Đảm bảo vị trí cuộn nằm trong giới hạn cho phép (không cuộn quá đầu hoặc cuối danh sách)
        final double maxScroll =
            dialogScrollController!.position.maxScrollExtent;
        targetOffset = targetOffset.clamp(0.0, maxScroll);

        // Cuộn mượt mà trực tiếp đến vị trí mong muốn chỉ với 1 hành động duy nhất
        dialogScrollController!.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Sort dialog list based on selected option
  void sortDialogList(String sortOption) {
    // If clicking the same option, toggle sort direction
    if (dialogSortOption.value == sortOption) {
      dialogSortAscending.value = !dialogSortAscending.value;
    } else {
      dialogSortOption.value = sortOption;
      dialogSortAscending.value = true; // Default to ascending for new option
    }

    switch (sortOption) {
      case "Trọng lượng":
        currentMaHieusInPortal.sort((a, b) {
          final aWeight = double.tryParse(a.Weight ?? '0') ?? 0;
          final bWeight = double.tryParse(b.Weight ?? '0') ?? 0;
          return dialogSortAscending.value
              ? aWeight.compareTo(bWeight) // Ascending
              : bWeight.compareTo(aWeight); // Descending
        });
        break;
      case "COD":
        currentMaHieusInPortal.sort((a, b) {
          final aMoney = double.tryParse(a.Money ?? '0') ?? 0;
          final bMoney = double.tryParse(b.Money ?? '0') ?? 0;
          return dialogSortAscending.value
              ? aMoney.compareTo(bMoney) // Ascending
              : bMoney.compareTo(aMoney); // Descending
        });
        break;
      case "Chưa chọn":
      default:
        // Do nothing - keep original order
        break;
    }
    update();
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

    // // Cập nhật UI ngay lập tức
    // currentMaHieusInPortal.removeWhere((item) => item.selected);
    // _updateSelectedDialogItemCount();
    // update();

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
        _provinceData = {'vo': [], 'ra': []};
      }
    }
  }

  /// Kiểm tra xem địa chỉ có chứa địa danh đặc biệt của Bình Định không
  bool _isBinhDinhSpecialLocation(String? address) {
    if (address == null || address.isEmpty) return false;

    final normalizedAddress = removeDiacritics(address.toLowerCase());
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

  /// Trích xuất tên địa danh đặc biệt từ địa chỉ (có dấu)
  String _extractBinhDinhLocation(String? address) {
    if (address == null || address.isEmpty) return 'Bình Định khác';

    final normalizedAddress = removeDiacritics(address.toLowerCase());

    // Map từ tên không dấu sang tên có dấu
    final locationMap = {
      'hoai nhon': 'Hoài Nhơn',
      'tam quan': 'Tam Quan',
      'hoai an': 'Hoài Ân',
      'an lao': 'An Lão',
      'an hao': 'Ân Hảo',
      'an my': 'Ân Mỹ',
      'binh duong': 'Bình Dương',
      'phu my': 'Phù Mỹ',
      'phu cat': 'Phù Cát'
    };

    for (final entry in locationMap.entries) {
      if (normalizedAddress.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'Bình Định khác';
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

      // Kiểm tra trường hợp đặc biệt: Bình Định (mã 55)
      if (provinceCode == '55') {
        if (_isBinhDinhSpecialLocation(item.Address)) {
          // Có địa danh đặc biệt → phân loại theo tên địa danh
          final locationName = _extractBinhDinhLocation(item.Address);
          counts[locationName] = (counts[locationName] ?? 0) + 1;
          continue; // Bỏ qua các kiểm tra khác
        } else {
          // Không có địa danh đặc biệt → tính vào VÔ
          counts['VÔ'] = counts['VÔ']! + 1;
          continue; // Bỏ qua các kiểm tra khác
        }
      }

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
      recipientNameController.clear(); // Clear the text field
      recipientNameFilter.value = ""; // Reset recipient name filter
    }
  }

  @override
  void onClose() {
    barcodeInputController.dispose();
    recipientNameController.dispose();
    _barcodeSubscription?.cancel(); // Cancel continuous scanning subscription

    cancelBulkQRScanInDialog();
    try {
      mobileScannerController?.dispose();
    } catch (e) {
      // Controller might not be initialized
    }
    super.onClose();
  }

  Future<void> refreshPortal(
    DateTime? time, {
    DateTime? fromDate,
    DateTime? toDate,
    String? recipientName,
  }) async {
    // Use provided filters or fall back to controller values
    DateTime? dateFilterFrom = fromDate ?? this.fromDate.value;
    DateTime? dateFilterTo = toDate ?? this.toDate.value;
    String? nameFilter = recipientName ??
        (recipientNameFilter.value.isEmpty ? null : recipientNameFilter.value);

    // Helper function to check if two dates are the same day
    bool isSameDay(DateTime date1, DateTime date2) {
      return date1.year == date2.year &&
          date1.month == date2.month &&
          date1.day == date2.day;
    }

    // Check if all filters are at default values (today + no recipient name)
    bool isDefaultFilters = isSameDay(dateFilterFrom, DateTime.now()) &&
        isSameDay(dateFilterTo, DateTime.now()) &&
        (nameFilter == null || nameFilter.isEmpty);

    if (isDefaultFilters) {
      // Call with just time and maHieus (old way)
      await FirebaseManager()
          .refreshPortal(time, maHieus: barcodeInputController.text);
    } else {
      // Call with all filter parameters
      await FirebaseManager().refreshPortal(
        time,
        maHieus: barcodeInputController.text,
        fromDate: dateFilterFrom,
        toDate: dateFilterTo,
        recipientName: nameFilter,
      );
    }

    // Build status message
    List<String> filterInfo = [];
    if (barcodeInputController.text.isNotEmpty) {
      filterInfo.add("Mã: ${barcodeInputController.text.split(',').length}");
    }
    if (nameFilter != null && nameFilter.isNotEmpty) {
      filterInfo.add("Tên: $nameFilter");
    }
    filterInfo.add(
        "Từ ${dateFilterFrom.day}/${dateFilterFrom.month} đến ${dateFilterTo.day}/${dateFilterTo.month}");

    if (filterInfo.isNotEmpty) {
      stateText.value = "Đang cập nhật dữ liệu - ${filterInfo.join(", ")}";
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
        case "DINGOAI_CUSTOM_CONFIG":
          waitingCodes = "";
          stateText.value =
              "Đang gửi cấu hình đi ngoài tới PC ${selectedMayChuForCustom.value}";

          final configItems = dingoaiCustomConfig.toList();
          final List<Map<String, dynamic>> payloadItems = [];

          for (var config in configItems) {
            final portalId = config['portalId'];
            final action = config['action'];

            // Lọc codes thuộc portal này
            final portalCodes = codes.where((c) => c.iD == portalId).toList();
            final maHieus = portalCodes.map((e) => e.code!).toList();
            final codeIDs = portalCodes.map((e) => e.IDCODE!).toList();

            payloadItems.add({
              'portalId': portalId,
              'action': action,
              'codes': maHieus,
              'codeIDs': codeIDs,
            });
          }

          final finalPayload = {
            'mayChu': selectedMayChuForCustom.value,
            'items': payloadItems,
          };

          FirebaseManager().addMessageToAppBD(selectedMayChu.value,
              MessageReceiveModel("dingoaiquere", jsonEncode(finalPayload)));

          // Reset config sau khi gửi
          dingoaiCustomConfig.clear();
          break;

        case "DINGOAI_CONFIG_INIT":
          waitingCodes = "";
          if (Get.isRegistered<DingoaiConfigController>()) {
            Get.find<DingoaiConfigController>().onPackagesLoaded(codes);
          }
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
          // Reset sort state when loading new portal data
          dialogSortOption.value = "Chưa chọn";
          dialogSortAscending.value = true;
          isShowEdit.value = true;
          update();
          break;

        default:
      }
    } else if (message.Lenh == "message") {
      stateText.value = message.DoiTuong;
      // Làm mới danh sách khi xóa thành công hoặc cập nhật KL thành công
      final msg = message.DoiTuong.toString();
      if (msg.contains("Xóa thành công") || msg.contains("Đã cập nhật KL")) {
        if (iPotal.value >= 0 && iPotal.value < portals.length) {
          getMaHieuToShow(iPotal.value);
        } else {
          refreshPortal(null);
        }
      }
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

  // Show statistics for current portal (used in showImprovedDialog)
  Future<void> showStatisticsForCurrentPortal() async {
    if (currentMaHieusInPortal.isEmpty) {
      Get.snackbar(
        "Thông báo",
        "Không có dữ liệu để thống kê",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final counts = await countPackagesByCategories();
    _showProvinceStatisticsDialog(currentMaHieusInPortal.length, counts);
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

      // Kiểm tra trường hợp đặc biệt: Bình Định (mã 55)
      if (provinceCode == '55') {
        if (_isBinhDinhSpecialLocation(item.Address)) {
          // Có địa danh đặc biệt → phân loại theo tên địa danh
          final locationName = _extractBinhDinhLocation(item.Address);
          aggregatedCounts[locationName] =
              (aggregatedCounts[locationName] ?? 0) + 1;
          continue; // Bỏ qua các kiểm tra khác
        } else {
          // Không có địa danh đặc biệt → tính vào VÔ
          aggregatedCounts['VÔ'] = aggregatedCounts['VÔ']! + 1;
          continue; // Bỏ qua các kiểm tra khác
        }
      }

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
    // Định nghĩa thứ tự ưu tiên và màu sắc cho các danh mục
    final categoryOrder = ['RA', 'VÔ', 'Quảng Nam', 'Quảng Ngãi'];
    final categoryColors = {
      'RA': Colors.red,
      'VÔ': Colors.green,
      'Quảng Nam': Colors.orange,
      'Quảng Ngãi': Colors.purple,
    };

    // Màu sắc cho các địa danh đặc biệt của Bình Định
    final binhDinhColors = [
      Colors.blue,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
      Colors.deepPurple,
      Colors.pink,
      Colors.amber,
      Colors.deepOrange,
      Colors.lime,
    ];

    // Tạo danh sách các mục để hiển thị
    final displayItems = <MapEntry<String, int>>[];

    // Thêm các danh mục chính theo thứ tự
    for (final category in categoryOrder) {
      if (counts.containsKey(category) && counts[category]! > 0) {
        displayItems.add(MapEntry(category, counts[category]!));
      }
    }

    // Thêm các địa danh đặc biệt của Bình Định (sắp xếp theo tên)
    final binhDinhLocations = counts.entries
        .where((entry) => !categoryOrder.contains(entry.key) && entry.value > 0)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    displayItems.addAll(binhDinhLocations);

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
        content: SingleChildScrollView(
          child: Column(
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
              // Hiển thị các mục động
              ...displayItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final category = item.key;
                final count = item.value;

                // Chọn màu
                Color color;
                if (categoryColors.containsKey(category)) {
                  color = categoryColors[category]!;
                } else {
                  // Địa danh Bình Định - sử dụng màu từ danh sách
                  final binhDinhIndex = index -
                      categoryOrder
                          .where((cat) =>
                              counts.containsKey(cat) && counts[cat]! > 0)
                          .length;
                  color = binhDinhColors[binhDinhIndex % binhDinhColors.length];
                }

                return Column(
                  children: [
                    _buildStatisticRow(category, count, color),
                    if (index < displayItems.length - 1)
                      const SizedBox(height: 8),
                  ],
                );
              }),
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
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.8),
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

  /// Điều hướng đến trang Đi Ngoài RT
  void goToDiNgoaiRT() {
    Get.toNamed(Routes.DINGOAI_RT);
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
