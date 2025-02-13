class DiNgoaiStateInfo {
  String? maBuuCucNhan = "";
  String? keyExactly = "";
  String? maHieu;
  String? khoiLuong;

  DiNgoaiStateInfo(
      {this.maBuuCucNhan, this.keyExactly, this.maHieu, this.khoiLuong});

  DiNgoaiStateInfo.fromJson(Map<dynamic, dynamic> json) {
    maBuuCucNhan = json['MaBuuCucNhan'];
    keyExactly = json['KeyExactly'];
    maHieu = json['MaHieu'];
    khoiLuong = json['KhoiLuong'];
  }

  Map<dynamic, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['MaBuuCucNhan'] = maBuuCucNhan;
    data['KeyExactly'] = keyExactly;
    data['MaHieu'] = maHieu;
    data['KhoiLuong'] = khoiLuong;
    return data;
  }
}
