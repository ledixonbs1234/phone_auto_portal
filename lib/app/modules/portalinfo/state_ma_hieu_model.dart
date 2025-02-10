class StateMaHieu {
  String? iD;
  String? code;
  String? state;
  String? IDCODE;
  String? Weight;
  String? Name;
  String? Address;
  String? Date;

  StateMaHieu(
      {this.iD,
      this.code,
      this.state,
      this.IDCODE,
      this.Weight,
      this.Name,
      this.Date,
      this.Address});

  StateMaHieu.fromJson(Map<dynamic, dynamic> json) {
    iD = json['ID'];
    code = json['Code'];
    state = json['State'];
    IDCODE = json['IDCODE'];
    Weight = json['Weight'];
    Name = json['Name'];
    Address = json['Address'];
    if (json['Date'] != null) {
      DateTime parsedDate = DateTime.parse(json['Date']).add(const Duration(hours: 7));
      Date =
          "${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}:${parsedDate.second.toString().padLeft(2, '0')}";
    }
  }

  Map<dynamic, dynamic> toJson() {
    final data = <dynamic, dynamic>{};
    data['ID'] = iD;
    data['Code'] = code;
    data['State'] = state;
    data['IDCODE'] = IDCODE;
    return data;
  }
}
