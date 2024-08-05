class PortalCheck {
  String? iD;
  String? code;
  bool? isDongCT;

  PortalCheck({this.iD, this.code, this.isDongCT});

  PortalCheck.fromJson(Map<String, dynamic> json) {
    iD = json['ID'];
    code = json['Code'];
    isDongCT = json['IsDongCT'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['ID'] = iD;
    data['Code'] = code;
    data['IsDongCT'] = isDongCT;
    return data;
  }
}
