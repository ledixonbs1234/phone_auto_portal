class StateMaHieu {
  String? iD;
  String? code;
  String? state;
  String? IDCODE;
  String? Weight;
  String? Name;
  String? Address;

  StateMaHieu(
      {this.iD,
      this.code,
      this.state,
      this.IDCODE,
      this.Weight,
      this.Name,
      this.Address});

  StateMaHieu.fromJson(Map<dynamic, dynamic> json) {
    iD = json['ID'];
    code = json['Code'];
    state = json['State'];
    IDCODE = json['IDCODE'];
    this.Weight = json['Weight'];
    this.Name = json['Name'];
    this.Address = json['Address'];
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
