class Customer {
  String maKH;
  String tenKH;
  bool isChooseHopDong;
  int sttHopDong;
  String address;

  Customer({
    required this.maKH,
    required this.tenKH,
    this.isChooseHopDong = false,
    this.sttHopDong = 0,
    this.address = '',
  });

  factory Customer.fromJson(dynamic key, Map<dynamic, dynamic> json) {
    return Customer(
      maKH: json['MaKH'] ?? key.toString(),
      tenKH: json['TenKH'] ?? '',
      isChooseHopDong: json['IsChooseHopDong'] == true,
      sttHopDong: json['STTHopDong'] ?? 0,
      address: json['Address'] ?? '',
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      'MaKH': maKH,
      'TenKH': tenKH,
      'IsChooseHopDong': isChooseHopDong,
      'STTHopDong': sttHopDong,
      'Address': address,
    };
  }
}
