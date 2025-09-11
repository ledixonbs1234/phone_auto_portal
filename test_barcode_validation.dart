// Test cases for barcode validation
void main() {
  // Valid test cases
  final validCodes = [
    'C1234567890VN', // Starts with C, 10 digits, ends with VN
    'E9876543210VN', // Starts with E, 10 digits, ends with VN
    'c1111111111vn', // Lowercase should work after toUpperCase
    'e0000000000vn', // Lowercase should work after toUpperCase
  ];

  // Invalid test cases
  final invalidCodes = [
    'C123456789VN', // Only 12 chars (missing 1 digit)
    'C12345678901VN', // 14 chars (too long)
    'A1234567890VN', // Starts with A (not C or E)
    'F1234567890VN', // Starts with F (not C or E)
    'C1234567890CN', // Ends with CN (not VN)
    'C1234567890EN', // Ends with EN (not VN)
    'C12345A7890VN', // Contains letter A in middle
    'C123456789XVN', // Contains letter X in middle
    '', // Empty string
    'short', // Too short
  ];

  print('=== VALID BARCODE TESTS ===');
  for (final code in validCodes) {
    final result = validateBarcode(code.toUpperCase());
    print('$code -> ${result ? "✅ VALID" : "❌ INVALID"}');
  }

  print('\n=== INVALID BARCODE TESTS ===');
  for (final code in invalidCodes) {
    final result = validateBarcode(code.toUpperCase());
    print('$code -> ${result ? "❌ UNEXPECTED VALID" : "✅ CORRECTLY INVALID"}');
  }
}

// Manual validation function for testing
bool validateBarcode(String barcode) {
  // Kiểm tra độ dài
  if (barcode.length != 13) {
    return false;
  }

  // Kiểm tra chữ cái đầu tiên (C hoặc E)
  final firstChar = barcode[0];
  if (firstChar != 'C' && firstChar != 'E') {
    return false;
  }

  // Kiểm tra 2 chữ cái cuối cùng (VN)
  final lastTwoChars = barcode.substring(11, 13);
  if (lastTwoChars != 'VN') {
    return false;
  }

  // Kiểm tra từ vị trí 2 đến trước VN (vị trí 1-10) là số
  final middlePart = barcode.substring(1, 11);
  final isAllDigits = RegExp(r'^\d+$').hasMatch(middlePart);
  if (!isAllDigits) {
    return false;
  }

  return true;
}
