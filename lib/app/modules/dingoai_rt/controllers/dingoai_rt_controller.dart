import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/state_ma_hieu_model.dart';
import 'package:phone_auto_portal/app/modules/dingoai_rt/models/di_ngoai_item_info.dart';

class DiNgoaiRtController extends GetxController {
  final items = <StateMaHieu>[].obs;

  /// Danh sách đi ngoài từ Firebase Real-time Database (từ DiNgoaiVM)
  /// ⚠️ CHỈ ĐỌC - Không được update trực tiếp trong Flutter
  /// Dữ liệu được cập nhật từ DiNgoaiVM (.NET) qua Firebase
  final diNgoaiItems = <DiNgoaiItemInfo>[].obs;

  /// Checkbox Auto
  final isAuto = false.obs;

  /// Checkbox In (Print)
  final isPrint = false.obs;

  /// Số lượng item đã chọn
  final selectedCount = 0.obs;

  /// Trạng thái đang xử lý
  final isProcessing = false.obs;

  /// Trạng thái đang tải dữ liệu từ Firebase
  final isLoading = false.obs;

  /// Text trạng thái
  final stateText = ''.obs;

  /// Scanner state
  final isScanning = false.obs;
  final scannedCount = 0.obs;
  late MobileScannerController scannerController;

  /// Firebase Database reference để đọc dữ liệu từ DiNgoaiVM
  late DatabaseReference _diNgoaiDataRef;

  /// Firebase Database reference để gửi commands đến DiNgoaiVM
  late DatabaseReference _diNgoaiCommandRef;

  /// Stream subscription cho Firebase Real-time updates
  StreamSubscription<DatabaseEvent>? _diNgoaiSubscription;

  /// Audio Player để phát âm thanh
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Lưu vị trí item trùng gần đây để phát âm trùng đơn
  final Map<String, int> _lastSeenIndex = {};

