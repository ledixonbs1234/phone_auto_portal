class DiNgoaiConfigItem {
  final String portalId;
  final String? portalName;
  final int? soLuong;
  String action; // 'ban_bd_ntb_rieng', 'duong_thu_rieng', 'khong_chon'

  DiNgoaiConfigItem({
    required this.portalId,
    this.portalName,
    this.soLuong,
    this.action = 'khong_chon',
  });

  Map<String, dynamic> toJson() {
    return {
      'portalId': portalId,
      'portalName': portalName,
      'soLuong': soLuong,
      'action': action,
    };
  }
}
