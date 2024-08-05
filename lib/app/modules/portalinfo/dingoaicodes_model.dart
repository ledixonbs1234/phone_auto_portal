class Dingoaicodes {
  bool? isSorted;
  bool isPrinted = false;
  bool isAutoBD = false;
  List<String>? codes;
  List<String>? codeIDs;

  Dingoaicodes(
      {this.isSorted,
      this.codes,
      this.codeIDs,
      this.isPrinted = false,
      this.isAutoBD = false});

  Dingoaicodes.fromJson(Map<dynamic, dynamic> json) {
    isSorted = json['isSorted'];
    isPrinted = json['isPrinted'];
    isAutoBD = json['isAutoBD'];
    codes = json['codes'].cast<String>();
    codes = json['codeIDs'].cast<String>();
  }

  Map<dynamic, dynamic> toJson() {
    final data = <dynamic, dynamic>{};
    data['isSorted'] = isSorted;
    data['codes'] = codes;
    data['isAutoBD'] = isAutoBD;
    data['isPrinted'] = isPrinted;
    data['codeIDs'] = codeIDs;
    return data;
  }
}
