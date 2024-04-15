class Dingoaicodes {
  bool? isSorted;
  bool isPrinted = false;
  List<String>? codes;

  Dingoaicodes({this.isSorted, this.codes, this.isPrinted = false});

  Dingoaicodes.fromJson(Map<dynamic, dynamic> json) {
    isSorted = json['isSorted'];
    isPrinted = json['isPrinted'];
    codes = json['codes'].cast<String>();
  }

  Map<dynamic, dynamic> toJson() {
    final data = <dynamic, dynamic>{};
    data['isSorted'] = isSorted;
    data['codes'] = codes;
    data['isPrinted'] = isPrinted;
    return data;
  }
}
