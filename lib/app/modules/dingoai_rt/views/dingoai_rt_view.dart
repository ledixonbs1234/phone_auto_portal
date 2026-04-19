import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dingoai_rt_controller.dart';
import '../../../routes/app_pages.dart';

class DiNgoaiRtView extends GetView<DiNgoaiRtController> {
  const DiNgoaiRtView({super.key});

  // ── Color Palette ──────────────────────────────────
  static const _primaryDark = Color(0xFF1A1D29);
  static const _primaryBlue = Color(0xFF4A7DFF);
  static const _accentCyan = Color(0xFF00D4AA);
  static const _successGreen = Color(0xFF22C55E);
  static const _dangerRed = Color(0xFFEF4444);
  static const _warningOrange = Color(0xFFF59E0B);
  static const _surfaceCard = Color(0xFF232736);
  static const _surfaceDark = Color(0xFF1E2130);
  static const _textPrimary = Color(0xFFF1F3F9);
  static const _textSecondary = Color(0xFF8B92A8);
  static const _dividerColor = Color(0xFF2D3148);

  // ── Item Builder ───────────────────────────────────
  Widget _buildDiNgoaiItem(BuildContext context, int index) {
    return Obx(() {
      final item = controller.diNgoaiItems[index];
      final isSelected = item.selected;

      // State-based styling
      Color accentColor;
      Color bgColor;
      IconData stateIcon;
      bool showStateIcon = true;

      switch (item.state) {
        case 1: // Thành công
          accentColor = _successGreen;
          bgColor = isSelected
              ? _successGreen.withValues(alpha: 0.15)
              : _surfaceCard;
          stateIcon = Icons.check_circle_rounded;
          break;
        case 2: // Thất bại
          accentColor = _dangerRed;
          bgColor = isSelected
              ? _dangerRed.withValues(alpha: 0.15)
              : _surfaceCard;
          stateIcon = Icons.cancel_rounded;
          break;
        default: // Chưa xử lý
          accentColor = isSelected ? _primaryBlue : _textSecondary;
          bgColor = isSelected
              ? _primaryBlue.withValues(alpha: 0.10)
              : _surfaceCard;
          stateIcon = Icons.radio_button_unchecked;
          showStateIcon = false;
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.5)
                : _dividerColor.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => controller.toggleSelect(index),
            splashColor: accentColor.withValues(alpha: 0.1),
            highlightColor: accentColor.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Index Badge
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: isSelected || item.state != 0
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor,
                                accentColor.withValues(alpha: 0.7),
                              ],
                            )
                          : null,
                      color: isSelected || item.state != 0
                          ? null
                          : _dividerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isSelected || item.state != 0
                              ? Colors.white
                              : _textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.code,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: item.state == 2
                                ? _dangerRed.withValues(alpha: 0.8)
                                : _textPrimary,
                            decoration: item.state == 1
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: _successGreen.withValues(alpha: 0.5),
                          ),
                        ),
                        if (item.buuCucNhanTemp != null &&
                            item.buuCucNhanTemp!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.buuCucNhanTemp!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // State indicator
                  if (showStateIcon)
                    Icon(stateIcon, color: accentColor, size: 22)
                  else if (isSelected)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ── Connection Status Badge ────────────────────────
  Widget _buildConnectionBadge() {
    return Obx(() {
      Color badgeColor;
      String label;
      IconData icon;

      switch (controller.pingStatus.value) {
        case 'online':
          badgeColor = _successGreen;
          label = '${controller.pingResponseTime.value}ms';
          icon = Icons.wifi_rounded;
          break;
        case 'offline':
          badgeColor = _dangerRed;
          label = 'Offline';
          icon = Icons.wifi_off_rounded;
          break;
        case 'pinging':
          badgeColor = _warningOrange;
          label = 'Ping...';
          icon = Icons.sync_rounded;
          break;
        default:
          badgeColor = _textSecondary;
          label = '---';
          icon = Icons.wifi_rounded;
      }

      return GestureDetector(
        onTap: controller.isPinging.value ? null : controller.pingPC,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              controller.isPinging.value
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation(badgeColor),
                      ),
                    )
                  : Icon(icon, color: badgeColor, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Stats Chips ────────────────────────────────────
  Widget _buildStatChip(String label, String value, Color color) {
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

  // ── Bottom Action Button ───────────────────────────
  Widget _buildActionButton({
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
                        colors: [
                          color,
                          color.withValues(alpha: 0.8),
                        ],
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
  Widget _buildToggleOption(String label, RxBool value) {
    return Obx(() => GestureDetector(
          onTap: () => value.value = !value.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: value.value
                  ? _primaryBlue.withValues(alpha: 0.15)
                  : _surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: value.value
                    ? _primaryBlue.withValues(alpha: 0.4)
                    : _dividerColor,
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
                    color: value.value ? _primaryBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: value.value ? _primaryBlue : _textSecondary,
                      width: 1.5,
                    ),
                  ),
                  child: value.value
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: value.value ? _primaryBlue : _textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  // ── Empty State ────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: _primaryBlue.withValues(alpha: 0.4),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có bưu gửi',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quét QR hoặc chờ dữ liệu từ PC',
            style: TextStyle(
              color: _textSecondary.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Main Build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryDark,
      appBar: AppBar(
        backgroundColor: _surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textPrimary, size: 20),
          onPressed: controller.goBack,
        ),
        title: const Text(
          'Đi Ngoài RT',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          // Connection badge
          _buildConnectionBadge(),
          const SizedBox(width: 6),

          // QR Scanner
          Obx(() => _buildAppBarAction(
                icon: Icons.qr_code_scanner_rounded,
                onPressed: controller.isScanning.value
                    ? null
                    : controller.showScanner,
                color: _accentCyan,
              )),

          // Danh Sách BĐ
          _buildAppBarAction(
            icon: Icons.list_alt_rounded,
            onPressed: () => Get.toNamed(Routes.DANHSACHBD),
            color: _primaryBlue,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Separator line ──
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryBlue.withValues(alpha: 0.0),
                  _primaryBlue.withValues(alpha: 0.3),
                  _primaryBlue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

          // ── Status & Stats Header ──
          Obx(() => AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: _surfaceDark,
                  child: Column(
                    children: [
                      // State text banner
                      if (controller.stateText.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primaryBlue.withValues(alpha: 0.12),
                                _accentCyan.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _primaryBlue.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            controller.stateText.value.isEmpty
                                ? 'Sẵn sàng xử lý'
                                : controller.stateText.value,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatChip(
                            'bưu gửi',
                            '${controller.diNgoaiItems.length}',
                            _primaryBlue,
                          ),
                          const SizedBox(width: 10),
                          _buildStatChip(
                            'đã chọn',
                            '${controller.selectedCount.value}',
                            _accentCyan,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),

          // ── List ──
          Expanded(
            child: Obx(() {
              if (controller.diNgoaiItems.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.diNgoaiItems.length,
                itemBuilder: (context, index) =>
                    _buildDiNgoaiItem(context, index),
              );
            }),
          ),

          // ── Bottom Action Bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: _surfaceDark,
              border: Border(
                top: BorderSide(
                  color: _dividerColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Toggle options
                  Row(
                    children: [
                      _buildToggleOption('Auto', controller.isAuto),
                      const SizedBox(width: 10),
                      _buildToggleOption('In', controller.isPrint),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Action buttons
                  Obx(() => Row(
                        children: [
                          _buildActionButton(
                            icon: Icons.refresh_rounded,
                            label: 'Refresh',
                            color: _warningOrange,
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.refreshData,
                            onLongPress: controller.isLoading.value
                                ? null
                                : controller.lamMoi,
                          ),
                          _buildActionButton(
                            icon: Icons.delete_outline_rounded,
                            label: 'Xóa',
                            color: _dangerRed,
                            onPressed: controller.deleteSelected,
                            onLongPress: controller.deleteAll,
                          ),
                          _buildActionButton(
                            icon: Icons.play_arrow_rounded,
                            label: 'Auto',
                            color: _primaryBlue,
                            onPressed: controller.runAuto,
                          ),
                        ],
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar Action Helper ───────────────────────────
  Widget _buildAppBarAction({
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
}
