import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/taodon/models/customer_model.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';
import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';
import '../models/nhaphang_model.dart';

class NhapHangController extends GetxController {
  // ── Passed-in customer info ──────────────────────────
  late Customer customer;

  // ── HDR ID from extension (sendhdr) ──────────────────
  final hdrIdText = ''.obs;

  // ── Form state ───────────────────────────────────────
  final formKey = GlobalKey<FormState>();

  final tenNguoiNhanCtrl = TextEditingController();
  final soDienThoaiCtrl = TextEditingController();
  final diaChiCtrl = TextEditingController();
  final noiDungCtrl = TextEditingController();
  final khoiLuongCtrl = TextEditingController();
  final codCtrl = TextEditingController();

  // Dropdown state
  final dichVuOptions = <String>['EMS', 'BCCP', 'PTT', 'KG', 'PK', 'TH'];
  final selectedDichVu = Rxn<String>();

  // Loading / submit state
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Customer is injected via Get.arguments from TaodonController
    final args = Get.arguments;
    if (args is Customer) {
      customer = args;
    } else {
      // Fallback: shouldn't happen
      customer = Customer(maKH: '', tenKH: 'Khách hàng');
    }
  }

  @override
  void onClose() {
    tenNguoiNhanCtrl.dispose();
    soDienThoaiCtrl.dispose();
    diaChiCtrl.dispose();
    noiDungCtrl.dispose();
    khoiLuongCtrl.dispose();
    codCtrl.dispose();
    super.onClose();
  }

  // ── Submit ────────────────────────────────────────────
  Future<void> submitDon() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedDichVu.value == null) {
      Get.snackbar('Thiếu thông tin', 'Vui lòng chọn Dịch Vụ',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.85),
          colorText: Colors.white);
      return;
    }

    isSubmitting.value = true;
    try {
      final model = NhapHangModel(
        tenNguoiNhan: tenNguoiNhanCtrl.text.trim(),
        soDienThoai: soDienThoaiCtrl.text.trim(),
        diaChi: diaChiCtrl.text.trim(),
        dichVu: selectedDichVu.value!,
        khoiLuong: double.tryParse(khoiLuongCtrl.text.trim()) ?? 0,
        cod: double.tryParse(codCtrl.text.trim()) ?? 0,
        noiDungBG: noiDungCtrl.text.trim(),
      );

      final db = FirebaseManager();
      db.addMessage(MessageReceiveModel(
        'nhaphang',
        jsonEncode({
          'maKH': customer.maKH,
          'tenKH': customer.tenKH,
          ...model.toJson(),
        }),
        nameMay: db.keyData ?? 'maychu',
      ));

      Get.snackbar(
        'Thành công',
        'Đã gửi đơn hàng cho ${customer.tenKH}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.85),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Clear form after success
      _clearForm();
    } catch (e) {
      debugPrint('NhapHangController submitDon error: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tạo đơn hàng: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.85),
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void _clearForm() {
    tenNguoiNhanCtrl.clear();
    soDienThoaiCtrl.clear();
    diaChiCtrl.clear();
    noiDungCtrl.clear();
    khoiLuongCtrl.clear();
    codCtrl.clear();
    selectedDichVu.value = null;
  }

  void onListenNotification(MessageReceiveModel message) {
    if (message.Lenh == 'sendhdr') {
      try {
        final data = jsonDecode(message.DoiTuong);
        hdrIdText.value = data['hdrId']?.toString() ?? '';
      } catch (e) {
        debugPrint('NhapHangController sendhdr parse error: $e');
      }
    }
  }
}
