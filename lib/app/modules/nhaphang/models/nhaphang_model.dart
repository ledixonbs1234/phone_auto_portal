class NhapHangModel {
  String tenNguoiNhan;
  String soDienThoai;
  String diaChi;
  String dichVu;
  double khoiLuong;
  double cod;
  String noiDungBG;

  NhapHangModel({
    this.tenNguoiNhan = '',
    this.soDienThoai = '',
    this.diaChi = '',
    this.dichVu = '',
    this.khoiLuong = 0,
    this.cod = 0,
    this.noiDungBG = '',
  });

  Map<String, dynamic> toJson() => {
        'TenNguoiNhan': tenNguoiNhan,
        'SoDienThoai': soDienThoai,
        'DiaChi': diaChi,
        'DichVu': dichVu,
        'KhoiLuong': khoiLuong,
        'COD': cod,
        'NoiDungBG': noiDungBG,
      };
}
