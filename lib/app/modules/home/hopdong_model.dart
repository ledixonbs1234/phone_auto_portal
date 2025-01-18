class HopDong {
  String? address = "";
  bool? isChooseHopDong = false;
  int? sTTHopDong = 0;
  String? maKH;

  HopDong({this.address, this.isChooseHopDong, this.sTTHopDong, this.maKH});

  HopDong.fromJson(Map<dynamic, dynamic> json) {
    address = json['Address'];
    isChooseHopDong = json['IsChooseHopDong'];
    sTTHopDong = json['STTHopDong'];
    maKH = json['MaKH'];
  }

  Map<dynamic, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['Address'] = address;
    data['IsChooseHopDong'] = isChooseHopDong;
    data['STTHopDong'] = sTTHopDong;
    data['MaKH'] = maKH;
    return data;
  }
}
