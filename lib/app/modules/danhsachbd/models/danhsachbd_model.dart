class DanhSachBDData {
  final int countKien;
  final int countTui;
  final int countBao;
  final List<LocBDModel> locBDs;

  DanhSachBDData({
    required this.countKien,
    required this.countTui,
    required this.countBao,
    required this.locBDs,
  });

  factory DanhSachBDData.fromJson(Map<String, dynamic> json) {
    var locsList = json['LocBDs'] as List?;
    List<LocBDModel> locs = [];
    if (locsList != null) {
      locs = locsList.map((e) => LocBDModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }

    return DanhSachBDData(
      countKien: json['CountKien'] ?? 0,
      countTui: json['CountTui'] ?? 0,
      countBao: json['CountBao'] ?? 0,
      locBDs: locs,
    );
  }
}

class LocBDModel {
  final String tenBD;
  final int count;
  final String isSendAlled;

  LocBDModel({
    required this.tenBD,
    required this.count,
    required this.isSendAlled,
  });

  factory LocBDModel.fromJson(Map<String, dynamic> json) {
    return LocBDModel(
      tenBD: json['TenBD'] ?? '',
      count: json['Count'] ?? 0,
      isSendAlled: json['IsSendAlled'] ?? '',
    );
  }
}
