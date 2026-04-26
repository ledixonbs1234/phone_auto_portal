import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Controls the app-wide theme (dark / light).
///
/// Persists the user's choice in [GetStorage] so it survives restarts.
class ThemeController extends GetxController {
  static const _storageKey = 'isDarkMode';
  final _storage = GetStorage();

  /// `true` → dark mode (default), `false` → light mode.
  final isDarkMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Restore persisted preference (default = dark).
    isDarkMode.value = _storage.read<bool>(_storageKey) ?? true;
    _applyTheme();
  }

  /// Toggle between dark and light mode.
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _storage.write(_storageKey, isDarkMode.value);
    _applyTheme();
  }

  void _applyTheme() {
    Get.changeThemeMode(
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
    );
    // Force full widget tree rebuild so all AppTheme dynamic getters
    // (primaryDark, surfaceCard, etc.) return updated colors immediately.
    Future.microtask(() => Get.forceAppUpdate());
  }
}
