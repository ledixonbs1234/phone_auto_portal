# Phone Auto Portal - Hướng Dẫn Khảo Sát & Kiến Trúc Dự Án (Walkthrough)

## 1. Tổng Quan & Công Nghệ Cốt Lõi (Overview & Tech Stack)

- **Mục tiêu:** Phone Auto Portal là ứng dụng di động & đa nền tảng tối ưu hóa quy trình nghiệp vụ bưu chính, chuyển phát (Vietnam Post / VNPost / PNS / MyVNPost / TMS). Ứng dụng cung cấp khả năng quét mã vạch bưu gửi siêu tốc, nhận dạng ký tự quang học (OCR), trích xuất thông tin người nhận bằng Google Gemini AI, tự động hóa tương tác ứng dụng bưu điện (TMS BD10) qua Android Accessibility Service, đồng bộ dữ liệu thời gian thực 2 chiều với hệ thống máy tính/portal máy chủ qua Firebase Realtime Database, và phát âm thanh hỗ trợ phân loại hàng hóa thông minh.
- **Ngôn ngữ & Runtime:** 
  - [Dart SDK](https://dart.dev/) `>= 3.3.0 < 4.0.0`
  - [Flutter Framework](https://flutter.dev/) `>= 3.3.0`
- **Phiên bản hiện tại:** `1.2.3+86`
- **Nền tảng hỗ trợ:** Android (nền tảng cốt lõi), iOS, Web, Windows, macOS, Linux.
- **Frameworks & Thư viện lõi:**
  - **Quản lý trạng thái & Điều hướng:** `get: ^4.6.6` (GetX Pattern: State Management, Dependency Injection, Named Routing).
  - **Dịch vụ Đám mây & Đồng bộ Realtime:** `firebase_core: ^4.0.0`, `firebase_database: 12.0.0`, `firebase_storage: ^13.0.6`, `firebase_ai: ^3.1.0`.
  - **Lưu trữ Cục bộ & Đám mây Bổ trợ:** `get_storage: 2.1.1`, [Supabase Storage](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/data/supabase_storage_service.dart), [Telegram Bot API Service](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/data/telegram_service.dart).
  - **Trí tuệ nhân tạo & Thị giác máy tính (AI & ML):** Google Gemini Flash API (`GeminiChatService`), `google_mlkit_text_recognition: ^0.15.0`, `google_mlkit_barcode_scanning: ^0.14.1`, `mobile_scanner: ^5.0.0`.
  - **Xử lý Media & Âm thanh:** `camera: ^0.10.5+9`, `image_picker: ^1.0.7`, `flutter_image_compress: ^2.4.0`, `image: ^4.5.4`, `just_audio: ^0.9.39` (hệ thống hơn 100 tệp âm thanh số đếm và cảnh báo), `gal: ^2.3.2`.
  - **Tự động hóa Hệ thống & Native Channel:** `awesome_notifications: ^0.10.1`, `tms_automation_bridge.dart` (MethodChannel Accessibility Service & Volume Button Hooks), `share_plus: ^12.0.2`, `url_launcher: ^6.3.1`, `open_filex: ^4.5.0`, `permission_handler: ^11.3.1`, `wakelock_plus: ^1.2.8`.
  - **Giao diện & Tiện ích:** `data_table_2: 2.5.11`, `group_button: 5.3.4`, `msh_checkbox: 2.0.1`, `autocomplete_textfield: 2.0.1`, `intl: ^0.20.2`, `dio: ^5.8.0+1`.

---

## 2. Kiến Trúc Hệ Thống & Luồng Hoạt Động (Architecture & Data Flow)

### 2.1 Mô Hình Kiến Trúc (Architectural Pattern)
Dự án được xây dựng theo mô hình **GetX + MVC (Model - View - Controller)** kết hợp với **Service Layer** và kiến trúc hướng sự kiện **Event-Driven Realtime**:
- **View (`lib/app/modules/*/views/`):** Xây dựng bằng `GetView<TController>` hoặc `StatelessWidget`, phản hồi giao diện tức thì theo dữ liệu phản ứng (`Obx`).
- **Controller (`lib/app/modules/*/controllers/`):** Kế thừa `GetxController`, xử lý toàn bộ logic nghiệp vụ, quản lý biến quan sát (`Rx`, `.obs`), vòng đời `onInit()`, `onReady()`, `onClose()`.
- **Binding (`lib/app/modules/*/bindings/`):** Đăng ký Dependency Injection thông qua `BindingsBuilder` hoặc `Bindings` (sử dụng `Get.lazyPut`).
- **Service Layer (`lib/data/`):** Chứa các Singleton Services xử lý giao tiếp mạng, cơ sở dữ liệu Firebase, bộ nhớ đệm hình ảnh và bridge với hệ điều hành Android.

```
┌───────────────────────────────────────────────────────────────────────────┐
│                          UI Layer (GetView / Obx)                         │
└─────────────────────────────────────┬─────────────────────────────────────┘
                                      │ User Actions / Reactive Bindings
┌─────────────────────────────────────▼─────────────────────────────────────┐
│                    Business Logic Layer (GetxController)                  │
│       (HomeController, KhoiTaoMoiController, ImageImportController...)    │
└──────────────┬──────────────────────┬──────────────────────┬──────────────┘
               │                      │                      │
┌──────────────▼───────┐ ┌────────────▼───────────┐ ┌────────▼──────────────┐
│ FirebaseManager      │ │ Image & ML Services    │ │ Native Automation      │
│ - Realtime DB Sync   │ │ - Barcode / OCR ML Kit │ │ - TMS Automation Bridge│
│ - Message Dispatcher │ │ - Gemini AI Extraction │ │ - AwesomeNotifications │
│ - Host / Client Node │ │ - Cache & Cloud Upload │ │ - MethodChannel Call   │
└──────────────────────┘ └────────────────────────┘ └────────────────────────┘
```

### 2.2 Các Luồng Hoạt Động Cốt Lõi (Core Data Flows)

1. **Luồng Đồng bộ Sự kiện & Lệnh Thời gian thực (Realtime Command Dispatching):**
   - [FirebaseManager](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/data/firebaseManager.dart) kết nối Firebase Realtime Database tại node `PORTAL/CHILD/{key}` (ví dụ: `maychu`, `mayphu`, `maygiaodich 1`...).
   - Lắng nghe sự kiện từ máy chủ PC tại `message/tophone`. Khi nhận được thông điệp:
     - Lệnh `mahieubd10`: Tạo thông báo ưu tiên cao qua `AwesomeNotifications`. Khi người dùng kích hoạt, [TmsAutomationBridge](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/data/tms_automation_bridge.dart) tự động sao chép mã vào Clipboard và kích hoạt Android Accessibility Service để tự động thao tác trên ứng dụng TMS.
     - Lệnh `phonecall`: Tự động kích hoạt gọi điện thoại theo số định tuyến.
     - Lệnh `showcapchar`: Nạp ảnh Base64 CAPTCHA từ máy tính về app để người dùng giải mã và gửi ngược lại.
     - Lệnh `sendhdr`, `checkstatemh`, `printDone`: Điều phối đồng bộ trạng thái tới [KhoiTaoMoiController](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/khoi_tao_moi/controllers/khoi_tao_moi_controller.dart) và [DetailController](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/detail/controllers/detail_controller.dart).
   - Phản hồi từ thiết bị được đẩy về máy tính thông qua `message/topc`.

2. **Luồng Xử Lý & Tải Ảnh Hàng Loạt (Batch Image Processing & OCR Pipeline):**
   - Người dùng chọn ảnh từ thư viện hoặc chụp trực tiếp từ camera.
   - [ImageBatchService](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/import_images/services/image_batch_service.dart) tự động phân nhóm các ảnh được chụp trong cùng khoảng thời gian (cách nhau dưới 2 phút).
   - [ImageProcessingService](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/import_images/services/image_processing_service.dart) nhận diện hướng văn bản (Text Orientation) qua ML Kit và tự động xoay chuẩn góc (0°, 90°, 180°, 270°), nén chất lượng ảnh nhằm tối ưu băng thông.
   - [BarcodeOcrService](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/import_images/services/barcode_ocr_service.dart) quét mã vạch bưu gửi. Nếu mã vạch mờ, hệ thống kích hoạt Text OCR dự phòng và kiểm tra tính hợp lệ bằng biểu thức chính quy (`^[cCreEpP][a-zA-Z]\d{9}[vV][nN]$`).
   - Tải ảnh lên Firebase Storage / Telegram Bot / Supabase Storage và cập nhật Metadata tức thì vào Realtime Database cho Chrome Extension / Desktop Portal xử lý.

3. **Luồng Trợ Lý Trí Tuệ Nhân Tạo (Gemini AI Vision & Extraction):**
   - [GeminiChatService](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/home/GeminiChatService.dart) gửi ảnh bưu phẩm tới Google Gemini Vision API (`gemini-3-flash-preview` / `gemini-1.5-flash`).
   - Mô hình AI tự động trích xuất cấu trúc dữ liệu JSON gồm: `maHieu`, `tenNguoiNhan`, `diaChi`, `soDienThoai` và hỗ trợ Google Search Grounding để tra cứu địa danh hành chính chuẩn xác.

4. **Luồng Phân Loại Hướng Đi & Cảnh Báo Âm Thanh (Voice & Audio Feedback):**
   - Trong quá trình quét mã bưu gửi ([quetthu](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/quetthu/), [quetmh](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/quetmh/), [direction_scanning](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/direction_scanning/)), hệ thống tra cứu bảng định tuyến `tinhthanh.json`.
   - Sử dụng `just_audio` phát chuỗi file âm thanh tương ứng (`assets/0.wav` - `assets/100.wav`, `hang_duoi_2kg.wav`, `dusoluong.wav`, `trungdon.mp3`, `lachuong.mp3`) để phản hồi ngay lập tức cho nhân viên phân loại mà không cần nhìn màn hình.

---

## 3. Bản Đồ Thư Mục & Module Trọng Tâm (Directory Topology)

```text
phone_auto_portal/
├── android/                         # Cấu hình Native Android, Kotlin Services, Manifest & Permissions
│   └── app/src/main/
│       ├── AndroidManifest.xml      # Khai báo quyền Camera, Notifications, Accessibility, Storage
│       └── kotlin/                  # Native MethodChannels (Accessibility, Volume Hooks, App Launcher)
├── assets/                          # Kho tài nguyên âm thanh & dữ liệu tĩnh
│   ├── 0.wav ... 100.wav            # Tệp âm thanh phát số đếm phân loại
│   ├── beep.mp3, trungdon.mp3...    # Âm thanh hiệu ứng thông báo trạng thái
│   ├── tinhthanh.json               # Cơ sở dữ liệu địa giới hành chính Việt Nam (Tỉnh/Thành/Quận/Huyện)
│   └── tree_data.json               # Cấu trúc cây dữ liệu bưu cục & phân luồng
├── lib/
│   ├── main.dart                    # Điểm khởi chạy ứng dụng, thiết lập Firebase, Notifications, DI
│   ├── firebase_options.dart        # Cấu hình Firebase tự động cho từng nền tảng
│   ├── app/
│   │   ├── modules/                 # Các module tính năng độc lập (GetX MVC)
│   │   │   ├── home/                # Màn hình chính điều khiển trung tâm, kết nối máy chủ/phụ, Gemini AI
│   │   │   │   ├── controllers/     # [home_controller.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/home/controllers/home_controller.dart)
│   │   │   │   ├── views/           # [home_view.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/home/views/home_view.dart)
│   │   │   │   └── GeminiChatService.dart # [GeminiChatService.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/home/GeminiChatService.dart)
│   │   │   ├── khoi_tao_moi/        # Quản lý & khởi tạo danh sách bưu gửi theo phiên
│   │   │   ├── createnew/           # Tạo mới bưu gửi và đồng bộ bảng giá
│   │   │   ├── taodon/              # Phân hệ lập đơn hàng bưu chính
│   │   │   ├── nhaphang/            # Nghiệp vụ nhập kho & gợi ý địa chỉ tự động
│   │   │   ├── import_images/       # Quản lý tải ảnh hàng loạt theo batch, xoay ảnh và OCR ML Kit
│   │   │   │   ├── services/        # [barcode_ocr_service.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/import_images/services/barcode_ocr_service.dart), [image_processing_service.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/import_images/services/image_processing_service.dart), [image_upload_service.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/import_images/services/image_upload_service.dart)
│   │   │   │   └── views/           # [import_images_view.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/modules/import_images/views/import_images_view.dart)
│   │   │   ├── capture_image/       # Giao diện chụp ảnh camera liên tục với chế độ khóa màn hình
│   │   │   ├── quetthu/             # Quét mã vạch bưu gửi 1 & tra cứu tức thời
│   │   │   ├── quetmh/              # Quét mã vạch bưu gửi 2 & thống kê số lượng
│   │   │   ├── direction_scanning/  # Quét mã kèm định hướng luân chuyển bưu cục
│   │   │   ├── dingoai_rt/          # Đồng bộ dữ liệu bưu gửi đi ngoài Real-time với hệ thống WPF
│   │   │   ├── dingoai_config/      # Cấu hình tham số bưu gửi đi ngoài
│   │   │   ├── danhsachbd/          # Quản lý danh sách bảng kê bưu điện
│   │   │   ├── portalinfo/          # Thông tin trạng thái Portal & đồng bộ tài khoản
│   │   │   ├── printPage/           # Phân hệ xuất lệnh in ấn phiếu gửi / mã vạch
│   │   │   ├── edit_page/           # Chỉnh sửa thông tin chi tiết bưu gửi
│   │   │   ├── detail/              # Xem chi tiết đơn hàng khách hàng
│   │   │   └── myview/              # Màn hình tổng hợp dữ liệu cá nhân
│   │   ├── routes/
│   │   │   ├── app_pages.dart       # [app_pages.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/routes/app_pages.dart) - Đăng ký danh sách Route & Bindings
│   │   │   └── app_routes.dart      # [app_routes.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/app/routes/app_routes.dart) - Hằng số đường dẫn URL/Route
│   │   ├── theme/                   # Giao diện Theme Sáng/Tối & Controller chuyển đổi
│   │   └── widgets/                 # Các Widget dùng chung (chọn máy chủ, bảng biểu...)
│   └── data/                        # Lớp Dữ Liệu & Giao Tiếp Hệ Thống
│       ├── firebaseManager.dart     # [firebaseManager.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/data/firebaseManager.dart) - Singleton điều phối kết nối Firebase
│       ├── tms_automation_bridge.dart # [tms_automation_bridge.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/data/tms_automation_bridge.dart) - Bridge MethodChannel tự động hóa Android
│       ├── image_cache_service.dart # [image_cache_service.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/data/image_cache_service.dart) - Bộ đệm quản lý ảnh nén & metadata
│       ├── telegram_service.dart    # [telegram_service.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/data/telegram_service.dart) - Tải ảnh lên Telegram Bot Media Group
│       ├── supabase_storage_service.dart # [supabase_storage_service.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/data/supabase_storage_service.dart) - Đồng bộ ảnh lên Supabase
│       ├── notification_controller.dart # [notification_controller.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/data/notification_controller.dart) - Xử lý tương tác Action Notifications
│       └── UpdateService.dart       # [UpdateService.dart](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/data/UpdateService.dart) - Tự động tải & cập nhật APK nội bộ
├── test/                            # Thư mục chứa Unit Test & Widget Test
├── pubspec.yaml                     # [pubspec.yaml](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/pubspec.yaml) - Quản lý dependencies, fonts, assets
└── analysis_options.yaml            # [analysis_options.yaml](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/analysis_options.yaml) - Quy tắc Linter & phân tích mã nguồn
```

---

## 4. Hướng Dẫn Phát Triển & Khởi Chạy (Development Workflows)

### 4.1 Yêu Cầu Môi Trường (Prerequisites)
- **Flutter SDK:** `>= 3.3.0` (Khuyến nghị Flutter 3.22.x trở lên với Dart 3.x).
- **Android Studio / VS Code:** Đã cài đặt Flutter & Dart extensions.
- **Android SDK:** Cài đặt Android SDK Platform 34+, Android SDK Build-Tools.
- **Tài khoản Firebase:** Dự án Firebase Realtime Database & Firebase Storage được cấu hình trong `lib/firebase_options.dart` và `.firebaserc`.

### 4.2 Các Lệnh Thao Tác Cơ Bản

```bash
# 1. Cài đặt các gói phụ thuộc
flutter pub get

# 2. Kiểm tra lỗi cú pháp và phân tích tĩnh (Static Analysis)
flutter analyze

# 3. Định dạng lại mã nguồn theo chuẩn Dart
dart format .

# 4. Khởi chạy ứng dụng ở chế độ Debug
flutter run

# 5. Khởi chạy trên thiết bị cụ thể (ví dụ thiết bị Android thật hoặc máy ảo)
flutter devices
flutter run -d <device_id>

# 6. Khởi chạy với hồ sơ hiệu năng (Profiling)
flutter run --profile

# 7. Chạy bộ kiểm thử tự động (Unit / Widget Tests)
flutter test

# 8. Chạy kiểm thử kèm thống kê độ bao phủ mã nguồn (Code Coverage)
flutter test --coverage
```

### 4.3 Đóng Gói Ứng Dụng (Build & Release)

```bash
# Đóng gói APK Release cho Android
flutter build apk --release

# Đóng gói App Bundle (cho Google Play)
flutter build appbundle --release

# Đóng gói cho nền tảng Web
flutter build web --release --web-renderer canvaskit
```

*Lưu ý:* Khi phát hành phiên bản mới, cập nhật số phiên bản và mã build trong [pubspec.yaml](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/pubspec.yaml) (định dạng `version: 1.2.3+<build_number>`) và đồng bộ tệp `build_number.txt`.

---

## 5. Quy Chuẩn Code & Lưu Ý Quan Trọng (Conventions & Guidelines)

### 5.1 Quy Chuẩn Thiết Kế & Cấu Trúc Mã Nguồn (GetX MVC Rules)
1. **Phân tách trách nhiệm tuyệt đối:**
   - Tuyệt đối không gọi trực tiếp `FirebaseDatabase.instance.ref()` hoặc gọi API mạng từ `Widget.build()`.
   - Toàn bộ trạng thái hiển thị phải được điều khiển qua Controller (`GetxController`) và gắn kết với UI bằng `Obx(() => ...)`.
2. **Quy tắc đặt tên:**
   - Tên tệp & thư mục: `snake_case` (ví dụ: `image_processing_service.dart`, `khoi_tao_moi_controller.dart`).
   - Tên Class: `PascalCase` (ví dụ: `KhoiTaoMoiController`, `ImageItem`).
   - Biến phản ứng: Luôn có hậu tố hoặc khởi tạo `.obs` (ví dụ: `final isLoading = false.obs;`).
3. **Giải phóng tài nguyên (Memory Leak Prevention):**
   - Mọi `StreamSubscription` (Firebase Database listeners, AudioPlayer streams) và `TextEditingController` bắt buộc phải được hủy trong phương thức `onClose()` của Controller:
   ```dart
   @override
   void onClose() {
     _firebaseSubscription?.cancel();
     textController.dispose();
     super.onClose();
   }
   ```

### 5.2 Lưu Ý Nghiệp Vụ & Cạm Bẫy Kỹ Thuật (Gotchas)
- **Quyền Trợ năng (Accessibility Service) trên Android:** Tính năng tự động hóa BD10 yêu cầu người dùng kích hoạt thủ công dịch vụ trợ năng trong mục *Cài đặt hệ thống > Trợ năng > TMS Automation Service*. Nếu chưa được cấp quyền, [TmsAutomationBridge](file:///H:/DATA/FLUTTER_APP/phone_auto_portal/lib/data/tms_automation_bridge.dart) sẽ mở màn hình cài đặt trợ năng để hướng dẫn người dùng.
- **Node Cấu hình Máy chủ Firebase (`PORTAL/CHILD/{key}`):** Đảm bảo chọn đúng định danh máy (`maychu`, `mayphu`, `maygiaodich 1`...) tại màn hình chính để nhận và gửi chính xác các luồng lệnh với ứng dụng desktop tương ứng.
- **Biểu thức chính quy Mã bưu gửi:** Mọi mã hiệu quét qua Barcode/OCR phải tuân theo định dạng chuẩn bưu chính: `^[cCreEpP][a-zA-Z]\d{9}[vV][nN]$`.
- **Firebase Connection Lifecycle:** Ứng dụng đã đăng ký lắng nghe trạng thái `AppLifecycleState.resumed` trong `FirebaseManager` để tự động khôi phục kết nối (`goOnline()`) khi người dùng quay lại ứng dụng.
