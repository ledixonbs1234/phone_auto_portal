import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/controllers/home_controller.dart';
import 'package:phone_auto_portal/app/modules/home/host_info.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';
import 'package:phone_auto_portal/app/theme/theme_controller.dart';

class HostSelectionWidget extends StatelessWidget {
  const HostSelectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final ThemeController themeController = Get.find<ThemeController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 450;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: 2.0,
            horizontal: isNarrowScreen ? 4.0 : 8.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ping button
              GestureDetector(
                onTap: () => controller.sendPing(),
                child: Container(
                  width: isNarrowScreen ? 32 : 36,
                  height: isNarrowScreen ? 32 : 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              SizedBox(width: isNarrowScreen ? 8 : 12),

              // Host Dropdown
              Expanded(
                child: Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.dividerColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: DropdownButton<HostInfo>(
                        value: controller.selectedMayChu.value,
                        onChanged: (value) {
                          controller.selectedMayChu.value = value!;
                          controller.saveKey(value.hostName);
                        },
                        onTap: () => controller.sendPing(),
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: AppTheme.surfaceCard,
                        underline: const SizedBox.shrink(),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                        selectedItemBuilder: (BuildContext context) {
                          return controller.maychus.map<Widget>((HostInfo e) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    e.hostName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Obx(() => Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: e.isOnline.value
                                              ? AppTheme.successGreen
                                              : AppTheme.dangerRed,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (e.isOnline.value
                                                      ? AppTheme.successGreen
                                                      : AppTheme.dangerRed)
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                              ],
                            );
                          }).toList();
                        },
                        items: controller.maychus.map((HostInfo e) {
                          return DropdownMenuItem<HostInfo>(
                            value: e,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Đã xóa Flexible và TextOverflow ở đây
                                Text(
                                  e.hostName,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                Obx(() => Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: e.isOnline.value
                                              ? AppTheme.successGreen
                                              : AppTheme.dangerRed,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (e.isOnline.value
                                                      ? AppTheme.successGreen
                                                      : AppTheme.dangerRed)
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    )),
              ),
              SizedBox(width: isNarrowScreen ? 6 : 10),

              // Days input
              Text(
                'cách',
                style: TextStyle(
                  fontSize: isNarrowScreen ? 12 : 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(width: isNarrowScreen ? 4 : 6),
              SizedBox(
                width: isNarrowScreen ? 35 : 45,
                child: TextField(
                  controller: controller.dayLastController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(width: isNarrowScreen ? 6 : 10),

              // ── Theme Toggle Button ──
              Obx(() => GestureDetector(
                    onTap: () => themeController.toggleTheme(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: isNarrowScreen ? 32 : 36,
                      height: isNarrowScreen ? 32 : 36,
                      decoration: BoxDecoration(
                        color: themeController.isDarkMode.value
                            ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                            : AppTheme.warningOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: themeController.isDarkMode.value
                              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                              : AppTheme.warningOrange.withValues(alpha: 0.4),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return RotationTransition(
                            turns: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          themeController.isDarkMode.value
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          key: ValueKey(themeController.isDarkMode.value),
                          size: 18,
                          color: themeController.isDarkMode.value
                              ? AppTheme.primaryBlue
                              : AppTheme.warningOrange,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
