import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/controllers/portalinfo_controller.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';
import '../models/dingoai_config_item.dart';

class DingoaiConfigController extends GetxController {
  final configItems = <DiNgoaiConfigItem>[].obs;
  final selectedMayChu = "mayphu".obs;
  final maychus = <String>["maychu", "mayphu", "mayphusan", "maytest"].obs;
  final stateText = "".obs;

  @override
  void onInit() {
    super.onInit();
    _loadSelectedPortals();
  }

  void _loadSelectedPortals() {
    final portalInfoController = Get.find<PortalinfoController>();
    final selectedPortals = portalInfoController.getSelectedsPortal();

    configItems.value = selectedPortals.map((portal) {
      return DiNgoaiConfigItem(
        portalId: portal.id ?? '',
        portalName: portal.name ?? 'Không tên',
        soLuong: portal.soLuong,
        action: 'khong_chon',
      );
    }).toList();

    selectedMayChu.value = portalInfoController.selectedMayChu.value;
  }

  void updateAction(int index, String action) {
    configItems[index].action = action;
    configItems.refresh();
  }

  void submitDiNgoaiConfig() {
    // Lọc ra những item có action khác 'khong_chon'
    final activeItems = configItems.where((item) => item.action != 'khong_chon').toList();

    if (activeItems.isEmpty) {
      Get.snackbar(
        'Cảnh báo',
        'Vui lòng chọn ít nhất một hành động cho portal',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    stateText.value = "Đang lấy dữ liệu mã hiệu...";

    // Lưu cấu hình vào PortalinfoController để xử lý sau khi nhận được mã hiệu
    final portalInfoController = Get.find<PortalinfoController>();
    portalInfoController.dingoaiCustomConfig.value = activeItems.map((item) => item.toJson()).toList();
    portalInfoController.selectedMayChuForCustom.value = selectedMayChu.value;
    portalInfoController.waitingCodes = "DINGOAI_CUSTOM_CONFIG";

    // Gửi yêu cầu lấy mã hiệu giống như luồng hiện tại
    final selectedPortalIds = portalInfoController.getSelectedsIdPortal();
    FirebaseManager().addMessage(
      MessageReceiveModel("getMaHieus", jsonEncode(selectedPortalIds))
    );

    Get.back(); // Quay lại màn hình trước
  }
}
