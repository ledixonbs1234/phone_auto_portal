// Path: hone_auto_portal/lib/app/modules/dingoai_config/models/dingoai_config_item.dart

import 'package:phone_auto_portal/app/modules/portalinfo/state_ma_hieu_model.dart';

class DiNgoaiConfigItem {
  final String portalId;
  final String? portalName;
  final int? soLuong;
  String
      action; // 'ban_bd_ntb_rieng', 'duong_thu_rieng', 'di_ra_rieng', 'dn_ntb_tq', 'khong_chon'
  List<StateMaHieu> packages; // Danh sách bưu gửi của portal này

  DiNgoaiConfigItem({
    required this.portalId,
    this.portalName,
    this.soLuong,
    this.action = 'khong_chon',
    List<StateMaHieu>? packages,
  }) : this.packages = packages ?? [];

  Map<String, dynamic> toJson() {
    return {
      'portalId': portalId,
      'portalName': portalName,
      'soLuong': soLuong,
      'action': action,
    };
  }
}
