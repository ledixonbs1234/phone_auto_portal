import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/taodon/models/customer_model.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';
import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';
import '../models/nhaphang_model.dart';
import '../services/address_suggestion_service.dart';

class NhapHangController extends GetxController {
  final scrollController = ScrollController();
  final addressFocusNode = FocusNode();
  final addressGlobalKey = GlobalKey();
  // ── Address suggestion service ───────────────────────
  final AddressSuggestionService addressService = AddressSuggestionService();
  final addressSuggestions = <AddressSuggestion>[].obs;
  Timer? _searchDebounce;

  // ── Passed-in customer info ───────────────────────────
  Customer _customer = Customer(maKH: '', tenKH: '');

  Customer get customer => _customer;

  // ── HDR ID from extension (sendhdr) ──────────────────
  final hdrIdText = ''.obs;

  // ── Address lookup (getaddress) ──────────────────────
  final tinh = ''.obs;
  final huyen = ''.obs;
  final xa = ''.obs;

  void lookupAddress(String address) {
    if (address.trim().isEmpty) return;
    final db = FirebaseManager();
    db.addMessage(MessageReceiveModel(
      'getaddress',
      address.trim(),
      nameMay: db.keyData ?? 'maychu',
    ));
  }

  void onAddressChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      addressSuggestions.clear();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      addressSuggestions.value = addressService.search(value);
    });
  }

  void selectAddressSuggestion(AddressSuggestion suggestion) {
    diaChiCtrl.text = suggestion.fullAddress;
    diaChiCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.fullAddress.length),
    );
    addressSuggestions.clear();
    lookupAddress(suggestion.fullAddress);
  }

  // ── Form state ───────────────────────────────────────
  final formKey = GlobalKey<FormState>();

  final tenNguoiNhanCtrl = TextEditingController();
  final soDienThoaiCtrl = TextEditingController();
  final diaChiCtrl = TextEditingController();
  final noiDungCtrl = TextEditingController();
  final khoiLuongCtrl = TextEditingController();
  final codCtrl = TextEditingController();

  // Dropdown state
  List<String> dichVuOptions = [];
  final selectedDichVu = Rxn<String>();

  // Loading / submit state
  final isSubmitting = false.obs;
  Timer? _submitTimeout;

  @override
  void onInit() {
    super.onInit();
    addressService.load();
    addressFocusNode.addListener(_onAddressFocusChanged);
  }

  void _onAddressFocusChanged() {
    if (addressFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = addressGlobalKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              alignment: 0.0, duration: const Duration(milliseconds: 300));
        }
      });
    }
  }

  void setUp(Customer cust, {String? hdrId, String? contractServiceCode}) {
    _customer = cust;
    hdrIdText.value = hdrId ?? '';
    _parseContractServiceCode(contractServiceCode);
    selectedDichVu.value = null;
    _clearForm();
  }

  void _parseContractServiceCode(String? csc) {
    if (csc != null && csc.isNotEmpty) {
      dichVuOptions = csc
          .split('|')
          .map((e) => e.split(';').first.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      dichVuOptions = ['EMS', 'BCCP', 'PTT', 'KG', 'PK', 'TH'];
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _submitTimeout?.cancel();
    addressFocusNode.removeListener(_onAddressFocusChanged);
    addressFocusNode.dispose();
    scrollController.dispose();
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
        cod: double.tryParse(codCtrl.text.trim().replaceAll('.', '')) ?? 0,
        noiDungBG: noiDungCtrl.text.trim(),
      );

      final db = FirebaseManager();
      db.addMessage(MessageReceiveModel(
        'submitnhaphang',
        jsonEncode({
          'hdrId': hdrIdText.value,
          'maKH': customer.maKH,
          'tenKH': customer.tenKH,
          ...model.toJson(),
        }),
        nameMay: db.keyData ?? 'maychu',
      ));

      _submitTimeout?.cancel();
      _submitTimeout = Timer(const Duration(seconds: 30), () {
        if (isSubmitting.value) {
          isSubmitting.value = false;
          Get.snackbar(
            'Lỗi',
            'Không nhận được phản hồi từ máy chủ',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.85),
            colorText: Colors.white,
          );
        }
      });
    } catch (e) {
      debugPrint('NhapHangController submitDon error: $e');
      isSubmitting.value = false;
      Get.snackbar(
        'Lỗi',
        'Không thể gửi đơn hàng: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.85),
        colorText: Colors.white,
      );
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
    switch (message.Lenh) {
      case 'sendhdr':
        try {
          final data = jsonDecode(message.DoiTuong);
          hdrIdText.value = data['hdrId']?.toString() ?? '';
        } catch (e) {
          debugPrint('NhapHangController sendhdr parse error: $e');
        }
      case 'getaddressok':
        try {
          final data = jsonDecode(message.DoiTuong);
          tinh.value = data['tinh']?.toString() ?? '';
          huyen.value = data['huyen']?.toString() ?? '';
          xa.value = data['xa']?.toString() ?? '';
        } catch (e) {
          debugPrint('NhapHangController getaddressok parse error: $e');
        }
      case 'submitnhaphangok':
        _submitTimeout?.cancel();
        if (isSubmitting.value) {
          _clearForm();
          isSubmitting.value = false;
          Get.snackbar(
            'Thành công',
            'Đã tạo đơn hàng thành công',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.85),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      case 'submitnhaphangerror':
        _submitTimeout?.cancel();
        if (isSubmitting.value) {
          isSubmitting.value = false;
          Get.snackbar(
            'Lỗi',
            message.DoiTuong.isNotEmpty
                ? message.DoiTuong
                : 'Tạo đơn thất bại',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.85),
            colorText: Colors.white,
          );
        }
    }
  }
}
