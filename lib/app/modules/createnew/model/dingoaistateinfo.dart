class DiNgoaiStateInfo {
  String? maBuuCucNhan = "";
  String? keyExactly = "";
  String? maHieu;

  DiNgoaiStateInfo({this.maBuuCucNhan, this.keyExactly, this.maHieu});

  DiNgoaiStateInfo.fromJson(Map<dynamic, dynamic> json) {
    maBuuCucNhan = json['MaBuuCucNhan'];
    keyExactly = json['KeyExactly'];
    maHieu = json['MaHieu'];
  }

  Map<dynamic, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['MaBuuCucNhan'] = maBuuCucNhan;
    data['KeyExactly'] = keyExactly;
    data['MaHieu'] = maHieu;
    return data;
  }
}
