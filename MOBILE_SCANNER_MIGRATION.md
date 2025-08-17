# Migration từ flutter_barcode_scanner sang mobile_scanner

## Thay đổi đã thực hiện

### 1. Cập nhật pubspec.yaml
- Xóa: `flutter_barcode_scanner: ^2.0.0`
- Thêm: `mobile_scanner: ^5.0.0`

### 2. Cập nhật PortalinfoController

#### Import changes:
```dart
// Cũ
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

// Mới
import 'package:mobile_scanner/mobile_scanner.dart';
```

#### Thêm variables:
```dart
// Mobile Scanner Controller
late MobileScannerController mobileScannerController;
StreamSubscription<BarcodeCapture>? _barcodeSubscription;
```

#### Cập nhật hàm startBulkQRScanInDialog():
- Thay thế `FlutterBarcodeScanner.getBarcodeStreamReceiver()` bằng `mobileScannerController.barcodes.listen()`
- Thêm dialog hiển thị scanner camera
- Thêm các nút điều khiển (Đóng, Đèn flash)

#### Cập nhật hàm scanBarcode():
- Tương tự như startBulkQRScanInDialog(), sử dụng mobile_scanner thay vì flutter_barcode_scanner
- Thêm dialog hiển thị camera cho continuous scanning

#### Thêm các hàm mới:
- `_showMobileScannerDialog()`: Hiển thị dialog scanner cho bulk scanning
- `_showContinuousScannerDialog()`: Hiển thị dialog scanner cho continuous scanning

### 3. Cập nhật CreatenewController

#### Import changes:
```dart
// Cũ
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

// Mới
import 'package:mobile_scanner/mobile_scanner.dart';
```

#### Thêm variables:
```dart
// Mobile Scanner Controller
late MobileScannerController mobileScannerController;
StreamSubscription<BarcodeCapture>? onListenBarcode;
```

#### Cập nhật hàm addKhachHangAsQR():
- Thay thế `FlutterBarcodeScanner.getBarcodeStreamReceiver()` bằng `mobileScannerController.barcodes.listen()`
- Thêm dialog hiển thị scanner camera
- Thêm các nút điều khiển (Dừng, Đèn flash)

#### Thêm hàm mới:
- `_showMobileScannerDialogForCreatenew()`: Hiển thị dialog scanner cho việc tạo mới

### 4. Cleanup và Dispose
- Thêm `mobileScannerController.dispose()` trong các hàm `onClose()` của cả hai controllers
- Đảm bảo cancel subscription khi không sử dụng

## Lợi ích của mobile_scanner

1. **Hiệu suất tốt hơn**: mobile_scanner được tối ưu hóa và có hiệu suất tốt hơn
2. **Cập nhật thường xuyên**: Thư viện được maintain và cập nhật thường xuyên
3. **UI tốt hơn**: Có thể tùy chỉnh UI scanner dễ dàng hơn
4. **Nhiều định dạng**: Hỗ trợ nhiều định dạng barcode/QR code
5. **Ít lỗi**: Ít gặp vấn đề về tương thích và bugs

## Cách sử dụng

Sau khi migration, các chức năng quét QR/barcode vẫn hoạt động như cũ nhưng với giao diện scanner mới:

1. **Trong PortalInfo**: Nhấn nút "Quét hàng loạt" để quét nhiều mã
2. **Trong CreateNew**: Nhấn nút QR để quét mã cho bưu gửi
3. **Continuous Scanning**: Nhấn nút "Quét" để quét liên tục

## Ghi chú
- Đảm bảo camera permission được cấp
- Thư viện mobile_scanner tự động xử lý camera lifecycle
- Dialog scanner có thể đóng bằng cách nhấn nút "Đóng" hoặc "Dừng"
