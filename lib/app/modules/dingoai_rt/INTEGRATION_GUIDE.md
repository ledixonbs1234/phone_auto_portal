# DiNgoaiRT Firebase Integration Guide

## Tổng quan

Module `dingoai_rt` được cập nhật để đồng bộ dữ liệu Real-time từ Firebase Database được gửi từ .NET WPF Application.

## Cấu trúc dữ liệu Firebase

### Firebase Path: `dingoai`

```json
{
  "dingoai": {
    "item1": {
      "Index": 1,
      "Code": "1234567890123",
      "TinhGocGui": "SG",
      "TinhDuKien": "HN",
      "BuuCucNhanTemp": "VTP-HN",
      "KhoiLuong": 500.5,
      "IsChuyenHoan": false,
      "MaTinh": "HN",
      "Address": "123 Nguyen Hue St, Hanoi",
      "MaBuuCuc": "VTP-HN-01",
      "TenBuuCuc": "Vietnam Post Hanoi",
      "IdCode": "ID-12345",
      "State": 0
    },
    "item2": {
      ...
    }
  }
}
```

### Model: DiNgoaiItemInfo

```dart
class DiNgoaiItemInfo {
  final int index;              // Sequential number (1-based)
  final String code;            // 13-digit barcode
  final String? tinhGocGui;     // Origin province
  final String? tinhDuKien;     // Expected destination
  final String? buuCucNhanTemp; // Postal office receiving code
  final double? khoiLuong;      // Weight in grams
  final bool isChuyenHoan;      // Return/exchange flag
  final String? maTinh;         // Province code
  final String? address;        // Recipient address
  final String? maBuuCuc;       // Postal office code
  final String? tenBuuCuc;      // Postal office name
  final String? idCode;         // Unique identifier
  final int state;              // 0=normal, 1=marked for action
  bool selected;                // UI selection state
}
```

## Các tính năng chính

### 1. Firebase Real-time Listening
- Tự động lắng nghe thay đổi từ Firebase node `dingoai`
- Parse dữ liệu vào `List<DiNgoaiItemInfo>`
- Cập nhật UI tự động khi có thay đổi

```dart
_listenToFirebaseUpdates() {
  _diNgoaiSubscription = _diNgoaiRef.onValue.listen(
    (DatabaseEvent event) {
      if (event.snapshot.exists) {
        _parseDiNgoaiData(event.snapshot.value);
      }
    },
  );
}
```

### 2. Refresh Data Button
- Button `Refresh` trong AppBar và Bottom Action Bar
- Gửi lệnh `refreshDiNgoai` lên Firebase để .NET App cập nhật
- Fetch dữ liệu mới từ Firebase

```dart
Future<void> refreshData() async {
  isLoading.value = true;
  stateText.value = 'Đang lấy dữ liệu từ Firebase...';
  
  // Gửi lệnh refresh lên Firebase
  FirebaseManager().addMessage(
    MessageReceiveModel("refreshDiNgoai", jsonEncode({...})),
  );
  
  // Đọc dữ liệu từ Firebase
  final snapshot = await _diNgoaiRef.get();
  _parseDiNgoaiData(snapshot.value);
}
```

### 3. Commands to .NET App

Gửi các lệnh qua Firebase để .NET App xử lý:

#### Delete Command
```dart
FirebaseManager().addMessage(
  MessageReceiveModel("xoanhieubg", jsonEncode(idCodes))
);
```

#### Go Outside (DiNgoaiRT) Command
```dart
FirebaseManager().addMessage(
  MessageReceiveModel("dingoaiRT", jsonEncode({
    "codes": codes,
    "auto": isAuto.value,
    "print": isPrint.value,
  }))
);
```

#### Refresh Command
```dart
FirebaseManager().addMessage(
  MessageReceiveModel("refreshDiNgoai", jsonEncode({
    "timestamp": DateTime.now().toString()
  }))
);
```

## Lifecycle Management

### onInit()
- Khởi tạo Firebase Database reference
- Bắt đầu lắng nghe Real-time updates

### onClose()
- Hủy Firebase stream subscription
- Giải phóng tài nguyên

