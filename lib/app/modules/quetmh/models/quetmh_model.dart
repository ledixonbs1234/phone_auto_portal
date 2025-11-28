class QuetMHModel {
  String? maHieu;
  String? timestamp;

  QuetMHModel({
    this.maHieu,
    this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'maHieu': maHieu,
      'timestamp': timestamp,
    };
  }

  factory QuetMHModel.fromJson(Map<String, dynamic> json) {
    return QuetMHModel(
      maHieu: json['maHieu'],
      timestamp: json['timestamp'],
    );
  }
}
