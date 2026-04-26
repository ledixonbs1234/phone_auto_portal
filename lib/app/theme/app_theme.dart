import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/theme/theme_controller.dart';

/// Shared theme palette & reusable widgets for the entire app.
///
/// Supports **dark** and **light** modes via [ThemeController].
///
/// Usage:
/// ```dart
/// import 'package:phone_auto_portal/app/theme/app_theme.dart';
///
/// Scaffold(backgroundColor: AppTheme.primaryDark, ...)
/// ```
class AppTheme {
  AppTheme._(); // Prevent instantiation

  // ── Helper ─────────────────────────────────────────
  static bool get _isDark {
    try {
      return Get.find<ThemeController>().isDarkMode.value;
    } catch (_) {
      return true; // fallback to dark before controller is registered
    }
  }

  // ── Color Palette ──────────────────────────────────
  // Accent colors stay the same in both themes
  static const primaryBlue = Color(0xFF4A7DFF);
  static const accentCyan = Color(0xFF00D4AA);
  static const successGreen = Color(0xFF22C55E);
  static const dangerRed = Color(0xFFEF4444);
  static const warningOrange = Color(0xFFF59E0B);

  // Theme-dependent colors
  static Color get primaryDark =>
      _isDark ? const Color(0xFF1A1D29) : const Color(0xFFF5F6FA);

  static Color get surfaceCard =>
      _isDark ? const Color(0xFF232736) : Colors.white;

  static Color get surfaceDark =>
      _isDark ? const Color(0xFF1E2130) : const Color(0xFFEEEFF5);

  static Color get textPrimary =>
      _isDark ? const Color(0xFFF1F3F9) : const Color(0xFF1A1D29);

  static Color get textSecondary =>
      _isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);

  static Color get dividerColor =>
      _isDark ? const Color(0xFF2D3148) : const Color(0xFFE0E2EB);

  // ── Flutter ThemeData builders ─────────────────────
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1D29),
        colorScheme: const ColorScheme.dark(
          primary: primaryBlue,
          secondary: accentCyan,
          surface: Color(0xFF232736),
        ),
        fontFamily: 'Roboto',
      );

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        colorScheme: const ColorScheme.light(
          primary: primaryBlue,
          secondary: accentCyan,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
      );

  // ── AppBar ─────────────────────────────────────────
  static AppBar buildAppBar({
    required String title,
    VoidCallback? onBack,
    List<Widget>? actions,
    Widget? titleWidget,
    bool centerTitle = false,
  }) {
    return AppBar(
      backgroundColor: surfaceDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: onBack != null
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: textPrimary, size: 20),
              onPressed: onBack,
            )
          : null,
      title: titleWidget ??
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
      centerTitle: centerTitle,
      iconTheme: IconThemeData(color: textPrimary),
      actions: actions,
    );
  }

  // ── Gradient Separator ─────────────────────────────
  static Widget gradientSeparator() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryBlue.withValues(alpha: 0.0),
            primaryBlue.withValues(alpha: 0.3),
            primaryBlue.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  // ── AppBar Icon Button ─────────────────────────────
  static Widget appBarAction({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  // ── Action Button (dark chip) ───────────────────────
  static Widget actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: onPressed != null
                ? color.withValues(alpha: 0.12)
                : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: onPressed != null
                  ? color.withValues(alpha: 0.25)
                  : color.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: onPressed != null
                      ? color
                      : color.withValues(alpha: 0.4),
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: onPressed != null
                      ? color
                      : color.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stat Chip ──────────────────────────────────────
  static Widget statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Gradient Action Button ─────────────────────────
  static Widget gradientButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: onPressed != null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withValues(alpha: 0.8)],
                      )
                    : null,
                color: onPressed == null
                    ? color.withValues(alpha: 0.3)
                    : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: onPressed != null
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Toggle Option ──────────────────────────────────
  static Widget toggleOption(String label, bool value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: value
              ? primaryBlue.withValues(alpha: 0.15)
              : surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value
                ? primaryBlue.withValues(alpha: 0.4)
                : dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value ? primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: value ? primaryBlue : textSecondary,
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: value ? primaryBlue : textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────
  static Widget emptyState({
    IconData icon = Icons.inventory_2_outlined,
    String title = 'Không có dữ liệu',
    String subtitle = '',
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: primaryBlue.withValues(alpha: 0.4),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: textSecondary.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Card Container ─────────────────────────────────
  static Widget cardContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dividerColor.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }

  // ── Input Field ────────────────────────────────────
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textSecondary, fontSize: 14),
      hintText: hint,
      hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: textSecondary) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: surfaceCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dividerColor.withValues(alpha: 0.3)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── Status Banner ──────────────────────────────────
  static Widget statusBanner(String text, {int? maxLines}) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryBlue.withValues(alpha: 0.12),
            accentCyan.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        textAlign: TextAlign.center,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      ),
    );
  }

  // ── Bottom Action Bar Container ────────────────────
  static Widget bottomBar({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: surfaceDark,
        border: Border(
          top: BorderSide(
            color: dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(top: false, child: child),
    );
  }

  // ── Section Header ─────────────────────────────────
  static Widget sectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ── Dark Dropdown Style ────────────────────────────
  static DropdownButtonFormField<T> darkDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? label,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: surfaceCard,
      style: TextStyle(color: textPrimary, fontSize: 14),
      decoration: inputDecoration(label: label ?? ''),
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: textSecondary),
    );
  }
}
