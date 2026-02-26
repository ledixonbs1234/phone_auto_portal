# Phone Auto Portal - Project Instructions

## Project Overview
Phone Auto Portal is a Flutter mobile application designed for automated portal operations with barcode scanning, image processing, and AI chat integration using Google Gemini API.

**Version:** 1.2.3 (Build 73)  
**Repository:** https://github.com/ledixonbs1234/phone_auto_portal  
**Platform:** Android, iOS, Web, Windows, Linux, macOS

---

## 1. Project Setup

### Prerequisites
- Flutter SDK >= 3.3.0
- Dart SDK >= 3.3.0
- Firebase Account with configured project
- Google Gemini API credentials
- Android SDK (for Android development)
- Xcode (for iOS development)

### Initial Setup
```bash
# Clone the repository
git clone https://github.com/ledixonbs1234/phone_auto_portal.git
cd phone_auto_portal

# Install dependencies
flutter pub get

# Configure Firebase (Android/iOS/Web)
firebase login
# Update .firebaserc with your Firebase project ID

# Run the app
flutter run
```

### Firebase Configuration
- Firebase Core setup in `lib/firebase_options.dart`
- Database: Firebase Realtime Database (firebase_database)
- AI: Firebase AI (firebase_ai) for ML Kit features
- Configure in `.firebaserc` with your project ID

---

## 2. Project Architecture

### Directory Structure
```
lib/
├── main.dart                 # Entry point
├── firebase_options.dart     # Firebase configuration
├── app/
│   ├── modules/             # Feature modules (MVC pattern)
│   │   ├── home/           # Main home screen
│   │   ├── createnew/      # Create new entry
│   │   ├── detail/         # Detail view
│   │   ├── myview/         # User view
│   │   ├── quetthu/        # Scanner module 1
│   │   ├── quetmh/         # Scanner module 2
│   │   └── printPage/      # Print functionality
│   ├── routes/             # Navigation routes
│   │   ├── app_pages.dart  # Route definitions
│   │   └── app_routes.dart # Route constants
│   └── widgets/            # Shared widgets
├── data/                   # Data layer
│   ├── image_cache_service.dart      # Image caching
│   ├── UpdateService.dart            # Update logic
│   ├── telegram_service.dart         # Telegram integration
│   └── TelegramManager.dart          # Telegram manager
└── test/                  # Unit tests

assets/                    # App resources
├── audio files (*.wav, *.mp3)
├── tinhthanh.json        # Location data
└── images
```

### Architecture Pattern: GetX + MVC
- **GetX:** State management, routing, dependency injection
- **Controllers:** Business logic (in each module)
- **Bindings:** Dependency injection setup
- **Views:** UI components
- **Models:** Data structures

### Module Structure (Each Feature Module)
```
module/
├── bindings/         # Dependency injection
│   └── module_binding.dart
├── controllers/      # Business logic
│   └── module_controller.dart
├── models/          # Data models
│   └── module_model.dart
├── views/           # UI screens
│   └── module_view.dart
└── widgets/         # Module-specific widgets (optional)
```

---

## 3. Key Services & Features

### 3.1 Image Processing
- **Image Caching**: `ImageCacheService` - Caches downloaded/processed images
- **Barcode Scanning**: `mobile_scanner`, `google_mlkit_barcode_scanning`
- **Image Compression**: `flutter_image_compress` for reducing file sizes
- **Text Recognition**: `google_mlkit_text_recognition`

### 3.2 AI Integration
- **Gemini Chat**: `GeminiChatService.dart` - AI chat with conversation history
- **Firebase AI**: ML Kit integration for on-device ML tasks
- **Conversation History**: Persistent context management

### 3.3 File Management
- **Download**: Using `dio` package
- **File Paths**: `path_provider` for app-specific directories
- **File Opening**: `open_filex` for opening APK files
- **File Selection**: `file_picker` for user file selection
- **Archive**: `archive` package for ZIP file operations

### 3.4 Notifications
- **Local Notifications**: `awesome_notifications` for app notifications

### 3.5 Device Integration
- **Camera**: `camera` plugin for photo capture
- **Audio**: `just_audio` for sound playback (extensive number selection audio)
- **Microphone**: Integrated with camera module
- **Permissions**: `permission_handler` for runtime permissions
- **Device Info**: `device_info_plus` for platform detection
- **Wake Lock**: `wakelock_plus` to prevent device sleep
- **URL Launch**: `url_launcher` for opening external links

### 3.6 Data Storage
- **Local Storage**: `get_storage` for persistent key-value storage
- **Firebase Database**: Real-time database sync
- **Hashing**: `crypto` package for cache key generation

