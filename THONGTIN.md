# THONGTIN.md

## 📋 TỔNG HỢP KHẢO SÁT MÃ NGUỒN

### 🎯 Mục tiêu
- Thêm chức năng chia sẻ mã hiệu qua Zalo khi nhận message với `Lenh == "mahieubd10"`
- Gửi mã hiệu mà không cần mở app Zalo

### 🔍 Cấu trúc dự án

| Thành phần | File | Chi tiết |
|-----------|------|---------|
| **Model** | `lib/app/modules/home/messageReceiveModel.dart` | Class `MessageReceiveModel`: thuộc tính `Lenh`, `DoiTuong` (mã hiệu), `TimeStamp`, `NameMay`, `username`, `password` |
| **Xử lý Message** | `lib/data/firebaseManager.dart` dòng 175-187 | Phát hiện `mahieubd10` → tạo notification qua `AwesomeNotifications()` với payload `{"code": message.DoiTuong}` |
| **Xử lý Notification** | `lib/data/notification_controller.dart` dòng 33-47 | Copy code vào clipboard → Launch app "STM Max" qua MethodChannel |
| **Native Android** | `android/app/src/main/kotlin/.../MainActivity.kt` | MethodChannel `launchApp` hỗ trợ mở ứng dụng khác |
| **Dependencies** | `pubspec.yaml` | Có `url_launcher: ^6.3.1` (hiện dùng cho `tel:` scheme) |

### ⚠️ Vấn đề hiện tại
- **Chỉ có**: Notification + Copy code + Mở STM Max
- **Thiếu**: Chia sẻ mã hiệu qua Zalo
- **Yêu cầu**: Không mở app Zalo, sử dụng share intent

### 🔗 Giải pháp khả dụng
- **Deep link Zalo**: `zalo://chat?phone=...` hoặc `zalo://send?phone=...`
- **Share Intent**: ACTION_SEND với MIME type `text/plain`
- **Package Zalo**: `com.zing.zalo`
- **url_launcher**: Có thể dùng trực tiếp cho deep links

### 📝 Dữ liệu đầu vào
- `Message.DoiTuong` = mã hiệu cần gửi
- Số điện thoại Zalo người nhận (cần lưu cấu hình)

### ✅ Trạng thái
Khảo sát hoàn tất - Sẵn sàng triển khai