// Path: hone_auto_portal/lib/app/modules/dingoai_config/controllers/dingoai_config_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/controllers/portalinfo_controller.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/state_ma_hieu_model.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart';
import '../models/dingoai_config_item.dart';

class DingoaiConfigController extends GetxController {
  final configItems = <DiNgoaiConfigItem>[].obs;
  final selectedMayChu = "mayphu".obs;
  final maychus = <String>["maychu", "mayphu", "mayphusan", "maytest"].obs;
  final stateText = "".obs;
  final isLoadingPackages = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSelectedPortals();
    _fetchPackages();
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

  // Tải danh sách bưu gửi của tất cả các portal đã chọn
  void _fetchPackages() {
    final portalInfoController = Get.find<PortalinfoController>();
    final selectedPortalIds = portalInfoController.getSelectedsIdPortal();
    if (selectedPortalIds.isNotEmpty) {
      isLoadingPackages.value = true;
      stateText.value = "Đang tải danh sách bưu gửi...";

      portalInfoController.waitingCodes = "DINGOAI_CONFIG_INIT";
      FirebaseManager().addMessage(
          MessageReceiveModel("getMaHieus", jsonEncode(selectedPortalIds)));
    }
  }

  // Callback được gọi từ PortalinfoController khi dữ liệu tải về thành công
  void onPackagesLoaded(List<StateMaHieu> codes) {
    isLoadingPackages.value = false;
    stateText.value = "Đã tải xong danh sách bưu gửi";

    for (var item in configItems) {
      final portalCodes = codes.where((c) => c.iD == item.portalId).toList();
      // Mặc định chọn tất cả
      for (var code in portalCodes) {
        code.selected = true;
      }
      item.packages = portalCodes;
    }
    configItems.refresh();
  }

  void updateAction(int index, String action) {
    configItems[index].action = action;
    configItems.refresh();
  }

  void submitDiNgoaiConfig() {
    final activeItems = configItems.toList();
    final List<Map<String, dynamic>> payloadItems = [];

    for (var item in activeItems) {
      final portalId = item.portalId;
      final action = item.action;

      // CHỈ giữ lại các bưu gửi được chọn (selected == true)
      final selectedPackages = item.packages.where((p) => p.selected).toList();

      final maHieus = selectedPackages.map((e) => e.code!).toList();
      final codeIDs = selectedPackages.map((e) => e.IDCODE!).toList();

      payloadItems.add({
        'portalId': portalId,
        'action': action,
        'codes': maHieus,
        'codeIDs': codeIDs,
      });
    }

    final finalPayload = {
      'mayChu': selectedMayChu.value,
      'items': payloadItems,
    };

    stateText.value = "Đang gửi cấu hình đi ngoài...";

    FirebaseManager().addMessageToAppBD(selectedMayChu.value,
        MessageReceiveModel("dingoaiquere", jsonEncode(finalPayload)));

    Get.back(); // Quay lại màn hình trước
  }
}