### 3.7 UI Components
- **Data Tables**: `data_table_2` for complex data display
- **Button Groups**: `group_button` for grouped button selection
- **Checkboxes**: `msh_checkbox` for custom checkbox styling
- **Autocomplete**: `autocomplete_textfield` for input suggestions
- **URL Routing**: `url_strategy` for web URL management

---

## 4. Development Guidelines

### 4.1 Naming Conventions
- **Files**: snake_case (e.g., `gemini_chat_service.dart`)
- **Classes**: PascalCase (e.g., `GeminiChatService`)
- **Functions/Variables**: camelCase (e.g., `getImageCache()`)
- **Constants**: UPPER_SNAKE_CASE
- **Routes**: Forward slashes (e.g., `Routes.HOME`)

### 4.2 Code Style
- Follow Dart/Flutter style guide
- Use `analysis_options.yaml` for linting rules
- Run `flutter analyze` before committing
- Format code with `flutter format .`

### 4.3 State Management with GetX
```dart
// Controller example
class MyController extends GetxController {
  final count = 0.obs;  // Observable variable
  
  void increment() {
    count.value++;
  }
}

// Using in View
class MyView extends GetView<MyController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => Text('${controller.count}'));
  }
}

// Binding example
class MyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyController>(() => MyController());
  }
}
```

### 4.4 Routing
Routes are defined in `lib/app/routes/app_pages.dart`. Add new routes there:
```dart
static final routes = [
  GetPage(
    name: _Paths.HOME,
    page: () => const HomeView(),
    binding: HomeBinding(),
  ),
];
```

### 4.5 Firebase Integration
- Configuration: `lib/firebase_options.dart`
- Initialization in `main.dart`
- Database operations in service classes
- Error handling with try-catch blocks

### 4.6 Testing
```bash
# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

---

## 5. Important Files & Systems

### Documentation Files
- `DIRECTION_SCANNING_GUIDE.md` - Barcode/direction scanning implementation
- `DIRECTION_SCANNING_DEMO.md` - Demo and testing guide
- `METADATA_SYSTEM.md` - Metadata handling system
- `CACHE_WORKFLOW.md` - Image caching workflow
- `GetX_Fixes_Summary.md` - GetX state management fixes

### Key Configuration Files
- `pubspec.yaml` - Dependencies and assets
- `analysis_options.yaml` - Linting rules
- `.firebaserc` - Firebase project configuration
- `firebase_options.dart` - Firebase initialization

### Assets
- **Audio Files**: Numbered audio files (0.wav - 100.wav) for voice output
- **Location Data**: `tinhthanh.json` - Vietnamese provinces/districts
- **Sound Effects**: beep.mp3, various category sounds

---

## 6. Common Tasks

### 6.1 Adding a New Feature Module
1. Create module directory: `lib/app/modules/feature_name/`
2. Create subdirectories: `bindings/`, `controllers/`, `models/`, `views/`
3. Create binding file with dependency injection
4. Create controller extending `GetxController`
5. Create view extending `GetView<FeatureController>`
6. Add route to `app_pages.dart`
7. Add route constant to `app_routes.dart`

### 6.2 Working with Images
```dart
// Using ImageCacheService
final imageCache = ImageCacheService();
final cachedImage = await imageCache.getCachedImage(imageUrl);
```

### 6.3 Using Gemini Chat
```dart
// See GeminiChatService.dart for implementation
final geminiService = GeminiChatService();
final response = await geminiService.chat(userMessage);
```

### 6.4 Barcode Scanning
- Modules: `quetthu`, `quetmh`
- See `DIRECTION_SCANNING_GUIDE.md` for detailed implementation

### 6.5 Playing Audio
```dart
// Using just_audio
import 'package:just_audio/just_audio.dart';
final player = AudioPlayer();
await player.setAsset('assets/beep.mp3');
await player.play();
```

---

## 7. Build & Release

### Android Build
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### iOS Build
```bash
# Build iOS app
flutter build ios --release
```

### Web Build
```bash
flutter build web --release
```

### Build Numbers
- Version defined in `pubspec.yaml`: `1.2.3+73`
- Build number tracked in `build_number.txt`
- Update before each release

---

## 8. Debugging Tips

### 8.1 Enable Debug Logging
Set environment variables or use `Get.log()`:
```dart
Get.log('Debug message');
```

### 8.2 Firebase Debugging
- Use Firebase Console for real-time database inspection
- Check Firebase Authentication if needed

### 8.3 Common Issues
- **GetX Binding Errors**: Ensure binding is registered in `app_pages.dart`
- **Image Caching**: Check app storage permissions
- **Barcode Detection**: Ensure camera permission is granted
- **Firebase Connection**: Check `.firebaserc` and network connectivity

### 8.4 Profiling
```bash
# Run with profiling
flutter run --profile

