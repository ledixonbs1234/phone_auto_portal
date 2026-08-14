import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/widgets/host_selection_widget.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';
import 'package:phone_auto_portal/app/routes/app_pages.dart';
import '../controllers/portalinfo_controller.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/state_ma_hieu_model.dart';

class PortalinfoView extends GetView<PortalinfoController> {
  const PortalinfoView({super.key});

  String _getLastWords(String? text, int count) {
    if (text == null || text.isEmpty) return "Không có địa chỉ";
    if (text.length <= count) return text;
    return "...${text.substring(text.length - count)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppTheme.buildAppBar(
        title: '',
        titleWidget: const HostSelectionWidget(),
      ),
      body: Column(children: [
        AppTheme.gradientSeparator(),

        // ── Top: Check · Refresh · Search toggle ──
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: AppTheme.actionButton(
                  icon: Icons.check_circle,
                  label: "Check",
                  color: AppTheme.warningOrange,
                  onPressed: () => controller.checkPortal(),
                ),
              ),
              const SizedBox(width: 8),
              AppTheme.actionButton(
                icon: Icons.refresh,
                label: "",
                color: AppTheme.primaryBlue,
                onPressed: () => controller.refreshPortal(null),
              ),
              const SizedBox(width: 8),
              Obx(() => _buildSearchToggle()),
            ],
          ),
        ),

        // ── Collapsible Search & Filter Section ──
        Obx(() => _buildSearchSection(context)),

        // ── Status Row: SL & State ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              AppTheme.statChip('SL', '', AppTheme.warningOrange),
              const SizedBox(width: 4),
              Obx(() => Text(
                    '${controller.countPortalSelected.value}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningOrange),
                  )),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(() => AppTheme.statusBanner(
                    '${controller.stateText}',
                    maxLines: 1)),
              ),
            ],
          ),
        ),

        // ── DataTable ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GetBuilder<PortalinfoController>(
              builder: (dx) => DataTable2(
                isHorizontalScrollBarVisible: false,
                dividerThickness: 0.3,
                showCheckboxColumn: true,
                sortAscending: controller.sortAscending.value,
                sortColumnIndex: controller.sortColumnIndex.value,
                onSelectAll: (value) {
                  for (var row in dx.portals) {
                    row.selected = value!;
                  }
                  dx.update();
                },
                columnSpacing: 5,
                horizontalMargin: 10,
                checkboxHorizontalMargin: 4,
                headingRowColor: WidgetStateProperty.all(AppTheme.surfaceDark),
                headingTextStyle: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.primaryBlue.withValues(alpha: 0.2);
                  }
                  return null;
                }),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.dividerColor.withValues(alpha: 0.5)),
                ),
                columns: [
                  const DataColumn2(
                      label: Text('TT'), fixedWidth: 30, size: ColumnSize.L),
                  DataColumn2(
                    label: const Text('Tên'),
                    numeric: false,
                    onSort: (i, asc) => controller.sortPortals(i, asc),
                  ),
                  DataColumn2(
                    label: const Text('SL'),
                    fixedWidth: 30,
                    numeric: true,
                    onSort: (i, asc) => controller.sortPortals(i, asc),
                  ),
                  DataColumn2(
                    label: const Text('State'),
                    fixedWidth: 70,
                    onSort: (i, asc) => controller.sortPortals(i, asc),
                  ),
                ],
                rows: _buildTableRows(dx, context),
              ),
            ),
          ),
        ),

        // ── Options Card ──
        Obx(() => _buildOptionsCard(context)),

        // ── Bottom Action Bar ──
        AppTheme.bottomBar(
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                AppTheme.actionButton(
                  icon: Icons.analytics,
                  label: 'Thống kê',
                  color: const Color(0xFF9B5DE5),
                  onPressed: () => controller.sendThongKe(),
                ),
                const SizedBox(width: 8),
                AppTheme.actionButton(
                  icon: Icons.print_outlined,
                  label: 'In Ra Vô',
                  color: AppTheme.dangerRed,
                  onPressed: () => controller.printPageSelected(),
                  onLongPress: () => controller.printPageSelectedAndSort(),
                ),
                const SizedBox(width: 8),
                AppTheme.actionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Di Ngoài RT',
                  color: AppTheme.accentCyan,
                  onPressed: () => controller.goToDiNgoaiRT(),
                ),
                const SizedBox(width: 8),
                AppTheme.actionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Check Hướng',
                  color: const Color(0xFF9B5DE5),
                  onPressed: () => controller.goToDirectionScanning(),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Search toggle icon ───────────────────────────────
  Widget _buildSearchToggle() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!controller.isScanSectionVisible.value) {
            controller.fromDate.value = DateTime.now();
            controller.toDate.value = DateTime.now();
            controller.recipientNameController.clear();
            controller.recipientNameFilter.value = "";
            controller.barcodeInputController.clear();
          }
          controller.toggleScanSection();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: controller.isScanSectionVisible.value
                ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: controller.isScanSectionVisible.value
                  ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                  : AppTheme.dividerColor,
            ),
          ),
          child: Icon(
            controller.isScanSectionVisible.value
                ? Icons.search_off
                : Icons.search,
            color: controller.isScanSectionVisible.value
                ? AppTheme.primaryBlue
                : AppTheme.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ── Collapsible search section ───────────────────────
  Widget _buildSearchSection(BuildContext context) {
    if (!controller.isScanSectionVisible.value) {
      return const SizedBox.shrink();
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      constraints: BoxConstraints(
        minHeight: 0,
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // Row 1: Barcode input + scan button
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: controller.barcodeInputController,
                    style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                    decoration: AppTheme.inputDecoration(
                      label: 'Mã sản phẩm',
                      hint: 'Nhập hoặc quét mã',
                      prefixIcon: Icons.qr_code,
                      suffix: IconButton(
                        icon: Icon(Icons.clear,
                            size: 16, color: AppTheme.textSecondary),
                        onPressed: () =>
                            controller.barcodeInputController.clear(),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) controller.refreshPortal(null);
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Obx(() => AppTheme.actionButton(
                        icon: controller.isScanning.value
                            ? Icons.hourglass_empty
                            : Icons.qr_code_scanner,
                        label: controller.isScanning.value ? "Quét..." : "Quét",
                        color: const Color(0xFF9B5DE5),
                        onPressed: () => controller.scanBarcode(),
                      )),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Row 2: Date range
            Row(children: [
              Expanded(child: _buildDatePicker(context, isFrom: true)),
              SizedBox(width: 8),
              Expanded(child: _buildDatePicker(context, isFrom: false)),
            ]),
            SizedBox(height: 10),

            // Row 3: Recipient name
            TextField(
              controller: controller.recipientNameController,
              onChanged: (v) => controller.recipientNameFilter.value = v,
              style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              decoration: AppTheme.inputDecoration(
                label: 'Tên người nhận',
                hint: 'Nhập tên người nhận',
                prefixIcon: Icons.person,
                suffix: Obx(
                  () => controller.recipientNameFilter.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              size: 16, color: AppTheme.textSecondary),
                          onPressed: () {
                            controller.recipientNameController.clear();
                            controller.recipientNameFilter.value = "";
                          },
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 24, minHeight: 24),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Row 4: Search submit
            _buildGradientSearchButton(),
          ],
        ),
      ),
    );
  }

  // ── Date picker tile ──────────────────────────────────
  Widget _buildDatePicker(BuildContext context, {required bool isFrom}) {
    return Obx(() {
      final date = isFrom ? controller.fromDate.value : controller.toDate.value;
      final color = isFrom ? AppTheme.primaryBlue : AppTheme.successGreen;
      final label = isFrom ? "Từ" : "Đến";

      return InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            if (isFrom) {
              controller.fromDate.value = picked;
              // Tự động đồng bộ toDate với fromDate
              controller.toDate.value = picked;
            } else {
              controller.toDate.value = picked;
            }
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            border: Border.all(color: AppTheme.dividerColor),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: color),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "$label: ${date.day}/${date.month}/${date.year}",
                  style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Gradient search button ────────────────────────────
  Widget _buildGradientSearchButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.refreshPortal(
              null,
              fromDate: controller.fromDate.value,
              toDate: controller.toDate.value,
              recipientName: controller.recipientNameFilter.value,
            );
            Get.snackbar(
              'Tìm kiếm',
              'Đang tìm kiếm với bộ lọc đã chọn...',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppTheme.primaryBlue,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue,
                  AppTheme.primaryBlue.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text('Tìm kiếm',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Options card ─────────────────────────────────────
  Widget _buildOptionsCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(children: [
        // Dropdown + toggles
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: DropdownButton<String>(
                  value: controller.selectedMayChu.value,
                  isExpanded: true,
                  dropdownColor: AppTheme.surfaceCard,
                  underline: const SizedBox.shrink(),
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textSecondary),
                  onChanged: (value) {
                    controller.selectedMayChu.value = value!;
                  },
                  items: controller.maychus.map((e) {
                    return DropdownMenuItem<String>(value: e, child: Text(e));
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AppTheme.toggleOption(
              'Sắp xếp',
              controller.isSortDiNgoai.value,
              () => controller.isSortDiNgoai.value =
                  !controller.isSortDiNgoai.value,
            ),
            const SizedBox(width: 8),
            AppTheme.toggleOption(
              'In',
              controller.isPrinted.value,
              () => controller.isPrinted.value = !controller.isPrinted.value,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Action row
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              AppTheme.actionButton(
                icon: Icons.download,
                label: 'Lấy DL',
                color: AppTheme.primaryBlue,
                onPressed: () => controller.layDuLieu(),
                onLongPress: () => controller.layDuLieuLo(),
              ),
              const SizedBox(width: 8),
              AppTheme.actionButton(
                icon: Icons.save,
                label: 'Xác Nhận',
                color: AppTheme.dangerRed,
                onPressed: () => _showConfirmProcessDialog(context),
                onLongPress: () => Get.toNamed(Routes.DINGOAI_CONFIG),
              ),
              const SizedBox(width: 8),
              AppTheme.actionButton(
                icon: Icons.send,
                label: 'Đi Ngoài',
                color: AppTheme.successGreen,
                onPressed: () => controller.sendDiNgoai(),
                onLongPress: () => controller.sendDiNgoaiAndRunBD(),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Table rows builder ───────────────────────────────
  List<DataRow> _buildTableRows(PortalinfoController dx, BuildContext context) {
    return List<DataRow>.generate(
      dx.portals.length,
      (index) {
        final p = dx.portals[index];
        return DataRow(
          selected: p.selected,
          onLongPress: () {
            controller.isShowEdit.value = false;
            controller.getMaHieuToShow(index);
            showImprovedDialog(context, index);
          },
          onSelectChanged: (value) {
            dx.iPotal.value = index;
            if (p.selected != value) p.selected = value!;
            dx.countPortalSelected.value =
                dx.portals.where((e) => e.selected).length;
            dx.update();
          },
          color: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.primaryBlue.withValues(alpha: 0.2);
            }
            return null;
          }),
          cells: [
            DataCell(Text('$index',
                style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold))),
            DataCell(Text(
              p.name!,
              style: TextStyle(
                  fontSize: 12,
                  color: !p.isXuLyDiNgoai
                      ? AppTheme.accentCyan
                      : AppTheme.warningOrange,
                  fontStyle: FontStyle.italic),
            )),
            DataCell(Text(
              p.soLuong?.toString() ?? "",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
            )),
            DataCell(_buildStatusText(p.trangThai)),
          ],
        );
      },
    );
  }

  Widget _buildStatusText(String? trangThai) {
    if (trangThai == null) return const Text("");
    if (trangThai == "2") {
      return const Text("Đang xử lý",
          style: TextStyle(fontSize: 12, color: AppTheme.successGreen));
    }
    if (trangThai == "3") {
      return const Text("Chấp Nhận",
          style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue));
    }
    return const Text("");
  }

  // ── Detail Dialog ──────────────────────────────────
  void showImprovedDialog(BuildContext context, int index) {
    final String? currentPortalStatus = controller.portals[index].trangThai;
    final bool showDeleteButton = currentPortalStatus == "2";

    controller.similarIdCodes.clear();

    // Initialize search state and controllers
    final textController = TextEditingController();
    controller.dialogSearchTextController = textController;
    controller.dialogSearchText.value = "";
    controller.dialogSearchMatches.clear();
    controller.dialogCurrentMatchIndex.value = -1;

    final scrollController = ScrollController();
    controller.dialogScrollController = scrollController;

    controller.dialogItemKeys.clear();

    Get.dialog(
      barrierDismissible: true,
      Dialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: PopScope(
          onPopInvokedWithResult: (didPop, result) {
            controller.cancelBulkQRScanInDialog();
          },
          child: GetBuilder<PortalinfoController>(
            builder: (dx) => ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
                maxWidth: 400,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            color: AppTheme.accentCyan, size: 18),
                        SizedBox(width: 6),
                        Text('Người Nhập: ',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                        Expanded(
                          child: Text(
                            dx.portals[index].nguoiNhap ?? 'N/A',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    // Title & Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "Danh sách (${dx.currentMaHieusInPortal.length})",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showDeleteButton || currentPortalStatus == "3")
                          Row(
                            children: [
                              _buildDialogIconButton(
                                icon: Icons.person_search,
                                color: AppTheme.warningOrange,
                                tooltip: 'Tìm tên giống nhau > 90%',
                                onPressed: () => controller.findSimilarNames(),
                              ),
                              if (showDeleteButton)
                                _buildDialogIconButton(
                                  icon: Icons.qr_code_scanner,
                                  color: const Color(0xFF9B5DE5),
                                  tooltip: 'Quét hàng loạt',
                                  onPressed: () =>
                                      controller.startBulkQRScanInDialog(),
                                ),
                              _buildDialogIconButton(
                                icon: Icons.analytics,
                                color: const Color(0xFF9B5DE5),
                                tooltip: 'Thống kê portal này',
                                onPressed: () =>
                                    controller.showStatisticsForCurrentPortal(),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Toolbar: detail toggle + sort
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Text("Chi tiết:",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary)),
                                Transform.scale(
                                  scale: 0.8,
                                  child: Obx(() => Switch(
                                        value: controller.isDetailedView.value,
                                        activeThumbColor: AppTheme.primaryBlue,
                                        inactiveThumbColor:
                                            AppTheme.textSecondary,
                                        inactiveTrackColor:
                                            AppTheme.surfaceDark,
                                        onChanged: (val) =>
                                            controller.toggleViewMode(val),
                                      )),
                                ),
                                SizedBox(width: 4),
                                Text("Hướng:",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary)),
                                Transform.scale(
                                  scale: 0.8,
                                  child: Obx(() => Switch(
                                        value: controller.showDirection.value,
                                        activeThumbColor: AppTheme.primaryBlue,
                                        inactiveThumbColor:
                                            AppTheme.textSecondary,
                                        inactiveTrackColor:
                                            AppTheme.surfaceDark,
                                        onChanged: (val) =>
                                            controller.toggleDirectionView(val),
                                      )),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildSortButton(
                            "KL", "Trọng lượng", const Color(0xFF9B5DE5)),
                        const SizedBox(width: 4),
                        _buildSortButton("\$", "COD", AppTheme.successGreen),
                      ],
                    ),

                    // Selected counter
                    Obx(() {
                      if (dx.selectedDialogItemCount.value == 0) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF9B5DE5).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF9B5DE5)
                                  .withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          'Đã chọn: ${dx.selectedDialogItemCount.value} bưu gửi',
                          style: const TextStyle(
                              color: Color(0xFF9B5DE5),
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    }),

                    // Search bar
                    Obx(() {
                      final hasMatches = dx.dialogSearchMatches.isNotEmpty;
                      final matchCount = dx.dialogSearchMatches.length;
                      final currentMatch = dx.dialogCurrentMatchIndex.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: textController,
                                onChanged: (val) => dx.searchInDialog(val),
                                style: TextStyle(
                                    color: AppTheme.textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Tìm kiếm tên...',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textSecondary
                                        .withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Icon(Icons.search,
                                      color: AppTheme.textSecondary, size: 18),
                                  suffixIcon: textController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear,
                                              color: AppTheme.textSecondary,
                                              size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            textController.clear();
                                            dx.searchInDialog("");
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: AppTheme.surfaceDark,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            if (textController.text.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                hasMatches
                                    ? '${currentMatch + 1}/$matchCount'
                                    : '0/0',
                                style: TextStyle(
                                  color: hasMatches
                                      ? AppTheme.accentCyan
                                      : AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_up,
                                    size: 20),
                                color: hasMatches
                                    ? AppTheme.accentCyan
                                    : AppTheme.textSecondary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: hasMatches
                                    ? () => dx.previousMatch()
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    size: 20),
                                color: hasMatches
                                    ? AppTheme.accentCyan
                                    : AppTheme.textSecondary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed:
                                    hasMatches ? () => dx.nextMatch() : null,
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                    Divider(
                        color: AppTheme.dividerColor.withValues(alpha: 0.5)),

                    // List
                    Expanded(
                      child: !dx.isShowEdit.value
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.primaryBlue))
                          : dx.currentMaHieusInPortal.isEmpty
                              ? AppTheme.emptyState(
                                  title: 'Không có dữ liệu mã hiệu')
                              : ListView.separated(
                                  controller: controller.dialogScrollController,
                                  cacheExtent: 5000,
                                  shrinkWrap: true,
                                  itemCount: dx.currentMaHieusInPortal.length,
                                  separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: AppTheme.dividerColor
                                          .withValues(alpha: 0.3)),
                                  itemBuilder: (context, i) {
                                    while (
                                        controller.dialogItemKeys.length <= i) {
                                      controller.dialogItemKeys
                                          .add(GlobalKey());
                                    }
                                    final item = dx.currentMaHieusInPortal[i];
                                    final isSimilar = controller.similarIdCodes
                                        .contains(item.IDCODE);
                                        final double itemHeight =
                                        controller.isDetailedView.value
                                            ? 130.0
                                            : 55.0;
                                    return Container(
                                      height: itemHeight,
                                      key: controller.dialogItemKeys[i],
                                      child: _buildDialogListTile(
                                        item: item,
                                        isSimilar: isSimilar,
                                        showDeleteButton: showDeleteButton,
                                        index: index,
                                        itemIndex: i,
                                        context: context,
                                      ),
                                    );
                                  },
                                ),
                    ),

                    // Delete all selected
                    if (showDeleteButton && dx.isAnyItemSelectedInDialog)
                      _buildDeleteAllSelectedButton(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).then((value) {
      controller.dialogSearchTextController?.dispose();
      controller.dialogSearchTextController = null;
      controller.dialogScrollController?.dispose();
      controller.dialogScrollController = null;
    });
  }

  // ── Dialog list tile ──────────────────────────────────
  Widget _buildDialogListTile({
    required StateMaHieu item,
    required bool isSimilar,
    required bool showDeleteButton,
    required int index,
    required int itemIndex,
    required BuildContext context,
  }) {
    return Obx(() {
      final isMatch = controller.dialogSearchMatches.contains(itemIndex);
      final isCurrentSearchMatch =
          controller.dialogCurrentMatchIndex.value != -1 &&
              controller.dialogSearchMatches.isNotEmpty &&
              controller.dialogSearchMatches[
                      controller.dialogCurrentMatchIndex.value] ==
                  itemIndex;

      Color? tileColor;
      if (isCurrentSearchMatch) {
        tileColor = AppTheme.accentCyan.withValues(alpha: 0.35);
      } else if (isMatch) {
        tileColor = AppTheme.accentCyan.withValues(alpha: 0.12);
      } else if (item.selected) {
        tileColor = AppTheme.primaryBlue.withValues(alpha: 0.15);
      } else if (isSimilar) {
        tileColor = AppTheme.warningOrange.withValues(alpha: 0.15);
      }

      return ListTile(
        dense: true,
        tileColor: tileColor,
        onTap: showDeleteButton
            ? () => controller.toggleItemSelectedInDialog(item)
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        title: Row(
          children: [
            if (isSimilar)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.warning_amber_rounded,
                    size: 16, color: AppTheme.warningOrange),
              ),
            Builder(
              builder: (context) {
                final direction = controller.getPackageDirection(item);
                if (direction == null) return const SizedBox.shrink();

                Color directionBgColor = Colors.blue;
                Color directionColor = Colors.blue.shade700;
                String displayDirection = direction;

                if (direction == 'RA') {
                  directionBgColor = Colors.red;
                  directionColor = Colors.red.shade700;
                } else if (direction == 'VÔ') {
                  directionBgColor = Colors.green;
                  directionColor = Colors.green.shade700;
                } else if (direction == 'Quảng Nam') {
                  directionBgColor = Colors.orange;
                  directionColor = Colors.orange.shade700;
                  displayDirection = 'Q.Nam';
                } else if (direction == 'Quảng Ngãi') {
                  directionBgColor = Colors.purple;
                  directionColor = Colors.purple.shade700;
                  displayDirection = 'Q.Ngãi';
                }

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: directionBgColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: directionColor, width: 1),
                  ),
                  child: Text(
                    displayDirection,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: directionColor,
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Text(
                item.code ?? 'N/A',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: controller.isDetailedView.value
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  SizedBox(
                    // Chiều cao ước tính cho 2 dòng: fontSize (13) * line-height (1.3) * 2 dòng ≈ 34.
                    // Bạn có thể điều chỉnh con số này để phù hợp với font chữ thực tế.
                    height: 34,
                    child: Text(
                      item.Name ?? "Không có tên",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height:
                            1.3, // Thuộc tính này giúp kiểm soát khoảng cách dòng tốt hơn
                      ),
                    ),
                  ),
                  Text(_getLastWords(item.Address, 50),
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text(item.Date ?? '',
                      style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textSecondary)),
                ],
              )
            : Text(item.Date ?? 'N/A',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.Weight ?? '0',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary)),
                Text(item.Money ?? '0',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            if (showDeleteButton) ...[
              const SizedBox(width: 4),
              _buildIconDialogButton(
                icon: Icons.scale,
                color: AppTheme.primaryBlue,
                tooltip: 'Sửa KL',
                onPressed: () => _showChangeWeightDialog(context, item, index),
              ),
              _buildIconDialogButton(
                icon: Icons.delete,
                color: AppTheme.dangerRed,
                tooltip: 'Xóa',
                onPressed: () => _showConfirmDeleteDialog(context, item, index),
              ),
            ]
          ],
        ),
      );
    });
  }

  // ── Delete all selected button ─────────────────────
  Widget _buildDeleteAllSelectedButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showConfirmDeleteAllDialog(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.dangerRed,
                    AppTheme.dangerRed.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_sweep, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Xóa các mục đã chọn',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Dialog helper widgets ──────────────────────────
  Widget _buildDialogIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton(String label, String sortType, Color color) {
    return Obx(() => InkWell(
          onTap: () => controller.sortDialogList(sortType),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: controller.dialogSortOption.value == sortType
                  ? color
                  : AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: controller.dialogSortOption.value == sortType
                    ? color
                    : AppTheme.dividerColor,
              ),
            ),
            child: Row(
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: controller.dialogSortOption.value == sortType
                            ? Colors.white
                            : AppTheme.textSecondary)),
                if (controller.dialogSortOption.value == sortType)
                  Icon(
                    controller.dialogSortAscending.value
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 12,
                    color: Colors.white,
                  )
              ],
            ),
          ),
        ));
  }

  Widget _buildIconDialogButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 28, maxHeight: 28),
      child: IconButton(
        icon: Icon(icon, color: color),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 18,
        onPressed: onPressed,
      ),
    );
  }

  // ── Confirm Dialogs ────────────────────────────────
  void _showConfirmDeleteDialog(
      BuildContext context, StateMaHieu item, int portalIndex) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            Text("Xác nhận xóa", style: TextStyle(color: AppTheme.textPrimary)),
        content: Text("Bạn có chắc chắn muốn xóa bưu gửi ${item.code ?? ''}?",
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Hủy", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteBG(item);
            },
            child:
                const Text("Xóa", style: TextStyle(color: AppTheme.dangerRed)),
          ),
        ],
      ),
    );
  }

  void _showConfirmDeleteAllDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            Text("Xác nhận xóa", style: TextStyle(color: AppTheme.textPrimary)),
        content: Text("Bạn có chắc chắn muốn xóa các bưu gửi đã chọn không?",
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Hủy", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteSelectedBGs();
            },
            child: const Text("Xóa đã chọn",
                style: TextStyle(color: AppTheme.dangerRed)),
          ),
        ],
      ),
    );
  }

  void _showChangeWeightDialog(
      BuildContext context, StateMaHieu item, int index) {
    final weightCtrl = TextEditingController(text: item.Weight ?? '');

    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Thay đổi trọng lượng",
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: weightCtrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: AppTheme.inputDecoration(label: "Trọng lượng mới"),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Hủy", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.updateWeight(item, weightCtrl.text);
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

  void _showConfirmProcessDialog(BuildContext context) {
    final selectedPortals = controller.getSelectedsPortal();

    if (selectedPortals.isEmpty) {
      Get.snackbar(
        'Cảnh báo',
        'Vui lòng chọn ít nhất một khách hàng để xác nhận xử lý',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.warningOrange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final selectedNames =
        selectedPortals.map((portal) => portal.name ?? 'N/A').toList();
    final count = selectedPortals.length;

    String contentMessage = count == 1
        ? "Bạn có muốn xác nhận xử lý khách hàng này không?\n\n"
        : "Bạn có muốn xác nhận xử lý $count khách hàng này không?\n\n";

    contentMessage += count == 1 ? "Khách hàng:\n" : "Danh sách khách hàng:\n";

    final displayCount = selectedNames.length > 10 ? 10 : selectedNames.length;
    for (int i = 0; i < displayCount; i++) {
      contentMessage += "${i + 1}. ${selectedNames[i]}\n";
    }

    if (selectedNames.length > 10) {
      contentMessage += "... và ${selectedNames.length - 10} khách hàng khác";
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Xác nhận xử lý",
            style: TextStyle(color: AppTheme.textPrimary)),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: 400,
          ),
          child: SingleChildScrollView(
            child: Text(
              contentMessage.trim(),
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Hủy", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.xacNhansPortal();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }
}
