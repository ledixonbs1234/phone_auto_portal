# AGENTS.md - AI Code Assistant Guide

## Project Context

**Project:** Phone Auto Portal - Flutter application for automated portal operations with barcode scanning, image processing, and AI chat integration.

**Tech Stack:**
- Flutter SDK >= 3.3.0
- Dart SDK >= 3.3.0
- GetX 4.6.6 (State Management, Routing, DI)
- Firebase (Core, Realtime Database, Storage, AI)
- Google ML Kit (Barcode Scanning, Text Recognition)

**Platforms:** Android

**Version:** 1.2.3+81

**Repository:** https://github.com/ledixonbs1234/phone_auto_portal

---

## Architecture Overview

### Pattern: GetX + MVC (Model-View-Controller)

```
lib/
├── main.dart                      # Entry point, Firebase init
├── firebase_options.dart          # Firebase configuration
├── app/
│   ├── modules/                   # Feature modules (MVC pattern)
│   │   ├── home/                  # Main home screen
│   │   │   ├── bindings/
│   │   │   ├── controllers/
│   │   │   ├── models/
│   │   │   ├── views/
│   │   │   ├── widgets/
│   │   │   └── GeminiChatService.dart
│   │   ├── detail/                # Detail view
│   │   ├── createnew/             # Create new entry
│   │   ├── khoi_tao_moi/         # Khởi tạo mới
│   │   ├── portalinfo/            # Portal info module
│   │   ├── printPage/             # Print functionality
│   │   ├── edit_page/             # Edit page
│   │   ├── myview/                # User view
│   │   ├── quetthu/               # Barcode scanner module 1
│   │   ├── quetmh/                # Barcode scanner module 2
│   │   ├── direction_scanning/    # Direction scanning
│   │   ├── import_images/         # Image import with services/
│   │   ├── capture_image/         # Camera capture
│   │   └── dingoai_rt/            # Di Ngoai real-time
│   ├── routes/
│   │   ├── app_pages.dart         # Route definitions
│   │   └── app_routes.dart        # Route constants
│   └── widgets/                   # Shared widgets
│       └── host_selection_widget.dart
└── data/                          # Data layer (services)
    ├── firebaseManager.dart       # Core Firebase operations
    ├── image_cache_service.dart   # Image caching system
    ├── firebase_storage_service.dart
    ├── UpdateService.dart         # App update logic
    └── telegram_service.dart      # Telegram integration
```

---

## Module Structure (MANDATORY)

Each module follows this structure:

```
module_name/
├── bindings/
│   └── module_binding.dart        # Dependency injection
├── controllers/
│   └── module_controller.dart    # Business logic
├── models/
│   └── module_model.dart         # Data models
├── views/
│   └── module_view.dart          # UI widgets
├── widgets/                      # Module-specific widgets (optional)
└── services/                     # Module services (optional)
```

---

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `home_controller.dart` |
| Classes | PascalCase | `HomeController` |
| Functions/Variables | camelCase | `getKhachHang` |
| Observable variables | .obs suffix | `khachHangs.obs` |
| Constants | UPPER_SNAKE_CASE | `INITIAL_ROUTE` |
| Routes | snake_case | `/home`, `/detail` |

---

## GetX Patterns (MANDATORY)

### Controller Pattern

```dart
class MyController extends GetxController {
  // Observable state
  final count = 0.obs;
  final items = <Item>[].obs;
  final user = Rxn<User>();
  
  // Text controllers
  final textController = TextEditingController();
  
  @override
  void onInit() {
    super.onInit();
    // Initialize data
    loadData();
  }
  
  @override
  void onClose() {
    // Cleanup resources
    textController.dispose();
    super.onClose();
  }
  
  // Business logic methods
  void increment() {
    count.value++;
  }
  
  Future<void> loadData() async {
    // Fetch data from service
  }
}
```

### View Pattern

```dart
class MyView extends GetView<MyController> {
  const MyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Page')),
      body: Obx(() => ListView.builder(
        itemCount: controller.items.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(controller.items[index].name));
        },
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Binding Pattern

```dart
class MyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyController>(() => MyController());
  }
}
```

### Route Registration

Add to `lib/app/routes/app_pages.dart`:

```dart
GetPage(
  name: _Paths.MY_MODULE,
  page: () => const MyView(),
  binding: MyBinding(),
),
```

Add constant to `lib/app/routes/app_routes.dart`:

```dart
static const MY_MODULE = _Paths.MY_MODULE;
// In _Paths class:
static const MY_MODULE = '/my-module';
```

---

## Core Services

### 1. FirebaseManager (lib/data/firebaseManager.dart)

Singleton managing Firebase Realtime Database operations.

```dart
// Usage
final db = FirebaseManager();
String key = db.readKey(); // Get key from GetStorage
db.rootPath.child('path/to/data').set(value);
db.rootPath.child('path/to/data').once().then((snapshot) {
  if (snapshot.exists) {
    // Process data
  }
});

