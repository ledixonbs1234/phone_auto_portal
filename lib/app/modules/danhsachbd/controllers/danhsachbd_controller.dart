import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/firebaseManager.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/danhsachbd_model.dart';
import 'package:get_storage/get_storage.dart';

class DanhSachBDController extends GetxController {
  final db = FirebaseManager();
  final data = Rxn<DanhSachBDData>();
  final isLoading = true.obs;

  late StreamSubscription _subscription;

  final textController = TextEditingController();
  final focusNode = FocusNode();

  // Trạng thái chọn BD
  final selectedBD = RxString('');

  @override
  void onInit() {
    super.onInit();
    _listenToData();
    // Yêu cầu PC refresh dữ liệu ngay khi mở
    refreshData();
  }

  @override
  void onClose() {
    _subscription.cancel();
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  void _listenToData() {
    String key = GetStorage().read('key') ?? "maychu";

    _subscription =
        db.database.child('$key/danhsachbd/data').onValue.listen((event) {
      if (event.snapshot.exists) {
        try {
          final jsonMap =
              Map<String, dynamic>.from(event.snapshot.value as Map);
          data.value = DanhSachBDData.fromJson(jsonMap);
        } catch (e) {
          debugPrint('Lỗi parse DanhSachBDData: $e');
        }
      }
      isLoading.value = false;
    }, onError: (error) {
      debugPrint('Lỗi listen DanhSachBDData: $error');
      isLoading.value = false;
    });
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      String key = GetStorage().read('key') ?? "maychu";
      await db.database
          .child('$key/danhsachbd/commands/refreshdanhsach')
          .set('refresh');
    } catch (e) {
      debugPrint('Lỗi refreshData: $e');
    }
  }

  void selectBD(String tenBD) {
    selectedBD.value = tenBD;
    String key = GetStorage().read('key') ?? "maychu";
    // Gửi lệnh set selected BD tới PC
    db.database.child('$key/danhsachbd/commands/selectbd').set(tenBD);
  }

  Future<void> createBD(String tenBD) async {
    if (tenBD.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng chọn một Bưu điện (BD) trước');
      return;
    }
    try {
      String key = GetStorage().read('key') ?? "maychu";
      // Gửi lệnh tạo BD tới PC
      await db.database.child('$key/danhsachbd/commands/taobd').set(tenBD);
      Get.snackbar('Thành công', 'Đã gửi lệnh tạo BĐ: $tenBD');
    } catch (e) {
      debugPrint('Lỗi createBD: $e');
      Get.snackbar('Lỗi', 'Không thể gửi lệnh tạo BĐ: $e');
    }
  }

  Future<void> onSubmitted(String value) async {
    if (value.trim().isEmpty) return;
    String code = value.trim();

    textController.clear();
    focusNode.requestFocus();

    if (selectedBD.value.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng chọn một Bưu điện (BD) để thêm mã hiệu',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      String key = GetStorage().read('key') ?? "maychu";

      // AutoAdd command
      await db.database
          .child('$key/danhsachbd/commands/autoadd')
          .set({'code': code, 'time': DateTime.now().millisecondsSinceEpoch});
    } catch (e) {
      debugPrint('Lỗi autoAdd: $e');
      Get.snackbar('Lỗi', 'Không thể gửi lệnh autoAdd: $e');
    }
  }
}
