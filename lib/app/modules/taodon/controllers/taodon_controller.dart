import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';
import 'package:phone_auto_portal/app/modules/taodon/models/customer_model.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';

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

  bool get canGoToNhapHang =>
      checkHdrId.value.isNotEmpty && checkHdrId.value != '0';

  Completer<void>? _acceptCompleter;

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

      // Notify Chrome Extension
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

      // Wait for accepttaodon message from extension
      _acceptCompleter = Completer<void>();
      await _acceptCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _acceptCompleter = null;
          throw TimeoutException('Không nhận được phản hồi từ Extension');
        },
      );

      // Navigate to NhapHang, pass the Customer as argument
      await Get.toNamed('/nhaphang', arguments: customer);
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
      _acceptCompleter = null;
    }
  }

  Future<void> onListenNotification(MessageReceiveModel message) async {
    if (message.Lenh == 'sendhdr' && _acceptCompleter != null) {
      _acceptCompleter?.complete();
    }
    if (message.Lenh == 'checktaodonok') {
      isChecking.value = false;
      try {
        final data = jsonDecode(message.DoiTuong);
        final hdrId = data['hdrId']?.toString();
        if (hdrId != null && hdrId != '0') {
          checkHdrId.value = hdrId;
        }
      } catch (e) {
        if (message.DoiTuong != '0' && message.DoiTuong.isNotEmpty) {
          checkHdrId.value = message.DoiTuong;
        }
      }
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
