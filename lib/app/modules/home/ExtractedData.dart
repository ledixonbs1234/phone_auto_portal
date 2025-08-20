// Một lớp để chứa kết quả đã được phân tích cú pháp.
class ExtractedData {
  final String? maHieu;
  final String? tenNguoiNhan;
  final String? diaChi;
  final String? soDienThoai;

  ExtractedData(
      {this.maHieu, this.tenNguoiNhan, this.diaChi, this.soDienThoai});

  factory ExtractedData.fromJson(Map<String, dynamic> json) {
    return ExtractedData(
      maHieu: json['maHieu'],
      tenNguoiNhan: json['tenNguoiNhan'],
      diaChi: json['diaChi'],
      soDienThoai: json['soDienThoai'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'maHieu': maHieu,
      'tenNguoiNhan': tenNguoiNhan,
      'diaChi': diaChi,
      'soDienThoai': soDienThoai,
    };
  }

  @override
  String toString() {
    return 'Mã hiệu: $maHieu, Tên: $tenNguoiNhan, Địa chỉ: $diaChi, SĐT: $soDienThoai';
  }
}
