# Fix JVM Compatibility Issues

## Vấn đề gặp phải

1. **Lỗi ban đầu**: 
   ```
   Inconsistent JVM-target compatibility detected for tasks 'compileDebugJavaWithJavac' (1.8) and 'compileDebugKotlin' (17).
   ```

2. **Lỗi tiếp theo**:
   ```
   Cannot find a Java installation on your machine matching this tasks requirements: {languageVersion=11, vendor=any vendor, implementation=vendor-specific}
   ```

## Nguyên nhân

- Dự án có cấu hình JVM không đồng nhất giữa Java và Kotlin
- Hệ thống không có Java 11 được cài đặt, chỉ có Java 17 từ Android Studio JBR

## Giải pháp đã áp dụng

### Bước 1: Kiểm tra Java version có sẵn
```bash
"D:\DATA\android-studio\jbr\bin\java.exe" -version
# Result: openjdk version "17.0.9" 2023-10-17
```

### Bước 2: Cập nhật android/app/build.gradle
Thay đổi từ JVM 11/17 hỗn hợp thành JVM 17 đồng nhất:

```gradle
// Trước đây (có vấn đề)
compileOptions {
    sourceCompatibility JavaVersion.VERSION_11
    targetCompatibility JavaVersion.VERSION_11
}
kotlin {
    jvmToolchain(17)  // Không khớp với compileOptions
}
kotlinOptions {
    jvmTarget = '11'  // Không khớp với jvmToolchain
}

// Sau khi sửa (đồng nhất)
compileOptions {
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
}
kotlin {
    jvmToolchain(17)
}
kotlinOptions {
    jvmTarget = '17'
}
```

### Bước 3: Clean và rebuild
```bash
flutter clean
flutter pub get
flutter run
```

## Cấu hình hiện tại

### gradle.properties
```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
org.gradle.java.home=D:\\DATA\\android-studio\\jbr
```

### android/app/build.gradle
```gradle
android {
    compileSdk flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlin {
        jvmToolchain(17)
    }
    kotlinOptions {
        jvmTarget = '17'
    }
    // ... rest of config
}
```

## Lưu ý quan trọng

1. **Đồng nhất JVM version**: Tất cả cấu hình JVM phải sử dụng cùng một version
2. **Android Studio JBR**: Sử dụng JBR của Android Studio thay vì cài đặt Java riêng
3. **Flutter clean**: Luôn clean sau khi thay đổi cấu hình Gradle
4. **gradle.properties**: Đặt `org.gradle.java.home` trỏ đến JBR của Android Studio

## Kết quả

Sau khi áp dụng các bước trên, dự án có thể build thành công mà không gặp lỗi JVM compatibility.