  // ── Lifecycle ──────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // Dữ liệu sẽ được load từ PortalinfoController trước khi navigate
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _initializeFirebase();
  }

  @override
  void onClose() {
    // Hủy Firebase stream subscription khi đóng controller
    _diNgoaiSubscription?.cancel();
    scannerController.dispose();
    _audioPlayer.dispose();
    super.onClose();
  }

  /// Khởi tạo Firebase Database references
  /// 📍 Data ref: đọc dữ liệu từ DiNgoaiVM (.NET)
  /// 📍 Command ref: gửi lệnh tới DiNgoaiVM
  void _initializeFirebase() {
    try {
      var keyData = GetStorage().read('key') ?? "maychu";
      // Reference để đọc dữ liệu từ DiNgoaiVM
      _diNgoaiDataRef =
          FirebaseDatabase.instance.ref('$keyData/dingoai/').child('dingoais');

      // Reference để gửi commands tới DiNgoaiVM
      _diNgoaiCommandRef =
          FirebaseDatabase.instance.ref('$keyData/dingoai/commands');

      // Tự động lắng nghe thay đổi từ Firebase (chỉ đọc)
      _listenToFirebaseUpdates();
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  }

  /// Lắng nghe cập nhật Real-time từ Firebase (dingoai node)
  /// 📍 Chỉ đọc dữ liệu từ DiNgoaiVM (.NET), không update
  /// 📍 Tự động cập nhật UI khi DiNgoaiVM thay đổi dữ liệu
  void _listenToFirebaseUpdates() {
    _diNgoaiSubscription?.cancel();
    _diNgoaiSubscription = _diNgoaiDataRef.onValue.listen(
      (DatabaseEvent event) {
        if (event.snapshot.exists) {
          debugPrint('📖 Dữ liệu từ DiNgoaiVM: ${event.snapshot.value}');
          _parseDiNgoaiData(event.snapshot.value);
        } else {
          debugPrint('📖 Không có dữ liệu từ DiNgoaiVM');
          diNgoaiItems.clear();
        }
      },
      onError: (error) {
        debugPrint('🔴 Firebase listen error: $error');
        stateText.value = 'Lỗi kết nối Firebase: $error';
      },
    );
  }

  /// Parse dữ liệu từ Firebase snapshot (từ DiNgoaiVM)
  /// ⚠️ CHỈ ĐỌC VÀ HIỂN THỊ - Không được update dữ liệu
  void _parseDiNgoaiData(dynamic data) {
    try {
      final List<DiNgoaiItemInfo> newItems = [];

      if (data is Map) {
        // Nếu data là Map, convert các entries từ DiNgoaiVM
        data.forEach((key, value) {
          if (value is Map) {
            final item = DiNgoaiItemInfo.fromJson(
              Map<String, dynamic>.from(value),
            );
            newItems.add(item);
          }
        });
      } else if (data is List) {
        // Nếu data là List
        for (var item in data) {
          if (item is Map) {
            final diNgoaiItem = DiNgoaiItemInfo.fromJson(
              Map<String, dynamic>.from(item),
            );
            newItems.add(diNgoaiItem);
          }
        }
      }

      // Sắp xếp theo index
      newItems.sort((a, b) => a.index.compareTo(b.index));
      diNgoaiItems.value = newItems;
      update();

      debugPrint('✅ Đã parse ${newItems.length} items từ DiNgoaiVM');

      if (isLoading.value) {
        isLoading.value = false;
        stateText.value = 'Đã cập nhật dữ liệu từ DiNgoaiVM';
      }
    } catch (e) {
      debugPrint('🔴 Error parsing Firebase data: $e');
      stateText.value = 'Lỗi xử lý dữ liệu: $e';
    }
  }

  // ── Data ───────────────────────────────────────────────

  /// Load dữ liệu mã hiệu vào danh sách
  /// ⚠️ Không còn sử dụng - dữ liệu được load từ Firebase qua _parseDiNgoaiData
  @Deprecated('Sử dụng dữ liệu từ Firebase qua diNgoaiItems thay vì items')
  void loadData(List<StateMaHieu> maHieus) {
    // items.assignAll(maHieus);
    // _updateSelectedCount();
  }

  // ── Selection ──────────────────────────────────────────

  /// Toggle chọn / bỏ chọn một item (chỉ cho phép chọn 1 item)
  void toggleSelect(int index) {
    if (index < 0 || index >= diNgoaiItems.length) return;

    bool isCurrentlySelected = diNgoaiItems[index].selected;

    // Bỏ chọn tất cả các item trước khi thay đổi trạng thái
    for (var item in diNgoaiItems) {
      item.selected = false;
    }

    // Đảo trạng thái của item được click
    diNgoaiItems[index].selected = !isCurrentlySelected;

    _updateSelectedCount();
    diNgoaiItems.refresh();

    // // Gửi lệnh selectedItem lên Firebase nếu có item được chọn
    // if (diNgoaiItems[index].selected) {
    //   _sendCommand('selectedItem', {
    //     'code': diNgoaiItems[index].code,
    //     'auto': isAuto.value,
    //     'print': isPrint.value,
    //   }).catchError((e) {
    //     debugPrint('Lỗi gửi lệnh selectedItem: $e');
    //   });
    // }
  }

  void _updateSelectedCount() {
    selectedCount.value = diNgoaiItems.where((item) => item.selected).length;
  }

  // ── Actions ────────────────────────────────────────────

  /// Refresh dữ liệu từ Firebase (dingoai node)
  /// 📍 Gửi lệnh refresh tới DiNgoaiVM qua Firebase commands
  /// 📍 Đọi dữ liệu từ DiNgoaiVM để hiển thị
  Future<void> refreshData() async {
    try {
      isLoading.value = true;
      stateText.value = 'Đang lấy dữ liệu từ DiNgoaiVM...';

      // Gửi lệnh refresh tới DiNgoaiVM qua Firebase commands
      await _sendCommand('refreshDiNgoai', {
        'timestamp': DateTime.now().toString(),
      });

      // Đọc dữ liệu một lần từ Firebase (từ DiNgoaiVM)
      final snapshot = await _diNgoaiDataRef.get();
      if (snapshot.exists) {
        debugPrint('✅ Đã refresh dữ liệu từ DiNgoaiVM');
        _parseDiNgoaiData(snapshot.value);
      } else {
        stateText.value = 'Không có dữ liệu từ DiNgoaiVM';
        diNgoaiItems.clear();
      }

      stateText.value = 'Đã refresh dữ liệu thành công';
    } catch (e) {
      isLoading.value = false;
      stateText.value = 'Lỗi refresh: $e';
      debugPrint('🔴 Error refreshing data: $e');
    }
  }

  /// Xóa các item đã chọn
  /// 📍 Gửi command "xoanhieubg" tới DiNgoaiVM
  /// 📍 DiNgoaiVM sẽ xóa items và publish dữ liệu cập nhật
  /// 📍 Flutter lắng nghe và cập nhật UI tự động
  Future<void> deleteSelected() async {
    final selected = diNgoaiItems.where((item) => item.selected).toList();
    if (selected.isEmpty) {
      stateText.value = 'Chưa có mục nào được chọn để xóa';
      return;
    }

    try {
      final codes = selected.map((item) => item.code).toList();

      // Gửi lệnh xóa tới DiNgoaiVM qua Firebase commands
      await _sendCommandRaw('xoanhieubg', codes);

      stateText.value =
          'Đã gửi yêu cầu xóa ${selected.length} bưu gửi tới DiNgoaiVM';

      // ⚠️ KHÔNG update UI trực tiếp
      // DiNgoaiVM sẽ xóa items trong dữ liệu của nó
      // → Publish dữ liệu cập nhật lên Firebase
      // → Flutter lắng nghe và cập nhật UI tự động
    } catch (e) {
      debugPrint('🔴 Error deleting items: $e');
      stateText.value = 'Lỗi xóa bưu gửi: $e';
    }
  }

  /// Chạy Auto — gửi lệnh đi ngoài RT tới DiNgoaiVM
  /// 📍 Gửi command "dingoaiRT" tới DiNgoaiVM
  /// 📍 DiNgoaiVM sẽ xử lý logic đi ngoài RT
  /// 📍 Dữ liệu được cập nhật từ DiNgoaiVM qua Firebase
  Future<void> runAuto() async {
    final selected = diNgoaiItems.where((item) => item.selected).toList();
    if (selected.isEmpty) {
      stateText.value = 'Chưa có mục nào được chọn';
      return;
    }

    try {
      isProcessing.value = true;
      stateText.value = 'Đang gửi lệnh đi ngoài RT tới DiNgoaiVM...';

      final codes = selected.map((item) => item.code).toList();

      // Gửi lệnh đi ngoài RT tới DiNgoaiVM qua Firebase commands
      await _sendCommandRaw('dingoaiRT', {
        'codes': codes,
        'auto': isAuto.value,
        'print': isPrint.value,
      });

      stateText.value =
          'Đã gửi yêu cầu xử lý ${selected.length} bưu gửi tới DiNgoaiVM. Đang chờ xử lý...';
    } catch (e) {
      isProcessing.value = false;
      stateText.value = 'Lỗi gửi lệnh: $e';
      debugPrint('🔴 Error running auto: $e');
    }
  }

  // ── Firebase Commands ─────────────────────────────────

  /// Gửi command tới DiNgoaiVM qua Firebase (dingoai/commands)
  ///
  /// 📍 Kiến Trúc:
  /// - Flutter gửi command → dingoai/commands node
  /// - DiNgoaiVM lắng nghe → Xử lý command
  /// - DiNgoaiVM cập nhật data → Publish lên dingoai node
  /// - Flutter lắng nghe → Cập nhật UI tự động
  ///
  /// ⚠️ KHÔNG thay đổi dữ liệu trực tiếp
  /// Tất cả thay đổi phải thông qua DiNgoaiVM
  Future<void> _sendCommand(
      String commandName, Map<String, dynamic> payload) async {
    try {
      final commandData = {
        'Lenh': commandName,
        'DoiTuong': jsonEncode(payload),
        'TimeStamp': DateTime.now().toString(),
      };

      debugPrint('📤 Gửi command tới DiNgoaiVM: $commandName');
      debugPrint('   Payload: $payload');

      // Gửi command tới dingoai/commands node
      await _diNgoaiCommandRef.set(commandData);

      debugPrint('✅ Command đã gửi thành công');
    } catch (e) {
      debugPrint('🔴 Error sending command: $e');
      rethrow;
    }
  }

  /// Gửi command với payload trực tiếp (không wrap trong JSON object)
  /// Dùng cho commands như "xoanhieubg", "dingoaiRT" cần DoiTuong là List<String>
  Future<void> _sendCommandRaw(String commandName, dynamic payload) async {
    try {
      final commandData = {
        'Lenh': commandName,
        'DoiTuong': jsonEncode(payload), // payload có thể là List hoặc Map
        'TimeStamp': DateTime.now().toString(),
      };

      debugPrint('📤 Gửi command raw tới DiNgoaiVM: $commandName');
      debugPrint('   Payload: $payload');

      await _diNgoaiCommandRef.set(commandData);

      debugPrint('✅ Command raw đã gửi thành công');
    } catch (e) {
      debugPrint('🔴 Error sending command raw: $e');
      rethrow;
    }
  }

  // ── Navigation ─────────────────────────────────────────

  /// Quay về trang trước
  void goBack() {
    Get.back();
  }

  // ── QR Scanner ──────────────────────────────────────────

  /// Hiển thị dialog quét QR
  void showScanner() {
    isScanning.value = true;
    Get.dialog(
      Obx(() => Scaffold(
            appBar: AppBar(
              title: const Text('Quét QR Code'),
              actions: [
                IconButton(
                  icon: Icon(
                    scannerController.torchEnabled
                        ? Icons.flash_on
                        : Icons.flash_off,
                  ),
                  onPressed: () => scannerController.toggleTorch(),
                ),
                IconButton(
                  icon: const Icon(Icons.switch_camera),
                  onPressed: () => scannerController.switchCamera(),
                ),
              ],
            ),
            body: Stack(
              children: [
                MobileScanner(
                  controller: scannerController,
                  onDetect: _onBarcodeDetect,
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Đã quét: ${scannedCount.value} mã',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
      barrierDismissible: false,
    ).then((_) {
      isScanning.value = false;
      _lastSeenIndex.clear();
    });
  }

  /// Xử lý khi quét được barcode
  Future<void> _onBarcodeDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        if (_lastSeenIndex.containsKey(barcode.rawValue)) {
          final lastIndex = _lastSeenIndex[barcode.rawValue]!;
          if (lastIndex > diNgoaiItems.length - 5) {
            // Item được thêm gần đây (< 5 vị trí từ cuối) - bỏ qua
            debugPrint('Bỏ qua mã trùng gần đây: $barcode.rawValue');
            return;
          }
        }
        final String scannedCode = barcode.rawValue!;
        debugPrint('📱 Đã quét: $scannedCode');
        await _processScannedCode(scannedCode);
      }
    }
  }

  /// Xử lý code đã quét
  Future<void> _processScannedCode(String code) async {
    // Tìm item trong danh sách
    final index = diNgoaiItems.indexWhere((item) => item.code == code);
    if (index != -1) {
      // Item đã tồn tại trong danh sách
      // Kiểm tra trùng gần đây - nếu item mới được thêm gần đây thì bỏ qua

      // Item trùng nhưng ở vị trí cũ - phát âm trùng đơn
      stateText.value = 'Mã $code đã có trong danh sách';

      // Chọn item nếu chưa được chọn
    } else {
      // Item chưa có trong danh sách - gửi command để DiNgoaiVM xử lý
      // PC expects DoiTuong as string directly, not JSON encoded
      try {
        final commandData = {
          'Lenh': 'adddingoai',
          'DoiTuong': code, // Send directly as string
          'TimeStamp': DateTime.now().toString(),
        };
        await _diNgoaiCommandRef.set(commandData);
        stateText.value = 'Mã $code đã được gửi tới DiNgoaiVM';

        // Lưu vị trí của item mới được thêm
        _lastSeenIndex[code] = diNgoaiItems.length;

        // Phát haptic feedback khi thêm thành công
        HapticFeedback.lightImpact();
      } catch (e) {
        stateText.value = 'Lỗi thêm mã: $e';
      }
    }

    scannedCount.value++;
  }

  /// Phát âm thanh
  Future<void> _playAudio(String path) async {
    try {
      await _audioPlayer.setAsset(path);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Lỗi phát âm thanh: $e');
    }
  }

  /// Toggle torch
  void toggleTorch() {
    scannerController.toggleTorch();
  }

  /// Toggle camera
  void toggleCamera() {
    scannerController.switchCamera();
  }
}
