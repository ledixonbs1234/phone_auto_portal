class Portal {
  String? id;
  String? name;
  String? maKH;
  String? maDonHang;
  String? nguoiNhap;
  int? soLuong;
  String? trangThai;
  List<BuuGuiPs>? buuGuiPs;
  bool selected = false;
  bool isXuLyDiNgoai = false;

  Portal(
      {this.id,
      this.name,
      this.maKH,
      this.maDonHang,
      this.nguoiNhap,
      this.soLuong,
      this.trangThai,
      this.buuGuiPs});

  Portal.fromJson(Map<dynamic, dynamic> json) {
    id = json['Id'];
    name = json['Name'];
    maKH = json['MaKH'];
    maDonHang = json['MaDonHang'];
    nguoiNhap = json['NguoiNhap'];
    soLuong = json['SoLuong'];
    trangThai = json['TrangThai'];
    if (json['BuuGuis'] != null) {
      buuGuiPs = <BuuGuiPs>[];
      json['BuuGuis'].forEach((v) {
        buuGuiPs?.add(BuuGuiPs.fromJson(v));
      });
    }
  }

  Map<dynamic, dynamic> toJson() {
    final data = <dynamic, dynamic>{};
    data['Id'] = id;
    data['Name'] = name;
    data['MaKH'] = maKH;
    data['MaDonHang'] = maDonHang;
    data['NguoiNhap'] = nguoiNhap;
    data['SoLuong'] = soLuong;
    data['TrangThai'] = trangThai;
    if (buuGuiPs != null) {
      data['BuuGuiPs'] = buuGuiPs?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class BuuGuiPs {
  String? id;
  String? maHieu;
  String? weight;

  BuuGuiPs({this.id, this.maHieu, this.weight});

  BuuGuiPs.fromJson(Map<dynamic, dynamic> json) {
    id = json['Id'];
    maHieu = json['MaHieu'];
    weight = json['Weight'];
  }

  Map<dynamic, dynamic> toJson() {
    final data = <dynamic, dynamic>{};
    data['Id'] = id;
    data['MaHieu'] = maHieu;
    data['Weight'] = weight;
    return data;
  }
}