// Listen to data changes
database.child('PNS/TimeUpdate').onValue.listen((event) {
  // Handle update
});
```

### 2. ImageCacheService (lib/data/image_cache_service.dart)

Manages processed image cache with JSON metadata.

```dart
// Usage
final cache = ImageCacheService.instance;
final cachedImage = await cache.getCachedImage(imagePath);
await cache.cleanupOldFiles(); // Remove old files

// Model
class ImageMetadata {
  final String originalPath;
  final String compressedPath;
  final String? maHieu;
  final int rotationAngle;
  final int lastModified;
  final int processedAt;
}
```

### 3. GeminiChatService (lib/app/modules/home/GeminiChatService.dart)

AI chat integration with conversation history.

```dart
// Usage
final gemini = GeminiChatService(apiUrl: 'YOUR_API_URL');
final response = await gemini.chat('Hello');
gemini.clearHistory(); // Clear conversation

// Features
// - Maintains conversation history
// - Supports Google Search tool
// - Thinking mode enabled
```

### 4. ImageUploadService (lib/app/modules/import_images/services/)

Batch image upload to Firebase Storage with retry and rollback.

```dart
// Features
// - Uploads images in batches (max 10 per batch)
// - Exponential backoff retry (1s, 2s, 3s)
// - Progress callbacks
// - Rollback on complete failure
// - Metadata sync with Realtime Database
```

### 5. KhoiTaoMoiController Message Handlers (lib/app/modules/khoi_tao_moi/controllers/khoi_tao_moi_controller.dart)

Xử lý các message từ Firebase trong `onListenNotification`:

```dart
// Các message handlers:
// - checkstatemh: Cập nhật trạng thái bưu gửi (trangThaiRequest = "Xong", money)
// - message: Hiển thị thông báo trạng thái (stateText)
// - showdetailmessage: Hiển thị chi tiết thông báo (stateText)
// - printDone: Thông báo in xong (stateText = "In xong")
// - sendhdr: Nhận HDR ID từ Portal

Future<void> onListenNotification(MessageReceiveModel message) async {
  switch (message.Lenh) {
    case "checkstatemh":
      var splitText = message.DoiTuong.split("|");
      var bg = buuGuis.firstWhereOrNull((e) => e.maBuuGui == splitText[0]);
      bg?.trangThaiRequest = "Xong";
      bg?.money = splitText[1];
      _saveToFirebase();
      update();
      break;
    case "message":
    case "showdetailmessage":
      stateText.value = message.DoiTuong;
      break;
    case "printDone":
      stateText.value = "In xong";
      break;
    case "sendhdr":
      try {
        final data = jsonDecode(message.DoiTuong);
        hdrId = data['hdrId']?.toString();
        hdrIdText.value = hdrId ?? "";
        stateText.value = "Đã nhận HDR: ${hdrIdText.value}";
      } catch (e) {
        stateText.value = "Lỗi nhận HDR";
      }
      update();
      break;
  }
}
```

---

## Data Models

### Key Models

| Model | Location | Purpose |
|-------|----------|---------|
| `KhachHangs` | home/khach_hangs_model.dart | Customer data |
| `UserInfo` | home/user_info.dart | User information |
| `HopDongModel` | home/hopdong_model.dart | Contract model |
| `PortalModel` | portalinfo/portal_model.dart | Portal data |
| `ImageItem` | import_images/models/ | Image item with metadata |
| `DiNgoaiItemInfo` | dingoai_rt/models/ | Di Ngoai item |

### Model Pattern

```dart
class MyModel {
  final String id;
  final String name;
  final DateTime createdAt;

  MyModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory MyModel.fromJson(Map<String, dynamic> json) => MyModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };
}
```

---

## Common Tasks

### Create New Module

1. Create directories: `lib/app/modules/new_module/{bindings,controllers,models,views}/`

2. Create binding:
```dart
// lib/app/modules/new_module/bindings/new_module_binding.dart
class NewModuleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NewModuleController>(() => NewModuleController());
  }
}
```

3. Create controller:
```dart
// lib/app/modules/new_module/controllers/new_module_controller.dart
class NewModuleController extends GetxController {
  final data = <Model>[].obs;
  final isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadData();
  }
  
  Future<void> loadData() async {
    isLoading.value = true;
    try {
      // Fetch data
    } finally {
      isLoading.value = false;
    }
  }
}
```

4. Create view:
```dart
// lib/app/modules/new_module/views/new_module_view.dart
class NewModuleView extends GetView<NewModuleController> {
  const NewModuleView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: controller.data.length,
          itemBuilder: (ctx, i) => ListTile(
            title: Text(controller.data[i].name),
          ),
        );
      }),
    );
  }
}
```

5. Register route in `app_pages.dart`

6. Add constant in `app_routes.dart`

### Access Firebase Data

```dart
// CORRECT - Use FirebaseManager
final db = FirebaseManager();
db.rootPath.child('customers').onValue.listen((event) {
  if (event.snapshot.exists) {
    final data = Map<String, dynamic>.from(event.snapshot.value as Map);
    // Process data
  }
});

// WRONG - Direct in View
FirebaseDatabase.instance.ref('path').get(); // Avoid this!
```

### Use GetStorage

```dart
// Write value
GetStorage().write('key', 'value');

// Read with default
String value = GetStorage().read('key') ?? 'default';

// Check if exists
bool hasKey = GetStorage().hasData('key');
```

### Play Audio

```dart
import 'package:just_audio/just_audio.dart';

final player = AudioPlayer();
await player.setAsset('assets/beep.mp3');
await player.play();
await player.dispose();
```

### Show Notification

```dart
AwesomeNotifications().createNotification(
  content: NotificationContent(
    id: 1,
    channelKey: 'test',
    title: 'Notification Title',
    body: 'Notification body',
  ),
);
```

---

## Anti-Patterns (DO NOT DO)

### ❌ Hardcoded Strings

```dart
// Wrong
Text('Hello');
ElevatedButton(child: Text('Submit'));

// Correct - Use constants or localization
Text('app.hello'.tr);
const String BTN_SUBMIT = 'Submit';
```

### ❌ Direct Firebase in Views

```dart
// Wrong
class MyView extends StatelessWidget {
  Widget build() {
    FirebaseDatabase.instance.ref('data').get(); // No!
  }
}

// Correct - Use controller/service
class MyController extends GetxController {
  Future<void> fetchData() async {
    final db = FirebaseManager();
    // ...
  }
}
```

### ❌ setState in GetX

```dart
// Wrong
setState(() {
  counter++;
});

// Correct
counter.value++; // For .obs variables
// or
counter++; // For .obs lists
```

### ❌ Missing Null Safety

```dart
// Wrong
String name = data['name']; // Can crash

// Correct
String? name = data['name'] as String?;
String name = data['name'] as String? ?? '';
```

### ❌ Memory Leaks in Listeners

```dart
// Wrong
@override
void onInit() {
  database.ref('path').onValue.listen((event) {
    // Never cancelled!
  });
}

// Correct
late StreamSubscription subscription;

@override
void onInit() {
  subscription = database.ref('path').onValue.listen((event) {
    // Handle
  });
}

@override
void onClose() {
  subscription.cancel();
  super.onClose();
}
```

---

## Dependencies Reference

### Core (pubspec.yaml)

```yaml
# State Management & Routing
get: ^4.6.6

# Firebase
firebase_core: ^4.0.0
firebase_database: 12.0.0
firebase_storage: ^13.0.6
firebase_ai: ^3.1.0

# Local Storage
get_storage: 2.1.1

# UI Components
cupertino_icons: ^1.0.6
data_table_2: 2.5.11
group_button: 5.3.4
msh_checkbox: 2.0.1
autocomplete_textfield: 2.0.1

# Media
camera: ^0.10.5+9
image_picker: ^1.0.7
flutter_image_compress: ^2.4.0
just_audio: ^0.9.39

# Scanning & ML
mobile_scanner: ^5.0.0
google_mlkit_barcode_scanning: ^0.14.1
google_mlkit_text_recognition: ^0.15.0

# Network & Files
dio: ^5.8.0+1
path_provider: ^2.1.5
open_filex: ^4.5.0
file_picker: ^10.3.7
archive: ^4.0.7

