# 📋 Hệ Thống Metadata JSON

## 🎯 Mục đích

Thay thế hệ thống cache phức tạp bằng metadata JSON đơn giản:
- **Lưu thông tin xử lý**: originalPath, compressedPath, maHieu, rotationAngle
- **Tăng tốc xử lý**: Tái sử dụng file compressed + mã hiệu đã đọc
- **Naming convention cố định**: `originalName_compressed.jpg` (không cần hash)
- **Tự động dọn dẹp**: Xóa file quá 7 ngày

## 📊 Cấu trúc Metadata

### ImageMetadata Model

```dart
class ImageMetadata {
  final String originalPath;      // Path file gốc
  final String compressedPath;    // Path file compressed
  final String? maHieu;           // Mã hiệu đã đọc (null nếu không có)
  final int rotationAngle;        // Góc xoay đã áp dụng
  final int lastModified;         // Timestamp file gốc
  final int processedAt;          // Timestamp xử lý
}
```

### Metadata JSON File

**Location**: `/temp/telegram_compressed/metadata.json`

**Format**:
```json
{
  "/storage/emulated/0/DCIM/IMG001.jpg:1733745600000": {
    "originalPath": "/storage/emulated/0/DCIM/IMG001.jpg",
    "compressedPath": "/data/user/0/.../telegram_compressed/IMG001_compressed.jpg",
    "maHieu": "ABC123",
    "rotationAngle": 90,
    "lastModified": 1733745600000,
    "processedAt": 1733745610000
  },
  "/storage/emulated/0/DCIM/IMG002.jpg:1733745650000": {
    "originalPath": "/storage/emulated/0/DCIM/IMG002.jpg",
    "compressedPath": "/data/user/0/.../telegram_compressed/IMG002_compressed.jpg",
    "maHieu": null,
    "rotationAngle": 0,
    "lastModified": 1733745650000,
    "processedAt": 1733745670000
  }
}
```

**Key Format**: `originalPath:lastModified`
- Đảm bảo uniqueness
- Phát hiện khi file gốc thay đổi

## 🔄 Workflow

### 1️⃣ Kiểm tra Metadata

```dart
final metadata = await ImageCacheService.instance.getMetadata(originalFile);

if (metadata != null) {
  // ✅ Có metadata
  print('MaHieu: ${metadata.maHieu}');
  final compressedFile = File(metadata.compressedPath);
  // Skip rotation, OCR, compression
} else {
  // ❌ Chưa có metadata
  // → Rotate → OCR → Compress → Save metadata
}
```

### 2️⃣ Xử lý và Lưu Metadata

```dart
// Rotate ảnh gốc
final rotatedFile = await rotateImage(originalFile, angle);

// Đọc mã hiệu
final maHieu = await extractMaHieu(rotatedFile);

// Compress và lưu metadata
final metadata = await ImageCacheService.instance.processAndSave(
  originalFile: originalFile,
  rotatedFile: rotatedFile,
  maHieu: maHieu,
  rotationAngle: angle,
);

// Kết quả
final compressedFile = File(metadata.compressedPath);
print('Compressed: ${metadata.compressedPath}');
print('MaHieu: ${metadata.maHieu}');
```

### 3️⃣ Upload

```dart
// File đã compressed, upload trực tiếp
await TelegramService.instance.uploadImage(compressedFile);
```

## 📂 Naming Convention

### Đơn giản, không dùng hash

- **File gốc**: `IMG_20231209_143022.jpg`
- **File compressed**: `IMG_20231209_143022_compressed.jpg`

### Ưu điểm
- ✅ Dễ debug: Nhìn tên file biết ngay nguồn gốc
- ✅ Không cần hash: Metadata JSON quản lý mapping
- ✅ Giảm độ phức tạp: Không cần tính toán hash

## 🗑️ Tự động Dọn dẹp

### Logic Cleanup (Auto chạy khi init)

```dart
await _cleanupOldFiles(); // Xóa file > 7 ngày
```

