class KhachHangs {
  List<BuuGuis>? buuGuis;
  int? index;
  String? maKH;
  String? maTin;
  String? tenKH;
  String? tenNguoiGui;
  String? timeNhanTin;

  CountState? countState;

  KhachHangs(
      {this.buuGuis,
      this.index,
      this.maKH,
      this.maTin,
      this.tenKH,
      this.tenNguoiGui,
      this.timeNhanTin,
      this.countState});

  KhachHangs.fromJson(Map<dynamic, dynamic> json) {
    if (json['BuuGuis'] != null) {
      buuGuis = <BuuGuis>[];
      json['BuuGuis'].forEach((v) {
        buuGuis?.add(BuuGuis.fromJson(v));
      });
    }
    index = json['Index'];
    maKH = json['MaKH'];
    maTin = json['MaTin'];

    tenKH = json['TenKH'];
    tenNguoiGui = json['TenNguoiGui'];
    timeNhanTin = json['TimeNhanTin'];
    countState = json['countState'] != null
        ? CountState?.fromJson(json['countState'])
        : null;
  }

  Map<dynamic, dynamic> toJson() {
    final data = <dynamic, dynamic>{};
    if (buuGuis != null) {
      data['BuuGuis'] = buuGuis?.map((v) => v.toJson()).toList();
    }
    data['Index'] = index;
    data['MaKH'] = maKH;
    data['MaTin'] = maTin;
    data['TenKH'] = tenKH;

    data['TenNguoiGui'] = tenNguoiGui;
    data['TimeNhanTin'] = timeNhanTin;
    if (countState != null) {
      data['countState'] = countState?.toJson();
    }
    return data;
  }
}

class BuuGuis {
  int? khoiLuong;
  String? id;
  String? maBuuGui;
  String? timeTrangThai;
  bool isBlackList = false;
  String? trangThai;
  String? trangThaiRequest;
  String? money;
  int? index;
  List<String>? listDo = <String>[];

  BuuGuis(
      {this.khoiLuong,
      this.maBuuGui,
      this.timeTrangThai,
      this.trangThai,
      this.id,
      this.money,
      this.listDo,
      this.trangThaiRequest,
      this.index});

  BuuGuis.fromJson(Map<dynamic, dynamic> json) {
    khoiLuong = json['KhoiLuong'];
    maBuuGui = json['MaBuuGui'];
    id = json['Id'];
    isBlackList = json['IsBlackList'] ?? false;
    timeTrangThai = json['TimeTrangThai'];
    trangThai = json['TrangThai'];
    money = json['Money'];
    listDo = json['ListDo'];

    trangThaiRequest = json['TrangThaiRequest'];
    index = json['index'];
  }

  Map<dynamic, dynamic> toJson() {
    final data = <dynamic, dynamic>{};
    data['KhoiLuong'] = khoiLuong;
    data['MaBuuGui'] = maBuuGui;
    data['Id'] = id;
    data['IsBlackList'] = isBlackList;
    data['TimeTrangThai'] = timeTrangThai;
    data['TrangThai'] = trangThai;
    data['index'] = index;
    data['Money'] = money;
    data['ListDo'] = listDo;
    data['TrangThaiRequest'] = trangThaiRequest;
    return data;
  }
}

class CountState {
  int? countChapNhan;
  int? countDangGom;
  int? countNhanHang;
  int? countPhanHuong;

  CountState(
      {this.countChapNhan,
      this.countDangGom,
      this.countNhanHang,
      this.countPhanHuong});

  CountState.fromJson(Map<dynamic, dynamic> json) {
    countChapNhan = json['countChapNhan'];
    countDangGom = json['countDangGom'];
    countNhanHang = json['countNhanHang'];
    countPhanHuong = json['countPhanHuong'];
  }

  Map<dynamic, dynamic> toJson() {
    final data = <dynamic, dynamic>{};
    data['countChapNhan'] = countChapNhan;
    data['countDangGom'] = countDangGom;
    data['countNhanHang'] = countNhanHang;
    data['countPhanHuong'] = countPhanHuong;
    return data;
  }
}
