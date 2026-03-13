import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_storage/get_storage.dart';
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

  /// Firebase Database reference để đọc dữ liệu từ DiNgoaiVM
  late DatabaseReference _diNgoaiDataRef;

  /// Firebase Database reference để gửi commands đến DiNgoaiVM
  late DatabaseReference _diNgoaiCommandRef;

  /// Stream subscription cho Firebase Real-time updates
  StreamSubscription<DatabaseEvent>? _diNgoaiSubscription;

  // ── Lifecycle ──────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // Dữ liệu sẽ được load từ PortalinfoController trước khi navigate
    _initializeFirebase();
  }

  @override
  void onClose() {
    // Hủy Firebase stream subscription khi đóng controller
    _diNgoaiSubscription?.cancel();
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
        Get.snackbar(
          'Lỗi',
          'Không thể kết nối Firebase: $error',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
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
      Get.snackbar(
        'Lỗi',
        'Lỗi xử lý dữ liệu: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
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

    // Gửi lệnh selectedItem lên Firebase nếu có item được chọn
    if (diNgoaiItems[index].selected) {
      _sendCommand('selectedItem', {
        'code': diNgoaiItems[index].code,
        'auto': isAuto.value,
        'print': isPrint.value,
      }).catchError((e) {
        debugPrint('Lỗi gửi lệnh selectedItem: $e');
      });
    }
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

      Get.snackbar(
        'Thành công',
        'Đã refresh dữ liệu đi ngoài từ DiNgoaiVM.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      isLoading.value = false;
      stateText.value = 'Lỗi refresh: $e';
      debugPrint('🔴 Error refreshing data: $e');
      Get.snackbar(
        'Lỗi',
        'Lỗi refresh dữ liệu: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Xóa các item đã chọn
  /// 📍 Gửi command "xoanhieubg" tới DiNgoaiVM
  /// 📍 DiNgoaiVM sẽ xóa items và publish dữ liệu cập nhật
  /// 📍 Flutter lắng nghe và cập nhật UI tự động
  Future<void> deleteSelected() async {
    final selected = diNgoaiItems.where((item) => item.selected).toList();
    if (selected.isEmpty) {
      Get.snackbar(
        'Thông báo',
        'Chưa có mục nào được chọn để xóa.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final codes = selected.map((item) => item.code).toList();

      // Gửi lệnh xóa tới DiNgoaiVM qua Firebase commands
      await _sendCommand('xoanhieubg', {
        'codes': codes,
      });

      Get.snackbar(
        'Thành công',
        'Đã gửi yêu cầu xóa ${selected.length} bưu gửi tới DiNgoaiVM.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // ⚠️ KHÔNG update UI trực tiếp
      // DiNgoaiVM sẽ xóa items trong dữ liệu của nó
      // → Publish dữ liệu cập nhật lên Firebase
      // → Flutter lắng nghe và cập nhật UI tự động
    } catch (e) {
      debugPrint('🔴 Error deleting items: $e');
      Get.snackbar(
        'Lỗi',
        'Lỗi xóa bưu gửi: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Chạy Auto — gửi lệnh đi ngoài RT tới DiNgoaiVM
  /// 📍 Gửi command "dingoaiRT" tới DiNgoaiVM
  /// 📍 DiNgoaiVM sẽ xử lý logic đi ngoài RT
  /// 📍 Dữ liệu được cập nhật từ DiNgoaiVM qua Firebase
  Future<void> runAuto() async {
    final selected = diNgoaiItems.where((item) => item.selected).toList();
    if (selected.isEmpty) {
      Get.snackbar(
        'Thông báo',
        'Chưa có mục nào được chọn.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isProcessing.value = true;
      stateText.value = 'Đang gửi lệnh đi ngoài RT tới DiNgoaiVM...';

      final codes = selected.map((item) => item.code).toList();

      // Gửi lệnh đi ngoài RT tới DiNgoaiVM qua Firebase commands
      await _sendCommand('dingoaiRT', {
        'codes': codes,
        'auto': isAuto.value,
        'print': isPrint.value,
      });

      Get.snackbar(
        'Đã gửi',
        'Đã gửi yêu cầu xử lý ${selected.length} bưu gửi tới DiNgoaiVM.',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      stateText.value = 'Đang chờ DiNgoaiVM xử lý...';
    } catch (e) {
      isProcessing.value = false;
      stateText.value = 'Lỗi: $e';
      debugPrint('🔴 Error running auto: $e');
      Get.snackbar(
        'Lỗi',
        'Lỗi gửi lệnh: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
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

  // ── Navigation ─────────────────────────────────────────

  /// Quay về trang trước
  void goBack() {
    Get.back();
  }
}
