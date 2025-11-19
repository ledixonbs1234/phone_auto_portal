class MessageReceiveModel {
  late String Lenh;
  late String TimeStamp;
  late String DoiTuong;
  late String NameMay;
  String? username;
  String? password;
  MessageReceiveModel(String lenh, String doiTuong,
      {String nameMay = "maychu", this.username, this.password}) {
    Lenh = lenh;
    TimeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    DoiTuong = doiTuong;
    NameMay = nameMay;
  }

  MessageReceiveModel.fromJson(Map<dynamic, dynamic> json)
      : Lenh = json['Lenh'],
        TimeStamp = json['TimeStamp'],
        DoiTuong = json['DoiTuong'],
        NameMay = json['NameMay'] ?? "",
        username = json['username'],
        password = json['password'];
  Map<dynamic, dynamic> toJson() => {
        'Lenh': Lenh,
        'TimeStamp': TimeStamp,
        'DoiTuong': DoiTuong,
        'NameMay': NameMay,
        'username': username,
        'password': password
      };
}