# Device
device_info_plus: ^10.1.2
permission_handler: ^11.3.1
wakelock_plus: ^1.2.8

# Notifications
awesome_notifications: ^0.10.1
```

---

## Testing Commands

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Format code
flutter format .

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

### Pre-commit Checklist

- [ ] Format code: `flutter format .`
- [ ] Analyze: `flutter analyze` (no errors)
- [ ] Run tests: `flutter test`
- [ ] Check for unused imports
- [ ] Verify null safety
- [ ] Update pubspec.yaml version if needed

---

## AI Assistant Guidelines

### When Creating New Code

1. Check module structure first
2. Follow GetX + MVC pattern strictly
3. Create all necessary files: binding, controller, model, view
4. Register in routes (app_pages.dart, app_routes.dart)
5. Use service classes for Firebase operations
6. Add proper error handling

### When Fixing Bugs

1. Read existing code to understand pattern
2. Maintain existing style
3. Use minimal changes
4. Keep backward compatibility
5. Test the fix
6. Check related code for similar issues

### When Refactoring

1. Analyze current structure
2. Keep GetX + MVC pattern
3. Maintain observable patterns (.obs)
4. Preserve binding relationships
5. Update tests if needed

### When Adding Services

1. Create in `lib/data/` for global services
2. Create in `lib/app/modules/<module>/services/` for module-specific
3. Use singleton pattern or GetX DI
4. Add error handling (try-catch)
5. Use debugPrint for logging

### Critical Files to Read

| File | Purpose |
|------|---------|
| `PROJECT_INSTRUCTIONS.md` | Full documentation |
| `lib/main.dart` | Entry point, initialization |
| `lib/app/routes/app_pages.dart` | Route definitions |
| `lib/data/firebaseManager.dart` | Firebase core operations |
| `lib/app/modules/home/controllers/home_controller.dart` | Main controller |

---

## Common Gotchas

### GetX Binding Not Working

```dart
// Wrong - Missing binding
GetPage(name: '/path', page: () => MyView());

// Correct
GetPage(name: '/path', page: () => MyView(), binding: MyBinding());
```

### Observable List Not Updating UI

```dart
// For .obs lists, changes auto-refresh UI
final items = <Item>[].obs;

items.add(newItem); // Auto-refreshes
items.value = [...items, newItem]; // Also works
items.refresh(); // Force refresh
```

### Global Controllers

```dart
// In main.dart
Get.put(HomeController());
Get.put(PortalinfoController());

// In any controller
class MyController extends GetxController {
  final homeController = Get.find<HomeController>();
}
```

---

## Route Map

| Route | Module | Description |
|-------|--------|-------------|
| `/home` | home | Main screen |
| `/detail` | detail | Detail view |
| `/createnew` | createnew | Create new entry |
| `/options` | createnew | Options view |
| `/portalinfo` | portalinfo | Portal information |
| `/print-page` | printPage | Print functionality |
| `/edit-page` | edit_page | Edit entry |
| `/myview` | myview | User view |
| `/quetthu` | quetthu | Scanner module 1 |
| `/quetmh` | quetmh | Scanner module 2 |
| `/direction-scanning` | direction_scanning | Direction scanning |
| `/import-images` | import_images | Image import |
| `/capture-image` | capture_image | Camera capture |
| `/dingoai-rt` | dingoai_rt | Di Ngoai real-time |

---

## Assets

Located in `assets/`:
- Audio: `beep.mp3`, `0.wav` to `100.wav`, category sounds
- Data: `tinhthanh.json` (Vietnam provinces/districts)
- Images: Various UI assets

Audio files numbered 0-100 are used for voice output in number selection.

---

## Firebase Structure

```
PORTAL/
├── CHILD/
│   └── {key}/                    # Dynamic key (maychu, mayphu, etc.)
│       ├── customers/
│       ├── orders/
│       └── ...
├── AppVersion/
│   └── app_update_info/
│       ├── android/
│       └── ios/
PNS/
└── TimeUpdate/

MYVNPOST/
└── TimeUpdate/
```

---

## Related Documentation

- `PROJECT_INSTRUCTIONS.md` - Full project documentation
- `README.md` - Flutter getting started guide
- `lib/app/modules/import_images/README.md` - Image import guide
- `lib/app/modules/dingoai_rt/INTEGRATION_GUIDE.md` - Di Ngoai integration

---

**Last Updated:** January 2026  
**Maintained By:** Development Team