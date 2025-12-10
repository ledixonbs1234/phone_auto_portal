# 📸 Image Processing & Cache Workflow

## 🔄 Workflow Tổng Quan

```
┌─────────────────┐
│  Original File  │ (IMG20251209151922.jpg từ camera/gallery)
│  A.jpg          │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ 0. CHECK CACHE FIRST (Controller)                       │
│                                                         │
│    Cache key: hash(A.jpg + last_modified)              │
│    Check: /cache/telegram_compressed/20251209_hash.jpg │
│                                                         │
│    ✅ Cache EXISTS:                                    │
│       → Use cached file                                │
│       → SKIP rotation (no need!)                       │
│       → SKIP OCR (already processed!)                  │
│       → Upload cached file directly                    │
│                                                         │
│    ❌ Cache NOT EXISTS:                                │
│       → Continue to step 1 (rotate)                    │
└────────┬────────────────────────────────────────────────┘
         │ (only if cache miss)
         ▼
┌─────────────────────────────────────────────────────────┐
│ 1. ROTATION (ImageProcessingService.processImage())     │
│    - Detect orientation using ML Kit                   │
│    - Rotate if needed (90°/180°/270°)                  │
│    - Output: A_rotated.jpg                             │
│    - Location: /cache/                                 │
│    - Status: TEMPORARY                                 │
└────────┬────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ 2. OCR (BarcodeOcrService.readMaHieu())                 │
│    - Read barcode/text from rotated file               │
│    - Extract mã hiệu (product code)                     │
└────────┬────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ 3. COMPRESSION + CACHE (TelegramService)                │
│    - Compress A_rotated.jpg                            │
│    - Save to: 20251209_hash(A.jpg).jpg                 │
│    - Location: /cache/telegram_compressed/             │
│    - Status: PERSISTENT (cached)                       │
└────────┬────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ 4. UPLOAD TO TELEGRAM                                   │
│    - Upload compressed file                            │
│    - Get file_id and download URL                      │
│    - Save metadata to Firebase                         │
└────────┬────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ 5. CLEANUP                                              │
│    ✅ Delete: A_rotated.jpg (TEMPORARY)                │
│    ✅ Keep: 20251209_hash.jpg (CACHED)                 │
│                                                         │
│ NEXT TIME:                                             │
│    A.jpg → Check cache → Found! → Skip steps 1,2,3     │
│    → Upload cached directly ✨                         │
└─────────────────────────────────────────────────────────┘
```

## 🔑 **KEY INSIGHT: Check Cache BEFORE Processing**

**Workflow mới (OPTIMAL):**
```
File A (original)
  ↓
Check cache: hash(A) → 20251209_abc123.jpg exists?
  │
  ├─ ✅ YES → Use cached file
  │          SKIP rotation
  │          SKIP OCR
  │          Upload directly
  │
  └─ ❌ NO  → Rotate A → A_rotated
                      ↓
                    OCR to get mã hiệu
                      ↓
                    Compress A_rotated
                      ↓
                    Save as 20251209_abc123.jpg (cache)
                      ↓
                    Upload
                      ↓
                    Delete A_rotated
```

**Performance Impact:**
```
First upload (cache miss):
  Rotation: 500ms
  OCR: 300ms
  Compression: 500ms
  Upload: 2000ms
  Total: 3300ms

Second upload (cache hit):
  Check cache: 10ms ✅
  Upload cached: 2000ms
  Total: 2010ms
  
Savings: 39% faster! 🚀
```

## 📁 File Lifecycle

### Original File
- **Path**: `/storage/emulated/0/DCIM/Camera/IMG20251209151922.jpg`
- **Lifecycle**: PERMANENT (người dùng tự quản lý)
- **Purpose**: Source image from camera/gallery

### Rotated File (TEMPORARY)
- **Path**: `/data/user/0/com.example.phone_auto_portal/cache/IMG20251209151922_rotated.jpg`
- **Lifecycle**: TEMPORARY (xóa sau khi upload xong)
- **Purpose**: 
  - Corrected orientation for OCR
  - Input for compression
- **Deleted**: In `finally` block after upload completes

### Compressed File (CACHED)
- **Path**: `/data/user/0/com.example.phone_auto_portal/cache/telegram_compressed/20251209_a1b2c3d4e5f6g7h8.jpg`
- **Lifecycle**: PERSISTENT (giữ cả ngày)
- **Purpose**: 
  - Optimized for upload (smaller size)
  - Reusable if same image uploaded multiple times