```dart
@override
void onClose() {
  _diNgoaiSubscription?.cancel();
  super.onClose();
}
```

## UI Components

### AppBar Actions
- **Refresh Button** (🔄): Load dữ liệu mới từ Firebase
- **Select/Deselect All**: Chọn/bỏ chọn tất cả items

### Bottom Action Bar Buttons
1. **Refresh** (Orange): Lấy dữ liệu từ Firebase
2. **Xóa** (Red): Xóa items được chọn
3. **Auto** (Blue): Xử lý go outside RT

### Status Display
- Hiển thị trạng thái: `Đang lấy dữ liệu từ Firebase...`
- Đếm tổng items từ danh sách
- Đếm items từ Firebase
- Đếm items đã chọn

## Error Handling

### Firebase Connection Errors
```dart
onError: (error) {
  Get.snackbar(
    'Lỗi',
    'Không thể kết nối Firebase: $error',
    backgroundColor: Colors.red,
  );
}
```

### Data Parsing Errors
```dart
catch (e) {
  Get.snackbar(
    'Lỗi',
    'Lỗi xử lý dữ liệu: $e',
    backgroundColor: Colors.red,
  );
}
```

## .NET WPF App Integration Points

1. **Data Write**: Viết dữ liệu vào `dingoai` node trong Firebase
2. **Command Listen**: Lắng nghe các commands từ Flutter
   - `xoanhieubg`: Delete items
   - `dingoaiRT`: Go outside RT
   - `refreshDiNgoai`: Refresh request

3. **Method**: `XuLyLenhGuiVeAsync` xử lý các commands

## Debugging Tips

### Monitor Firebase Data
```dart
// Print data changes
void _parseDiNgoaiData(dynamic data) {
  print('Received data: $data');
  print('Items count: ${newItems.length}');
}
```

### Check Stream Subscriptions
```dart
// Verify stream is active
if (_diNgoaiSubscription != null) {
  print('Firebase stream is active');
}
```

### Test Refresh
1. Nhấn Refresh button
2. Check AppBar loading spinner
3. Verify bottom status text updates
4. Check console logs

## Example Firebase Structure

```json
{
  "dingoai": {
    "di-ng-001": {
      "Index": 1,
      "Code": "1234567890123",
      "TinhGocGui": "SG",
      "TinhDuKien": "HN",
      "BuuCucNhanTemp": "VTP-HN",
      "KhoiLuong": 500.5,
      "IsChuyenHoan": false,
      "MaTinh": "10",
      "Address": "123 Nguyen Hue, Hanoi",
      "MaBuuCuc": "100101",
      "TenBuuCuc": "VTP Hoan Kiem",
      "IdCode": "ID-12345",
      "State": 0
    },
    "di-ng-002": {
      "Index": 2,
      "Code": "1234567890124",
      "TinhGocGui": "HCM",
      "TinhDuKien": "DN",
      "BuuCucNhanTemp": "VTP-DN",
      "KhoiLuong": 750.0,
      "IsChuyenHoan": true,
      "MaTinh": "20",
      "Address": "456 Tran Hung Dao, HCMC",
      "MaBuuCuc": "700103",
      "TenBuuCuc": "VTP District 1",
      "IdCode": "ID-12346",
      "State": 1
    }
  }
}
```

## Performance Considerations

1. **Real-time Sync**: Tự động đồng bộ mà không cần user action
2. **Refresh Button**: Manual fetch cho phép user kiểm soát timing
3. **Loading State**: UI indicator shows when fetching
4. **Memory**: Items list cleared khi parse data mới

## Files Modified/Created

- ✅ `controllers/dingoai_rt_controller.dart` - Updated with Firebase logic
- ✅ `models/di_ngoai_item_info.dart` - New model class
- ✅ `views/dingoai_rt_view.dart` - Updated with Refresh button
- ✅ `views/widgets/firebase_data_view.dart` - New widget to display Firebase data
- ✅ `INTEGRATION_GUIDE.md` - This guide

## Next Steps

1. Test Firebase connection
2. Verify .NET App writes data to `dingoai` node
3. Monitor command handling in .NET
4. Add any custom field mappings if needed
