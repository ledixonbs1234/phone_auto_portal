import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/barcode_scanner_model.dart';

void main() {
  group('DirectionScanSession Tests', () {
    test('should calculate progress correctly', () {
      final session = DirectionScanSession(
        direction: 'RA',
        startTime: DateTime.now(),
        scannedPackages: [],
        totalPackagesInDirection: 100,
      );

      // Initially no progress
      expect(session.progress, 0.0);

      // After processing 25 packages
      session.processedCount = 25;
      expect(session.progress, 25.0);

      // After processing 50 packages
      session.processedCount = 50;
      expect(session.progress, 50.0);

      // Complete processing
      session.processedCount = 100;
      expect(session.progress, 100.0);
    });

    test('should calculate remaining count correctly', () {
      final session = DirectionScanSession(
        direction: 'VÔ',
        startTime: DateTime.now(),
        scannedPackages: [],
        totalPackagesInDirection: 80,
      );

      session.processedCount = 30;
      expect(session.remainingCount, 50);

      session.processedCount = 80;
      expect(session.remainingCount, 0);
    });
  });

  group('ScannedPackage Tests', () {
    test('should return correct status text for successful scan', () {
      final package = ScannedPackage(
        barcode: 'TEST123',
        scannedTime: DateTime.now(),
        isFoundInCurrentDirection: true,
        currentDirection: 'RA',
      );

      expect(package.statusText, 'Đã xử lý ✓');
    });

    test('should return correct status text for wrong direction', () {
      final package = ScannedPackage(
        barcode: 'TEST456',
        scannedTime: DateTime.now(),
        foundInDirection: 'VÔ',
        isFoundInCurrentDirection: false,
        currentDirection: 'RA',
      );

      expect(package.statusText, 'Có trong hướng: VÔ');
    });

    test('should return correct status text for not found', () {
      final package = ScannedPackage(
        barcode: 'NOTFOUND',
        scannedTime: DateTime.now(),
        isFoundInCurrentDirection: false,
        currentDirection: 'RA',
      );

      expect(package.statusText, 'Không tìm thấy');
    });

    test('should serialize to/from JSON correctly', () {
      final originalPackage = ScannedPackage(
        barcode: 'JSON_TEST',
        scannedTime: DateTime.parse('2025-09-06T12:00:00'),
        foundInDirection: 'Quảng Nam',
        isFoundInCurrentDirection: false,
        currentDirection: 'RA',
      );

      final json = originalPackage.toJson();
      final reconstructedPackage = ScannedPackage.fromJson(json);

      expect(reconstructedPackage.barcode, originalPackage.barcode);
      expect(reconstructedPackage.foundInDirection,
          originalPackage.foundInDirection);
      expect(reconstructedPackage.isFoundInCurrentDirection,
          originalPackage.isFoundInCurrentDirection);
      expect(reconstructedPackage.currentDirection,
          originalPackage.currentDirection);
    });
  });
}
