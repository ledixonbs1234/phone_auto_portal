# Import Images Module

Module cho phép import ảnh từ thư viện, tự động xử lý và upload lên Firebase.

## Tính năng

1. **Chọn ảnh từ thư viện**
   - Chọn nhiều ảnh cùng lúc
   - Lọc chỉ ảnh được chụp hôm nay

2. **Phân loại theo Batch**
   - Tự động nhóm ảnh theo thời gian (cách nhau 2 phút)
   - Hiển thị số lượng ảnh trong mỗi batch

3. **Xử lý ảnh tự động**
   - Detect hướng chữ trong ảnh (ML Kit Text Recognition)
   - Tự động xoay ảnh về đúng hướng (0°, 90°, 180°, 270°)
   - Compress ảnh trước khi upload

4. **Đọc mã hiệu**
   - Ưu tiên: Barcode Scanner
   - Fallback: OCR (ML Kit Text Recognition)
   - Validate mã hiệu theo pattern: `^[cCreEpP][a-zA-Z]\d{9}[vV][nN]$`

5. **Upload Firebase**
   - Upload ảnh lên Firebase Storage
   - Lưu metadata vào Realtime Database
   - Theo dõi progress upload

## Workflow

```
1. Chọn ảnh từ thư viện
   ↓
2. Phân loại thành batch (theo thời gian)
   ↓
3. Chọn batch để xử lý
   ↓
4. Xử lý từng ảnh:
   - Detect & Rotate (về đúng hướng)
   - Compress
   - Read Barcode/OCR (đọc mã hiệu)
   - Validate mã hiệu
   - Upload lên Firebase
   ↓
5. Sync metadata với Realtime Database
```

## Cấu trúc Firebase

### Firebase Storage
```
images/
  └── {date}/                    (VD: 2025-12-07)
      └── {batch_id}/           (UUID)
          ├── {image_id_1}.jpg
          ├── {image_id_2}.jpg
          └── ...
```

### Realtime Database

#### 1. Imported Images (cho Chrome Extension)
```json
{
  "imported_images": {
    "2025-12-07": {
      "batch_12h20_uuid": {
        "image_uuid_1": {
          "url": "https://storage.googleapis.com/...",
          "maHieu": "CA1234567890VN",
          "timestamp": 1733562000000,
          "processed": true,
          "uploadedAt": 1733562100000
        },
        "image_uuid_2": {
          "url": "https://...",
          "maHieu": "RA9876543210VN",
          "timestamp": 1733562030000,
          "processed": true,
          "uploadedAt": 1733562110000
        }
      }
    }
  }
}
```

#### 2. Batch Metadata
```json
{
  "imported_batches": {
    "2025-12-07": {
      "batch_12h20_uuid": {
        "startTime": 1733562000000,
        "endTime": 1733562120000,
        "totalImages": 5,
        "processedImages": 5,
        "uploadedAt": 1733562200000,
        "status": "completed"
      }
    }
  }
}
```

## Cách sử dụng cho Chrome Extension

### 1. Query ảnh theo ngày
```javascript
const date = '2025-12-07';
const ref = firebase.database().ref(`imported_images/${date}`);

ref.once('value', (snapshot) => {
  const batches = snapshot.val();
  
  Object.keys(batches).forEach(batchId => {
    const batch = batches[batchId];
    
    Object.keys(batch).forEach(imageId => {
      const image = batch[imageId];
      console.log('URL:', image.url);
      console.log('Mã hiệu:', image.maHieu);
      
      // Download image
      downloadImage(image.url, image.maHieu);
    });
  });
});
```

### 2. Listen realtime updates
```javascript
const ref = firebase.database().ref('imported_images');

ref.on('child_added', (snapshot) => {
  console.log('New batch uploaded:', snapshot.key);
  // Process new images...
});
```

### 3. Filter theo mã hiệu
```javascript
const ref = firebase.database().ref(`imported_images/${date}`);

ref.once('value', (snapshot) => {
  const images = [];
  snapshot.forEach(batchSnapshot => {
    batchSnapshot.forEach(imageSnapshot => {
      const img = imageSnapshot.val();
      if (img.processed && img.maHieu) {
        images.push(img);
      }
    });
  });
  
  console.log('Processed images:', images);
});
```

## API Reference

### Models

#### ImageItem
```dart
class ImageItem {
  final String id;
  final File file;
  final DateTime timestamp;
  String? maHieu;
  String? firebaseUrl;
  int rotationAngle;
  ImageProcessingStatus status;
}
```

#### ImageBatch
```dart
class ImageBatch {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final List<ImageItem> images;
  bool isSelected;
  BatchStatus status;
}
```

### Services

#### ImageBatchService
- `pickImages()`: Chọn ảnh từ thư viện
- `filterTodayImages()`: Lọc ảnh hôm nay
- `createBatches()`: Tạo batch từ ảnh

#### ImageProcessingService
- `detectTextOrientation()`: Detect hướng chữ
- `rotateImage()`: Xoay ảnh
- `compressImage()`: Compress ảnh
- `processImage()`: Workflow hoàn chỉnh

#### BarcodeOcrService
- `readBarcodeFromImage()`: Đọc barcode
- `readTextFromImage()`: OCR text
- `isValidMaHieu()`: Validate mã hiệu
- `readMaHieu()`: Workflow hoàn chỉnh

#### ImageUploadService
- `uploadImageToStorage()`: Upload lên Storage
- `saveImageMetadata()`: Lưu metadata
- `uploadBatchMetadata()`: Upload batch info
- `uploadImageWithMetadata()`: Workflow hoàn chỉnh

## Validation Pattern

Mã hiệu hợp lệ phải match pattern:
```regex
^[cCreEpP][a-zA-Z]\d{9}[vV][nN]$
```

Ví dụ hợp lệ:
- `CA1234567890VN`
- `ra9876543210vn`
- `EP5555555555VN`

## Error Handling

Module có retry mechanism cho các lỗi:
- Lỗi xử lý ảnh → Hiển thị trong UI
- Lỗi đọc mã hiệu → Vẫn upload (maHieu = null)
- Lỗi upload → Retry button

## Performance

- Compress ảnh: quality 85%, max 1920x1080
- Batch processing: Xử lý tuần tự từng ảnh
- Upload progress: Real-time tracking
- ML Kit: Dispose sau khi xong

## Dependencies

```yaml
dependencies:
  image_picker: ^1.1.2
  google_mlkit_text_recognition: latest
  flutter_image_compress: latest
  mobile_scanner: ^5.2.3
  firebase_storage: latest
  firebase_database: latest
  uuid: ^3.0.7
  image: ^4.5.4
  intl: latest
```

## Screenshots

### 1. Empty State
Hiển thị khi chưa có ảnh

### 2. Batch List
Danh sách các batch với thông tin:
- Thời gian (12:20 - 12:21)
- Số lượng (5 ảnh)
- Progress bar
- Preview thumbnails

### 3. Processing
- Status: Rotating, Reading, Uploading
- Progress: 3/5 ảnh
- Error count

### 4. Completed
- Hiển thị mã hiệu đã đọc được
- Upload thành công
