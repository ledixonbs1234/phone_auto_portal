/// Model cho item đi ngoài được lấy từ Firebase Real-time Database
class DiNgoaiItemInfo {
  final int index; // Sequential number (1-based)
  final String code; // 13-digit barcode/tracking number
  final String? tinhGocGui; // Origin province code
  final String? tinhDuKien; // Expected destination province code
  final String? buuCucNhanTemp; // Postal office receiving code
  final double? khoiLuong; // Package weight in grams
  final bool isChuyenHoan; // Whether package needs return/exchange
  final String? maTinh; // Province code
  final String? address; // Recipient address
  final String? maBuuCuc; // Postal office code
  final String? tenBuuCuc; // Postal office name
  final String? idCode; // Unique identifier
  final int state; // Item state (0=normal, 1=marked for action)
  bool selected; // For UI selection

  DiNgoaiItemInfo({
    required this.index,
    required this.code,
    this.tinhGocGui,
    this.tinhDuKien,
    this.buuCucNhanTemp,
    this.khoiLuong,
    this.isChuyenHoan = false,
    this.maTinh,
    this.address,
    this.maBuuCuc,
    this.tenBuuCuc,
    this.idCode,
    this.state = 0,
    this.selected = false,
  });

  /// Factory constructor để parse từ JSON (từ Firebase)
  factory DiNgoaiItemInfo.fromJson(Map<String, dynamic> json) {
    return DiNgoaiItemInfo(
      index: json['Index'] as int? ?? 0,
      code: json['Code'] as String? ?? '',
      tinhGocGui: json['TinhGocGui'] as String?,
      tinhDuKien: json['TinhDuKien'] as String?,
      buuCucNhanTemp: json['BuuCucNhanTemp'] as String?,
      khoiLuong: (json['KhoiLuong'] as num?)?.toDouble(),
      isChuyenHoan: json['IsChuyenHoan'] as bool? ?? false,
      maTinh: json['MaTinh'] as String?,
      address: json['Address'] as String?,
      maBuuCuc: json['MaBuuCuc'] as String?,
      tenBuuCuc: json['TenBuuCuc'] as String?,
      idCode: json['IdCode'] as String?,
      state: json['State'] as int? ?? 0,
      selected: false,
    );
  }

  /// Convert sang JSON (nếu cần gửi lên Firebase)
  Map<String, dynamic> toJson() {
    return {
      'Index': index,
      'Code': code,
      'TinhGocGui': tinhGocGui,
      'TinhDuKien': tinhDuKien,
      'BuuCucNhanTemp': buuCucNhanTemp,
      'KhoiLuong': khoiLuong,
      'IsChuyenHoan': isChuyenHoan,
      'MaTinh': maTinh,
      'Address': address,
      'MaBuuCuc': maBuuCuc,
      'TenBuuCuc': tenBuuCuc,
      'IdCode': idCode,
      'State': state,
    };
  }

  @override
  String toString() =>
      'DiNgoaiItemInfo(index: $index, code: $code, idCode: $idCode, state: $state)';
}
