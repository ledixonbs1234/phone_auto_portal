class MessageReceiveModel {
  late String Lenh;
  late String TimeStamp;
  late String DoiTuong;
  MessageReceiveModel(String lenh, String doiTuong) {
    Lenh = lenh;
    TimeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    DoiTuong = doiTuong;
  }

  MessageReceiveModel.fromJson(Map<dynamic, dynamic> json)
      : Lenh = json['Lenh'],
        TimeStamp = json['TimeStamp'],
        DoiTuong = json['DoiTuong'];
  Map<dynamic, dynamic> toJson() =>
      {'Lenh': Lenh, 'TimeStamp': TimeStamp, 'DoiTuong': DoiTuong};
}
