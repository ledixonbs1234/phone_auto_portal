# 📦 Chức Năng Quét Barcode Theo Hướng

## 🎯 Mô Tả Chức Năng

Chức năng mới cho phép người dùng quét barcode để xử lý bưu gửi theo từng hướng cụ thể. Hệ thống sẽ tự động phân loại và xử lý bưu gửi dựa trên hướng đã chọn.

## 🚀 Cách Sử Dụng

### Bước 1: Chuẩn Bị Dữ Liệu
1. Vào trang **Portal Info**
2. Nhấn nút **"Chuẩn bị dữ liệu"** để hệ thống phân loại bưu gửi theo hướng
3. Hệ thống sẽ tự động phân loại các bưu gửi thành:
   - **RA**: Bưu gửi đi ra ngoài tỉnh
   - **VÔ**: Bưu gửi đi vào tỉnh
   - **Quảng Nam**: Bưu gửi thuộc tỉnh Quảng Nam
   - **Quảng Ngãi**: Bưu gửi thuộc tỉnh Quảng Ngãi

### Bước 2: Chọn Hướng
1. Trong dropdown **"Chọn hướng"**, chọn hướng mà bạn muốn xử lý
2. Hệ thống sẽ hiển thị số lượng bưu gửi trong hướng đó

### Bước 3: Bắt Đầu Quét
1. Nhấn nút **"Bắt đầu quét"**
2. Camera sẽ bật lên để quét barcode liên tục
3. Quét từng mã barcode trên bưu gửi

## 🔍 Kết Quả Quét

### ✅ Khi Quét Đúng Hướng
- Mã hiệu sẽ **biến mất** khỏi danh sách hướng đó
- Hiển thị thông báo **"Đã xử lý ✓"** màu xanh
- Có âm thanh/rung báo thành công

### ⚠️ Khi Quét Sai Hướng
- Hiển thị thông báo **"Có trong hướng: [Tên hướng]"** màu cam
- Mã hiệu được thêm vào **bảng danh sách bưu gửi không đúng hướng**

### ❌ Khi Không Tìm Thấy
- Hiển thị thông báo **"Không tìm thấy bưu gửi"** màu đỏ
- Mã hiệu được thêm vào **bảng danh sách bưu gửi không có**

## 📊 Theo Dõi Tiến Độ

### Thanh Tiến Độ
- Hiển thị **% hoàn thành** theo thời gian thực
- Cho biết **số lượng đã xử lý / tổng số** trong hướng

### Danh Sách Quét
- Hiển thị **lịch sử quét** trong session hiện tại
- Phân biệt màu sắc theo trạng thái:
  - 🟢 **Xanh**: Xử lý thành công
  - 🟠 **Cam**: Có trong hướng khác
  - 🔴 **Đỏ**: Không tìm thấy

## 🎛️ Các Nút Điều Khiển

### Trong Dialog Quét
- **Dừng**: Kết thúc session quét
- **Đèn flash**: Bật/tắt đèn flash camera
- **Kết quả**: Xem báo cáo chi tiết

### Báo Cáo Kết Quả
- **Tổng số quét**: Số lượng mã đã quét
- **Xử lý thành công**: Số mã đúng hướng
- **Không tìm thấy**: Số mã không có trong hệ thống
- **Tiến độ**: % hoàn thành

## 📋 Xuất Báo Cáo

### Danh Sách Lỗi
- Nhấn **"Xuất danh sách lỗi"** để xem chi tiết
- Hiển thị:
  - Mã barcode bị lỗi
  - Lý do lỗi (Không tìm thấy / Sai hướng)
  - Hướng thực tế (nếu có)

## ⚡ Tính Năng Nâng Cao

### 🔄 Quét Liên Tục
- Không cần nhấn nút sau mỗi lần quét
- Tự động xử lý khi phát hiện mã mới
- Loại bỏ mã trùng lặp

### 🎵 Phản Hồi Âm Thanh/Rung
- **Rung nhẹ**: Quét thành công
- **Rung mạnh**: Quét lỗi hoặc sai hướng

### 💾 Lưu Session
- Dữ liệu session được lưu trong bộ nhớ
- Có thể tiếp tục sau khi tạm dừng

## 🛠️ Cấu Trúc Code

### Models
- **`ScannedPackage`**: Lưu thông tin bưu gửi đã quét
- **`DirectionScanSession`**: Quản lý session quét theo hướng

### Controller Methods
- **`prepareDirectionData()`**: Chuẩn bị và phân loại dữ liệu
- **`startDirectionScan(direction)`**: Bắt đầu quét cho hướng
- **`_processDirectionScanResult(barcode)`**: Xử lý kết quả quét
- **`_showScanResults()`**: Hiển thị báo cáo kết quả

## 🐛 Xử Lý Lỗi

### Lỗi Camera
- Hiển thị thông báo lỗi rõ ràng
- Hướng dẫn cách khắc phục

### Lỗi Dữ Liệu
- Kiểm tra tính hợp lệ của dữ liệu tỉnh thành
- Fallback khi không load được dữ liệu

### Lỗi Kết Nối
- Xử lý trường hợp mất kết nối
- Lưu session cục bộ

## 🔧 Customization

### Thêm Hướng Mới
```dart
final availableDirections = [
  'RA', 
  'VÔ', 
  'Quảng Nam', 
  'Quảng Ngãi',
  'Hướng Mới' // Thêm hướng tại đây
].obs;
```

### Thay Đổi Màu Sắc
```dart
Color get statusColor {
  if (isFoundInCurrentDirection) {
    return Colors.green; // Thành công
  } else if (foundInDirection != null) {
    return Colors.orange; // Sai hướng
  } else {
    return Colors.red; // Không tìm thấy
  }
}
```

## 📞 Hỗ Trợ

Nếu gặp vấn đề khi sử dụng chức năng này, vui lòng liên hệ đội phát triển để được hỗ trợ.
