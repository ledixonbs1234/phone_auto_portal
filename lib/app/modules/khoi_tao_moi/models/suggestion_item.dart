class SuggestionItem {
  final String maBuuGui;
  final String maKH;
  final String tenKH;
  final int? khoiLuong;

  SuggestionItem({
    required this.maBuuGui,
    required this.maKH,
    required this.tenKH,
    this.khoiLuong,
  });

  @override
  String toString() => '$maBuuGui - $tenKH';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SuggestionItem &&
        other.maBuuGui == maBuuGui &&
        other.maKH == maKH;
  }

  @override
  int get hashCode => maBuuGui.hashCode ^ maKH.hashCode;
}
