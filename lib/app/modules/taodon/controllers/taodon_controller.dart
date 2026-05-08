import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';
import 'package:phone_auto_portal/app/modules/taodon/models/customer_model.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';
import 'package:phone_auto_portal/app/modules/nhaphang/controllers/nhaphang_controller.dart';

class TaodonController extends GetxController {
  final isLoading = true.obs;
  final customers = <Customer>[].obs;
  final selectedMaKH = Rxn<String>();
  final stateText = ''.obs;

  /// Button loading state — disables "Tạo đơn" while request is in flight.
  final isButtonLoading = false.obs;

  /// Check portal button state
  final isChecking = false.obs;
  final checkHdrId = ''.obs;
  final selectedTenKH = ''.obs;
  final contractServiceCode = ''.obs;

  Completer<void>? _selectCompleter;

  bool get canGoToNhapHang =>
      checkHdrId.value.isNotEmpty && checkHdrId.value != '0';

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  void sendCheckTaodon() {
    Get.printInfo(info: "Đang gui Check Tao Don");
    isChecking.value = true;
    checkHdrId.value = '';
    final db = FirebaseManager();
    db.addMessage(MessageReceiveModel(
      "checktaodon",
      "",
      nameMay: db.keyData ?? "maychu",
    ));
  }

  void goToNhapHang() {
    if (!canGoToNhapHang) return;
    final cust = getSelectedCustomer();
    final csc = contractServiceCode.value;
    Get.find<NhapHangController>().setUp(
      cust!,
      hdrId: checkHdrId.value,
      contractServiceCode: csc,
    );
    Get.toNamed('/nhaphang');
  }

  void fetchCustomers() {
    isLoading.value = true;
    final db = FirebaseManager();
    db.database.child('PORTAL/HopDongs').once().then((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final list = <Customer>[];
        data.forEach((key, value) {
          if (value is Map) {
            list.add(Customer.fromJson(key, value));
          }
        });

        // Sort: named customers first, then alphabetically
        list.sort((a, b) {
          final aHasName = a.tenKH.trim().isNotEmpty;
          final bHasName = b.tenKH.trim().isNotEmpty;
          if (aHasName && !bHasName) return -1;
          if (!aHasName && bHasName) return 1;
          return a.tenKH.compareTo(b.tenKH);
        });

        customers.value = list;
      } else {
        customers.clear();
      }
      isLoading.value = false;
    }).catchError((error) {
      isLoading.value = false;
      Get.snackbar('Lỗi', 'Không thể tải danh sách khách hàng');
      debugPrint('Error fetching customers: $error');
    });
  }

  Future<void> selectCustomer(Customer customer) async {
    if (isButtonLoading.value) return;
    isButtonLoading.value = true;
    stateText.value = 'Đang gửi yêu cầu...';
    try {
      final db = FirebaseManager();

      db.addMessage(MessageReceiveModel(
        "taodon",
        jsonEncode({
          "maKH": customer.maKH,
          "tenKH": customer.tenKH,
          "address": customer.address,
          "sttHopDong": customer.sttHopDong,
          "isChooseHopDong": customer.isChooseHopDong,
        }),
        nameMay: db.keyData ?? "maychu",
      ));

      stateText.value = 'Đang chờ xác nhận...';

      _selectCompleter = Completer<void>();
      await _selectCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _selectCompleter = null;
          throw TimeoutException('Không nhận được phản hồi từ Extension');
        },
      );

      final cust = getSelectedCustomer();
      final csc = contractServiceCode.value;
      Get.find<NhapHangController>().setUp(
        cust!,
        hdrId: checkHdrId.value,
        contractServiceCode: csc,
      );
      await Get.toNamed('/nhaphang');
    } on TimeoutException catch (e) {
      Get.snackbar(
        'Hết thời gian',
        e.message ?? 'Extension không phản hồi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('selectCustomer error: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tạo đơn: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
    } finally {
      isButtonLoading.value = false;
      stateText.value = '';
      _selectCompleter = null;
    }
  }

  Future<void> onListenNotification(MessageReceiveModel message) async {
    if (message.Lenh == 'checktaodonok') {
      isChecking.value = false;
      try {
        final data = jsonDecode(message.DoiTuong);
        final hdrId = data['hdrId']?.toString();
        final maKH = data['customerCode']?.toString();
        final tenKH = data['customerName']?.toString();
        final csc = data['contractServiceCode']?.toString() ?? '';

        if (hdrId != null && hdrId != '0') {
          checkHdrId.value = hdrId;
          selectedMaKH.value = maKH;
          selectedTenKH.value = tenKH ?? '';
          contractServiceCode.value = csc;
        }
      } catch (e) {
        if (message.DoiTuong != '0' && message.DoiTuong.isNotEmpty) {
          checkHdrId.value = message.DoiTuong;
        }
      }
      _selectCompleter?.complete();
    }
  }

  Customer? getSelectedCustomer() {
    final maKH = selectedMaKH.value;
    if (maKH == null) return null;
    try {
      return customers.firstWhere((c) => c.maKH == maKH);
    } catch (e) {
      return null;
    }
  }
}
