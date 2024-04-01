class Dingoaicodes {
  bool? isSorted;
  List<String>? codes;

  Dingoaicodes({this.isSorted, this.codes});

  Dingoaicodes.fromJson(Map<dynamic, dynamic> json) {
    isSorted = json['isSorted'];
    codes = json['codes'].cast<String>();
  }

  Map<dynamic, dynamic> toJson() {
    final data = <dynamic, dynamic>{};
    data['isSorted'] = isSorted;
    data['codes'] = codes;
    return data;
  }
}
