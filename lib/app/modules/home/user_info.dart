// lib/app/modules/home/user_info.dart
class UserInfo {
  // final String key; // Thêm nếu key RTDB không phải là username
  final String name;
  final String username;
  final String password;

  UserInfo({
    // required this.key,
    required this.name,
    required this.username,
    required this.password,
  });

  // Giữ nguyên toJson, fromJson, operator==, hashCode, toString từ lần trước
  // Hoặc điều chỉnh fromJson nếu cần đọc từ cấu trúc RTDB
  factory UserInfo.fromJson(String rtdbKey, Map<dynamic, dynamic> json) {
    return UserInfo(
      // key: rtdbKey,
      name: json['name'] ??
          rtdbKey, // Lấy tên, nếu không có thì dùng tạm key/username
      username: json['username'] ?? '',
      password: json['password'] ?? '', // Lấy mật khẩu
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'password': password,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserInfo &&
        // other.key == key && // So sánh cả key nếu dùng
        other.name == name &&
        other.username == username &&
        other.password == password;
  }

  @override
  int get hashCode =>
      // key.hashCode ^ // Hash cả key nếu dùng
      name.hashCode ^ username.hashCode ^ password.hashCode;

  @override
  String toString() {
    return name.isNotEmpty
        ? name
        : (username.isNotEmpty ? username : 'Không rõ');
  }
}