# Use DevTools
flutter pub global activate devtools
flutter devtools
```

---

## 9. Dependencies Overview

### Core
- `get: ^4.6.6` - State management & routing
- `firebase_core: ^4.0.0` - Firebase base
- `firebase_database: 12.0.0` - Real-time database

### Media & Scanning
- `camera: ^0.10.5+9` - Camera access
- `mobile_scanner: ^5.0.0` - Barcode scanning
- `google_mlkit_barcode_scanning: ^0.14.1` - ML Kit barcode
- `google_mlkit_text_recognition: ^0.15.0` - Text recognition
- `image_picker: ^1.0.7` - Image selection
- `flutter_image_compress: ^2.4.0` - Image compression

### Audio & Notifications
- `just_audio: ^0.9.39` - Audio playback
- `awesome_notifications: ^0.10.1` - Local notifications
- `wakelock_plus: ^1.2.8` - Wake lock

### Storage & Network
- `dio: ^5.8.0+1` - HTTP client
- `get_storage: 2.1.1` - Local storage
- `path_provider: ^2.1.5` - App directories
- `archive: ^4.0.7` - ZIP handling

### Device & Permissions
- `device_info_plus: ^10.1.2` - Device info
- `permission_handler: ^11.3.1` - Runtime permissions
- `package_info_plus: ^8.3.0` - App info
- `open_filex: ^4.5.0` - Open files

### UI & UX
- `cupertino_icons: ^1.0.6` - iOS icons
- `data_table_2: 2.5.11` - Data tables
- `group_button: 5.3.4` - Button groups
- `msh_checkbox: 2.0.1` - Custom checkboxes
- `autocomplete_textfield: 2.0.1` - Autocomplete

### Utilities
- `url_launcher: ^6.3.1` - Launch URLs
- `url_strategy: 0.2.0` - Web URL strategy
- `crypto: ^3.0.3` - Hashing
- `firebase_ai: ^3.1.0` - Firebase AI

---

## 10. Git Workflow

### Commit Guidelines
- Use descriptive commit messages
- Reference task IDs or issues when applicable
- Format: `[FEATURE|FIX|DOCS] Description`

### Branch Strategy
- `main` - Production-ready code
- `develop` - Development branch
- `feature/*` - Feature branches
- `fix/*` - Bug fix branches

### Before Committing
```bash
# Format code
flutter format .

# Analyze
flutter analyze

# Run tests
flutter test

# Build verification
flutter build apk --debug
```

---

## 11. Performance Optimization

### Image Caching
- Use `ImageCacheService` for frequently accessed images
- Implement cache expiration logic
- Monitor cache size growth

### State Management
- Use `.obs` only for observable fields
- Avoid unnecessary Obx rebuilds
- Use `GetBuilder` for complex widgets

### Database
- Optimize Firebase queries
- Use indexing for frequently filtered fields
- Implement pagination for large datasets

### UI Rendering
- Use `const` constructors where possible
- Lazy load heavy widgets
- Implement item caching in lists

---

## 12. Support & Resources

### Documentation Links
- [Flutter Docs](https://docs.flutter.dev/)
- [GetX Documentation](https://github.com/jonataslaw/getx)
- [Firebase Docs](https://firebase.google.com/docs)
- [Google Gemini API](https://ai.google.dev/docs)

### Project Documentation
- Refer to existing `.md` files in project root
- Check module README files for specific features
- Review controller comments for usage examples

### Contact & Issues
- Repository: https://github.com/ledixonbs1234/phone_auto_portal
- Create issues for bugs or feature requests
- Follow project contribution guidelines

---

## 13. Maintenance & Updates

### Dependency Updates
```bash
# Check for updates
flutter pub upgrade --dry-run

# Update dependencies
flutter pub upgrade

# Update specific package
flutter pub upgrade package_name
```

### Firebase Updates
- Keep Firebase dependencies up to date
- Test thoroughly after Firebase upgrades
- Monitor deprecation warnings

### Build Number Management
- Increment `pubspec.yaml` version for releases
- Update `build_number.txt`
- Tag releases in Git

---

## Version History
- **1.2.3 (Build 73)** - Current version
- Includes Gemini AI integration
- Complete barcode scanning system
- Image caching and metadata system

---

**Last Updated:** January 2026  
**Maintained By:** Development Team  
**Status:** Active Development
