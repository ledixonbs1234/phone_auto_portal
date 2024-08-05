class SplitAddress {
  String code;
  String name;
  String address;
  SplitAddress(this.code, this.address, this.name);
  Map<String, dynamic> toJson() {
    return {
      'Code': code,
      'Name': name,
      'Address': address,
    };
  }
}
