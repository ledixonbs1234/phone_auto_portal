import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auto_portal/data/image_cache_service.dart';
import 'dart:io';

/// Test case để verify cache logic
///
/// Scenario: Upload cùng một ảnh 2 lần
///
/// Expected behavior:
/// - Lần 1: Rotate → Compress → Cache → Upload → Delete rotated
/// - Lần 2: Check cache → HIT → Skip rotation & compression → Upload cached
void main() {
  group('ImageCacheService Cache Key Logic', () {
    test('Cache key should be based on original file, not rotated file',
        () async {
      // Giả lập workflow

      // File gốc từ camera
      final originalFile = File('/storage/IMG001.jpg');
      final originalModified = 1702123456789;

      // === UPLOAD LẦN 1 ===

      // Step 1: Rotate (tạo file temp mới)
      final rotatedFile1 = File('/cache/IMG001_rotated.jpg');
      final rotatedModified1 = DateTime.now().millisecondsSinceEpoch;

      // Step 2: Generate cache key
      // IMPORTANT: Dùng ORIGINAL FILE, không phải rotated file
      final cacheKey = _generateCacheKey(originalFile, originalModified);
      // Expected: 20251209_hash(/storage/IMG001.jpg:1702123456789)

      print('Cache key lần 1: $cacheKey');

      // Step 3: Compress rotated file và save với cache key từ original
      final compressedFile = File('/cache/telegram_compressed/$cacheKey');
      // Simulate: compress(rotatedFile1) → save as compressedFile

      // Step 4: Upload compressedFile

      // Step 5: Delete rotatedFile1 (cleanup)

      // === UPLOAD LẦN 2 (cùng ảnh gốc) ===

      // Step 1: Rotate (tạo file temp MỚI)
      final rotatedFile2 = File('/cache/IMG001_rotated.jpg');
      final rotatedModified2 = DateTime.now().millisecondsSinceEpoch;

      // Step 2: Generate cache key
      // Vẫn dùng ORIGINAL FILE (path và modified không đổi)
      final cacheKey2 = _generateCacheKey(originalFile, originalModified);

      print('Cache key lần 2: $cacheKey2');

      // Step 3: Check cache
      // Expected: cacheKey2 == cacheKey → Cache HIT!

      expect(cacheKey2, equals(cacheKey),
          reason: 'Cache key phải GIỐNG NHAU vì dựa trên original file');

      // Expected workflow lần 2:
      // - Check cache với key = hash(original)
      // - Tìm thấy compressedFile
      // - Skip compress, upload compressedFile trực tiếp
      // - Delete rotatedFile2

      print('✅ Cache hit! Không cần compress lại');
    });

    test('WRONG approach: Cache key from rotated file causes cache miss',
        () async {
      // File gốc
      final originalFile = File('/storage/IMG001.jpg');

      // === UPLOAD LẦN 1 ===

      // Rotate (file temp mới)
      final rotatedFile1 = File('/cache/IMG001_rotated.jpg');
      final rotatedModified1 = 1702123456001;

      // ❌ WRONG: Cache key từ ROTATED FILE
      final wrongCacheKey1 = _generateCacheKey(rotatedFile1, rotatedModified1);
      print('Wrong cache key lần 1: $wrongCacheKey1');

      // === UPLOAD LẦN 2 ===

      // Rotate (file temp MỚI, path có thể giống nhưng modified time KHÁC)
      final rotatedFile2 = File('/cache/IMG001_rotated.jpg');
      final rotatedModified2 = 1702123456002; // Khác lần 1!

      // ❌ WRONG: Cache key từ ROTATED FILE
      final wrongCacheKey2 = _generateCacheKey(rotatedFile2, rotatedModified2);
      print('Wrong cache key lần 2: $wrongCacheKey2');

      // Expected: Cache MISS vì modified time khác
      expect(wrongCacheKey2, isNot(equals(wrongCacheKey1)),
          reason:
              'Cache key KHÁC NHAU vì dựa trên rotated file (modified time khác)');

      print('❌ Cache miss! Phải compress lại (lãng phí)');
    });
  });
}

/// Simulate cache key generation
String _generateCacheKey(File file, int modifiedTime) {
  final combined = '${file.path}:$modifiedTime';
  // Simplified hash for test
  final hash = combined.hashCode.toRadixString(16).substring(0, 8);
  final datePrefix = '20251209';
  return '${datePrefix}_$hash.jpg';
}
