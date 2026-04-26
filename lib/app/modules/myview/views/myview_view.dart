import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/khach_hangs_model.dart';
import 'package:phone_auto_portal/app/widgets/host_selection_widget.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';

import '../controllers/myview_controller.dart';

class MyviewView extends GetView<MyviewController> {
  const MyviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppTheme.buildAppBar(
        title: 'My VNPOST',
        onBack: () => Get.back(),
        centerTitle: true,
      ),
      body: Obx(
        () => SingleChildScrollView(
          child: Column(
            children: [
              AppTheme.gradientSeparator(),

              // ── Host Selection ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: HostSelectionWidget(),
              ),

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
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textPrimary),
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary),
                    value: controller.seKhachHangs.value,
                    items: controller.khachHangs
                        .map<DropdownMenuItem<KhachHangs>>((KhachHangs e) {
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
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Get Data Button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    AppTheme.gradientButton(
                      icon: Icons.cloud_download_rounded,
                      label: 'Get Portal Data',
                      color: AppTheme.primaryBlue,
                      onPressed: () => controller.getMyPostData(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── State Text ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppTheme.statusBanner('${controller.stateText}'),
              ),

              const SizedBox(height: 8),

              // ── Time Update ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        color:
                            AppTheme.warningOrange.withValues(alpha: 0.7),
                        size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Thời Gian Cập Nhật: ${controller.timeUpdate}',
                      style: TextStyle(
                        color: AppTheme.warningOrange,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // ── Search Section ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.textController,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: AppTheme.inputDecoration(
                          label: 'Mã Khách Hàng',
                          hint: 'Ví dụ: KH00123',
                          suffix: IconButton(
                            icon: Icon(Icons.clear_rounded,
                                color: AppTheme.textSecondary, size: 20),
                            onPressed: () =>
                                controller.textController.clear(),
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            controller.findKhachHang(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => controller
                            .findKhachHang(controller.textController.text),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryBlue,
                                Color(0xFF3A6AE8)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Tìm Kiếm',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Action Buttons ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    AppTheme.gradientButton(
                      icon: Icons.info_outline_rounded,
                      label: 'Chi Tiết',
                      color: const Color(0xFF6366F1),
                      onPressed: () => controller.goToDetail(),
                    ),
                    const SizedBox(width: 8),
                    AppTheme.gradientButton(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Tạo Mới',
                      color: const Color(0xFF9B5DE5),
                      onPressed: () => controller.goToCreateNew(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}