import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/widgets/host_selection_widget.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';

import '../controllers/home_controller.dart';

import '../khach_hangs_model.dart';
import '../user_info.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  // ── Action Button (dark style) ─────────────────────
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
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
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
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

  // ── Login Dialog ───────────────────────────────────
  void _showLoginDialog(BuildContext context) {
    final usernameController = TextEditingController(
        text: controller.selectedUser.value?.username ?? '');
    final passwordController = TextEditingController(
        text: controller.selectedUser.value?.password ?? '');

    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cài đặt tài khoản Portal",
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: AppTheme.inputDecoration(
                label: "Tài khoản",
                prefixIcon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: AppTheme.inputDecoration(
                label: "Mật khẩu",
                prefixIcon: Icons.lock_outline_rounded,
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.selectedUser.value =
                  UserInfo(name: 'Không chọn', username: '', password: '');
              Get.back();
            },
            child: const Text("Thoát",
                style: TextStyle(color: AppTheme.dangerRed)),
          ),
          ElevatedButton(
            onPressed: () {
              if (usernameController.text.isNotEmpty) {
                controller.selectedUser.value = UserInfo(
                  name: usernameController.text,
                  username: usernameController.text,
                  password: passwordController.text,
                );
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // ── Quick Nav Button ───────────────────────────────
  Widget _buildNavChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        resizeToAvoidBottomInset: false,
        appBar: AppTheme.buildAppBar(
          title: '',
          titleWidget: const HostSelectionWidget(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => controller.gotoPortalInfo(),
          backgroundColor: AppTheme.primaryBlue,
          child: const Icon(Icons.settings, color: Colors.white),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Obx(
              () => Column(
                children: [
                  AppTheme.gradientSeparator(),

                  // ── User Account Section ──
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Obx(() {
                            final user = controller.selectedUser.value;
                            final hasUser =
                                user != null && user.username.isNotEmpty;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasUser
                                      ? AppTheme.accentCyan
                                          .withValues(alpha: 0.3)
                                      : AppTheme.dividerColor,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    hasUser
                                        ? Icons.account_circle_rounded
                                        : Icons.person_off_rounded,
                                    color: hasUser
                                        ? AppTheme.accentCyan
                                        : AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    hasUser
                                        ? "TK: ${user.username}"
                                        : "Chưa đăng nhập",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: hasUser
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showLoginDialog(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.25)),
                            ),
                            child: const Icon(Icons.settings_rounded,
                                color: AppTheme.primaryBlue, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Data Action Row ──
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.cloud_download_rounded,
                            label: 'Get Portal Data',
                            color: AppTheme.primaryBlue,
                            onPressed: () => controller.getPortalData(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.add_box_rounded,
                            label: 'Get My Post',
                            color: AppTheme.successGreen,
                            onPressed: () => controller.goToMyPost(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Captcha / Login Section ──
                  controller.imageBytes.value.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: AppTheme.cardContainer(
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    const Base64Decoder()
                                        .convert(controller.imageBytes.value),
                                    width: 250,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      child: TextField(
                                        onSubmitted: (value) =>
                                            controller.loginPNS(),
                                        controller:
                                            controller.capcharController,
                                        style: const TextStyle(
                                            color: AppTheme.textPrimary),
                                        decoration: AppTheme.inputDecoration(
                                            label: 'Captcha'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      icon: Icons.login_rounded,
                                      label: 'PNS',
                                      color: AppTheme.successGreen,
                                      onPressed: () => controller.loginPNS(),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      icon: Icons.login_rounded,
                                      label: 'GD',
                                      color: const Color(0xFF9B5DE5),
                                      onPressed: () => controller.loginPNS(
                                          isGiaoDich: true),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),

                  // ── Customer Dropdown ──
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: DropdownButton<KhachHangs>(
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceCard,
                        underline: const SizedBox.shrink(),
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.textPrimary),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textSecondary),
                        value: controller.seKhachHangs.value,
                        items: controller.khachHangs
                            .map<DropdownMenuItem<KhachHangs>>(
                                (KhachHangs e) {
                          return DropdownMenuItem<KhachHangs>(
                            value: e,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    e.tenKH!.length > 30
                                        ? e.tenKH!
                                            .substring(e.tenKH!.length - 30)
                                        : e.tenKH!,
                                    style: const TextStyle(
                                        color: AppTheme.accentCyan),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "${e.countState!.countDangGom.toString().padLeft(3, ' ')} ${e.countState!.countPhanHuong.toString().padLeft(3, ' ')} ",
                                      style: const TextStyle(
                                          color: AppTheme.primaryBlue),
                                    ),
                                    Text(
                                      "${e.countState!.countNhanHang.toString().padLeft(3, ' ')} ",
                                      style: const TextStyle(
                                          color: AppTheme.dangerRed),
                                    ),
                                    Text(
                                      e.countState!.countChapNhan
                                          .toString()
                                          .padLeft(3, ' '),
                                      style: TextStyle(
                                          color: AppTheme.primaryBlue
                                              .withValues(alpha: 0.6)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (KhachHangs? value) async {
                          if (value == null) return;
                          controller.seKhachHangs.value = value;
                          controller.lastSelectKH = value.maKH!;
                          controller.checkHopDong(value);
                        },
                      ),
                    ),
                  ),

                  // ── Time Update ──
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            color: AppTheme.warningOrange.withValues(alpha: 0.7),
                            size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "Time Update: ${controller.timeUpdate.value}",
                          style: const TextStyle(
                              color: AppTheme.warningOrange, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  // ── Search MH ──
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        const Text('Tìm kiếm MH:',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller.textMHController,
                            keyboardType: TextInputType.number,
                            style:
                                const TextStyle(color: AppTheme.textPrimary),
                            decoration: AppTheme.inputDecoration(
                                label: '', hint: 'Nhập mã hiệu'),
                            onChanged: (value) {
                              controller.textMH.value = value;
                              if (value.isNotEmpty && value.length >= 2) {
                                controller.findKhachHangsByMH(value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── State Text ──
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: AppTheme.statusBanner('${controller.stateText}'),
                  ),

                  // ── Contract Card ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AppTheme.cardContainer(
                      child: Column(
                        children: [
                          TextField(
                            enabled: false,
                            controller: controller.maKHController,
                            style: const TextStyle(
                                color: AppTheme.dangerRed, fontSize: 16),
                            decoration:
                                AppTheme.inputDecoration(label: 'Mã KH'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            enabled: controller.isEditHopDong.value,
                            controller: controller.addressController,
                            style:
                                const TextStyle(color: AppTheme.textPrimary),
                            decoration:
                                AppTheme.inputDecoration(label: 'Địa chỉ'),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Có hợp đồng:',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary)),
                              Checkbox(
                                value: controller.isHaveHopDong.value,
                                activeColor: AppTheme.successGreen,
                                checkColor: Colors.white,
                                side: const BorderSide(
                                    color: AppTheme.textSecondary),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                onChanged: controller.isEditHopDong.value
                                    ? (e) =>
                                        controller.isHaveHopDong.value = e!
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              const Text('STT HĐ:',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 50,
                                child: TextField(
                                  enabled: controller.isEditHopDong.value,
                                  keyboardType: TextInputType.number,
                                  controller:
                                      controller.numberHopDongController,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppTheme.dividerColor)),
                                    focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppTheme.primaryBlue)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _buildActionButton(
                                    icon: Icons.edit_rounded,
                                    label: 'Sửa',
                                    color: AppTheme.warningOrange,
                                    onPressed: () =>
                                        controller.editHopDong(),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionButton(
                                    icon: Icons.save_rounded,
                                    label: 'Lưu',
                                    color: AppTheme.primaryBlue,
                                    onPressed:
                                        controller.isEditHopDong.value
                                            ? () => controller.saveHopDong()
                                            : () {},
                                  ),
                                ],
                              ),
                              _buildActionButton(
                                icon: Icons.rocket_launch_rounded,
                                label: 'Khởi tạo',
                                color: AppTheme.accentCyan,
                                onPressed: () =>
                                    controller.khoiTaoPortal(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Quick Navigation Grid ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildNavChip(
                          icon: Icons.info_outline_rounded,
                          label: 'Chi Tiết',
                          color: const Color(0xFF6366F1),
                          onPressed: () => controller.goToDetail(),
                        ),
                        _buildNavChip(
                          icon: Icons.create_new_folder_rounded,
                          label: 'BM',
                          color: AppTheme.dangerRed,
                          onPressed: () => controller.goToKhoiTaoMoi(),
                        ),
                        _buildNavChip(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Tạo Mới',
                          color: const Color(0xFF9B5DE5),
                          onPressed: () => controller.goToCreateNew(),
                        ),
                        _buildNavChip(
                          icon: Icons.print_rounded,
                          label: 'In MH',
                          color: AppTheme.warningOrange,
                          onPressed: () => controller.goToPrintPage(),
                        ),
                        _buildNavChip(
                          icon: Icons.mark_email_read_rounded,
                          label: 'Quét Thư',
                          color: AppTheme.primaryBlue,
                          onPressed: () => controller.goToQuetThu(),
                        ),
                        _buildNavChip(
                          icon: Icons.qr_code_scanner_rounded,
                          label: 'Quét MH',
                          color: AppTheme.accentCyan,
                          onPressed: () => controller.goToQuetMH(),
                        ),
                        _buildNavChip(
                          icon: Icons.photo_library_rounded,
                          label: 'Import Img',
                          color: const Color(0xFF7C3AED),
                          onPressed: () => controller.goToImportImages(),
                        ),
                        _buildNavChip(
                          icon: Icons.camera_alt_rounded,
                          label: 'Chụp Ảnh',
                          color: const Color(0xFFD946EF),
                          onPressed: () => controller.goToCaptureImage(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ));
  }
}