### Chi tiết
1. Duyệt qua tất cả metadata entries
2. Kiểm tra `processedAt < now - 7 days`
3. Xóa file compressed
4. Xóa entry khỏi metadata JSON
5. Lưu lại metadata

### Giữ lại bao lâu?
- **7 ngày**: Đủ dài để tái sử dụng trong workflow thực tế
- **Không vô thời hạn**: Tránh chiếm dụng storage

## 🚀 Performance

### So sánh với Cache cũ

| Metric | Cache cũ (hash-based) | Metadata JSON |
|--------|----------------------|---------------|
| **Key generation** | MD5 hash (slow) | String concat (fast) |
| **Cache hit check** | File exists check | JSON lookup + file exists |
| **Storage info** | Not available | Lưu maHieu, rotationAngle |
| **Debugging** | Hash không đọc được | Path rõ ràng |
| **Cleanup logic** | Date prefix parsing | processedAt timestamp |

### Ưu điểm Metadata JSON
1. **Lưu được maHieu**: Không mất thông tin khi file compressed
2. **Đơn giản hơn**: Không cần hash phức tạp
3. **Dễ debug**: Đọc JSON thấy ngay thông tin
4. **Mở rộng dễ**: Thêm field mới vào metadata không ảnh hưởng code cũ

## 📊 Cache Info

```dart
final info = await ImageCacheService.instance.getCacheInfo();
print('Files: ${info.fileCount}');
print('Size: ${info.formattedSize}'); // e.g., "45.2 MB"
```

## 🧹 Clear All

```dart
await ImageCacheService.instance.clearAll();
// Xóa toàn bộ: metadata.json + all compressed files
```

## 🔍 Example Use Case

### Scenario: Upload batch 20 ảnh, sau đó upload lại

#### Lần 1 (chưa có metadata):
```
[1/20] 🔍 Kiểm tra metadata: IMG001.jpg
[1/20] ⚙️ Chưa xử lý, bắt đầu...
[1/20] 🔄 Đang xoay ảnh: IMG001.jpg (500ms)
[1/20] 📖 Đang đọc mã hiệu: IMG001.jpg (300ms)
[1/20] 🗜️ Đang nén và lưu: IMG001.jpg (500ms)
```
**Total per image: ~1300ms**

#### Lần 2 (có metadata):
```
[1/20] 🔍 Kiểm tra metadata: IMG001.jpg
[1/20] ✅ Tìm thấy: ABC123
```
**Total per image: ~50ms** (96% faster! 🚀)

### Lợi ích thực tế
- **Lần 1**: 20 ảnh × 1300ms = 26 giây
- **Lần 2**: 20 ảnh × 50ms = 1 giây
- **Tiết kiệm**: 25 giây (96%)
- **Bonus**: Lấy lại được maHieu mà không cần OCR lại!

## 🎯 Key Benefits

1. ✅ **Lưu được maHieu**: Không mất thông tin sau compress
2. ✅ **Đơn giản**: Naming convention rõ ràng, không cần hash
3. ✅ **Nhanh**: JSON lookup + file exists (không cần compress/OCR lại)
4. ✅ **Dễ debug**: Path và thông tin dễ đọc
5. ✅ **Tự động cleanup**: Xóa file cũ > 7 ngày
6. ✅ **Mở rộng**: Thêm field mới không phá code cũ

## ⚠️ Important Notes

1. **Metadata key**: Dựa trên `originalPath + lastModified`
   - Nếu file gốc bị sửa → lastModified thay đổi → metadata miss → xử lý lại
   
2. **Compressed file check**: Luôn kiểm tra file compressed còn tồn tại
   - Nếu bị xóa thủ công → remove metadata entry
   
3. **Backward compatible**: TelegramService vẫn nhận `File` hoặc `ImageItem`
   - Assume file đã compressed từ controller

4. **No auto-delete**: File compressed KHÔNG tự xóa sau upload
   - Giữ lại để tái sử dụng
   - Tự động xóa sau 7 ngày