- **Deleted**: Automatically cleaned up at app startup (only keep today's files)

## 🔑 Cache Key Generation

```dart
String generateCacheKey(File originalFile) {
  // Cache key dựa trên ORIGINAL FILE, không phải rotated file
  final filePath = originalFile.absolute.path;
  final lastModified = originalFile.lastModifiedSync().millisecondsSinceEpoch;
  final combined = '$filePath:$lastModified';
  final hash = md5(combined).substring(0, 16);
  
  final today = DateTime.now();
  final datePrefix = 'YYYYMMDD'; // e.g., 20251209
  
  return '${datePrefix}_${hash}.jpg';
}
```

**Example:**
- Original: `/DCIM/Camera/IMG20251209151922.jpg` (modified: 1702123456789)
- Hash: `md5("/DCIM/Camera/IMG20251209151922.jpg:1702123456789")` → `a1b2c3d4e5f6g7h8`
- Cache: `20251209_a1b2c3d4e5f6g7h8.jpg`

**IMPORTANT:** Cache key từ **original file**, không phải rotated file!

### Tại sao dùng Original File?

```
❌ WRONG (cache key from rotated file):
Upload lần 1: A.jpg → A_rotated.jpg → cache(A_rotated) → delete A_rotated
Upload lần 2: A.jpg → A_rotated.jpg (NEW file, different path/time)
               → cache MISS (key khác) → compress lại ❌

✅ CORRECT (cache key from original file):
Upload lần 1: A.jpg → cache key = hash(A.jpg)
              → A_rotated.jpg → compress → save cache
              → delete A_rotated
Upload lần 2: A.jpg → cache key = hash(A.jpg) 
              → cache HIT! ✅ (không cần rotate/compress)
```

## 🧹 Cache Cleanup Strategy

### At App Startup (`ImageCacheService.init()`)
```dart
1. Scan /cache/telegram_compressed/
2. Get today's date prefix (e.g., 20251209)
3. For each file:
   - Check if filename starts with today's prefix
   - If NO → Delete (old cache)
   - If YES → Keep (today's cache)
```

### Manual Cleanup (Optional)
```dart
// Clear all cache
await ImageCacheService.instance.clearAllCache();

// Get cache info
final info = await ImageCacheService.instance.getCacheInfo();
print(info); // CacheInfo(files: 15, size: 12.3 MB)
```

## ⚡ Performance Benefits

### Without Cache (Old Workflow)
```
Upload same image 3 times (always process):
- Rotation: 3 times × 500ms = 1500ms
- OCR: 3 times × 300ms = 900ms
- Compression: 3 times × 500ms = 1500ms
- Upload: 3 times × 2000ms = 6000ms
- Total: 9900ms (9.9s)
```

### With Cache (New Workflow)
```
Upload same image 3 times:

First upload (cache miss):
- Check cache: 10ms (miss)
- Rotation: 500ms
- OCR: 300ms
- Compression: 500ms
- Upload: 2000ms
- Subtotal: 3310ms

Second upload (cache hit):
- Check cache: 10ms (HIT!) ✅
- Rotation: SKIPPED
- OCR: SKIPPED
- Compression: SKIPPED
- Upload cached: 2000ms
- Subtotal: 2010ms

Third upload (cache hit):
- Check cache: 10ms (HIT!) ✅
- Upload cached: 2000ms
- Subtotal: 2010ms

Total: 7330ms (7.3s)
Savings: 26% faster! 🚀
```

### Additional Benefits
- ✅ **CPU savings**: No redundant rotation/OCR/compression
- ✅ **Battery savings**: Less image processing
- ✅ **Consistency**: Same compressed version every time
- ✅ **User Experience**: Faster subsequent uploads
- ✅ **Network optimization**: Can use Media Group more efficiently

## 🛡️ Error Handling

### If Compression Fails
```dart
try {
  compressed = await compressAndCacheImage(rotatedFile);
} catch (e) {
  // Fallback: use rotated file directly (no compression)
  compressed = rotatedFile;
}
```

### If Cache Read Fails
```dart
try {
  cached = await getCachedCompressedImage(rotatedFile);
} catch (e) {
  // Fallback: compress new file
  cached = await compressAndCacheImage(rotatedFile);
}
```

### If Cleanup Fails
```dart
try {
  await rotatedFile.delete();
} catch (e) {
  // Silent ignore - don't block upload
  debugLog('⚠️ Could not delete temp file: $e');
}
```

## 📊 Cache Statistics

Check cache status at any time:

```dart
final cacheInfo = await ImageCacheService.instance.getCacheInfo();

print(cacheInfo.fileCount);    // 15 files
print(cacheInfo.totalSize);    // 12345678 bytes
print(cacheInfo.formattedSize); // "11.8 MB"
```

## 🔍 Debugging

Enable debug logs to track file lifecycle:

```
[ImageCacheService] 📁 Created cache directory: /cache/telegram_compressed
[ImageCacheService] ✅ Cleaned up 5 old cached files
[ImageCacheService] ✅ Found cached compressed image: 20251209_a1b2c3d4e5f6g7h8.jpg
[ImageImportController] ✅ Đã xóa file rotated tạm: /cache/IMG20251209151922_rotated.jpg
```

## 🎯 Summary

| File Type | Location | Lifecycle | Purpose |
|-----------|----------|-----------|---------|
| **Original** | `/DCIM/...` | Permanent | User's photo |
| **Rotated** | `/cache/` | Temporary | OCR input |
| **Compressed** | `/cache/telegram_compressed/` | Daily cache | Upload optimization |

**Key Principle:** 
- Delete ROTATED files after use (temporary correction)
- Keep COMPRESSED files all day (performance optimization)
- Clean old COMPRESSED files at startup (storage management)
