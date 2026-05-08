import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';
import '../controllers/nhaphang_controller.dart';

class NhapHangView extends GetView<NhapHangController> {
  const NhapHangView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppTheme.buildAppBar(
        title: 'Nhập Hàng',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  controller.customer.tenKH,
                  style: const TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: controller.formKey,
        child: Column(
          children: [
            // ── Customer info banner ────────────────────
            _CustomerBanner(controller: controller),

            // ── Scrollable form ─────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: controller.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(
                        icon: Icons.person_outline,
                        label: 'THÔNG TIN NGƯỜI NHẬN'),
                    const SizedBox(height: 8),

                    // Họ và tên
                    _FormField(
                      controller: controller.tenNguoiNhanCtrl,
                      label: 'Họ và tên người nhận',
                      hint: 'Nguyễn Văn A',
                      prefixIcon: Icons.badge_outlined,
                      keyboardType: TextInputType.name,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập họ tên'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Số điện thoại
                    _FormField(
                      controller: controller.soDienThoaiCtrl,
                      label: 'Số điện thoại',
                      hint: '0912345678',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Vui lòng nhập SĐT';
                        if (v.trim().length < 9) return 'SĐT không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Địa chỉ
                    TextFormField(
                      key: controller.addressGlobalKey,
                      focusNode: controller.addressFocusNode,
                      controller: controller.diaChiCtrl,
                      keyboardType: TextInputType.streetAddress,
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (value) {
                        controller.addressSuggestions.clear();
                        controller.lookupAddress(value);
                      },
                      onChanged: controller.onAddressChanged,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập địa chỉ'
                          : null,
                      style:
                          TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                      decoration: AppTheme.inputDecoration(
                        label: 'Địa chỉ',
                        hint:
                            'Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành',
                        prefixIcon: Icons.location_on_outlined,
                        suffix: IconButton(
                          icon: const Icon(Icons.search_rounded,
                              color: AppTheme.accentCyan, size: 22),
                          onPressed: () {
                            controller.addressSuggestions.clear();
                            controller
                                .lookupAddress(controller.diaChiCtrl.text);
                          },
                        ),
                      ),
                    ),

                    // ── Address suggestion list ─────────
                    Obx(() {
                      final suggestions = controller.addressSuggestions;
                      if (suggestions.isEmpty) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: suggestions.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, indent: 12, endIndent: 12),
                          itemBuilder: (context, i) {
                            final s = suggestions[i];
                            return InkWell(
                              onTap: () =>
                                  controller.selectAddressSuggestion(s),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_city,
                                        size: 16,
                                        color: AppTheme.accentCyan
                                            .withValues(alpha: 0.7)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.wardName,
                                            style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${s.districtName}, ${s.provinceName}',
                                            style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 8),

                    // Phường/Xã, Quận/Huyện, Tỉnh/TP
                    Obx(() => Row(
                          children: [
                            Expanded(
                              child: _ReadonlyField(
                                  label: 'Phường/Xã',
                                  value: controller.xa.value),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ReadonlyField(
                                  label: 'Quận/Huyện',
                                  value: controller.huyen.value),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ReadonlyField(
                                  label: 'Tỉnh/TP',
                                  value: controller.tinh.value),
                            ),
                          ],
                        )),
                    const SizedBox(height: 20),

                    const _SectionLabel(
                        icon: Icons.local_shipping_outlined,
                        label: 'THÔNG TIN GÓI HÀNG'),
                    const SizedBox(height: 8),

                    // Dịch vụ
                    _DichVuDropdown(controller: controller),
                    const SizedBox(height: 12),

                    // Khối lượng
                    _FormField(
                      controller: controller.khoiLuongCtrl,
                      label: 'Khối lượng (gram)',
                      hint: '500',
                      prefixIcon: Icons.scale_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Nhập khối lượng';
                        final d = double.tryParse(v);
                        if (d == null || d <= 0)
                          return 'Khối lượng không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // COD
                    _FormField(
                      controller: controller.codCtrl,
                      label: 'COD (VNĐ)',
                      hint: '0',
                      prefixIcon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [_ThousandsFormatter()],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Nhập số tiền COD';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Nội dung BG
                    _FormField(
                      controller: controller.noiDungCtrl,
                      label: 'Nội dung bưu gửi',
                      hint: 'Quần áo, đồ điện tử...',
                      prefixIcon: Icons.inventory_2_outlined,
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nhập nội dung bưu gửi'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // ── Nút Tạo Đơn ─────────────────────
                    Obx(() {
                      final isLoading = controller.isSubmitting.value;
                      return _SubmitButton(
                        isLoading: isLoading,
                        onPressed: isLoading ? null : controller.submitDon,
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Customer info banner
// ─────────────────────────────────────────────────────────
class _CustomerBanner extends StatelessWidget {
  final NhapHangController controller;
  const _CustomerBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentCyan.withValues(alpha: 0.15),
            AppTheme.primaryBlue.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.accentCyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store_mall_directory_outlined,
                color: AppTheme.accentCyan, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.customer.tenKH,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mã KH: ${controller.customer.maKH}${controller.customer.isChooseHopDong ? "  •  HĐ: ${controller.customer.sttHopDong}" : ""}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                Obx(() {
                  final hdr = controller.hdrIdText.value;
                  if (hdr.isEmpty) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.tag,
                            size: 12, color: AppTheme.accentCyan),
                        const SizedBox(width: 4),
                        Text(
                          'HDR: $hdr',
                          style: const TextStyle(
                            color: AppTheme.accentCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: controller.customer.isChooseHopDong
                  ? AppTheme.successGreen.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              controller.customer.isChooseHopDong ? 'Có HĐ' : 'Không HĐ',
              style: TextStyle(
                color: controller.customer.isChooseHopDong
                    ? AppTheme.successGreen
                    : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentCyan, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.accentCyan,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Reusable form field
// ─────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  const _FormField({
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
      maxLines: maxLines,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: AppTheme.inputDecoration(
        label: label,
        hint: hint,
        prefixIcon: prefixIcon,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Dịch vụ Dropdown
// ─────────────────────────────────────────────────────────
class _DichVuDropdown extends StatelessWidget {
  final NhapHangController controller;
  const _DichVuDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: controller.selectedDichVu.value,
      dropdownColor: AppTheme.surfaceCard,
      style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: AppTheme.textSecondary),
      decoration: AppTheme.inputDecoration(
        label: 'Dịch Vụ',
        prefixIcon: Icons.local_post_office_outlined,
      ),
      items: controller.dichVuOptions
          .map((dv) => DropdownMenuItem(
                value: dv,
                child: Text(dv),
              ))
          .toList(),
      onChanged: (v) => controller.selectedDichVu.value = v,
      validator: (v) => v == null ? 'Vui lòng chọn dịch vụ' : null,
    );
  }
}

// ─────────────────────────────────────────────────────────
// Submit button
// ─────────────────────────────────────────────────────────
class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _SubmitButton({required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading
              ? AppTheme.accentCyan.withValues(alpha: 0.5)
              : AppTheme.accentCyan,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.accentCyan.withValues(alpha: 0.4),
          elevation: isLoading ? 0 : 4,
          shadowColor: AppTheme.accentCyan.withValues(alpha: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Đang xử lý...',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: 10),
                  Text('Tạo Đơn',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Readonly small field for address components
// ─────────────────────────────────────────────────────────
class _ThousandsFormatter extends TextInputFormatter {
  const _ThousandsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final clean = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final textBeforeCursor =
        newValue.text.substring(0, newValue.selection.baseOffset);
    final digitsBeforeCursor =
        textBeforeCursor.replaceAll(RegExp(r'[^\d]'), '').length;

    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && (clean.length - i) % 3 == 0) buffer.write('.');
      buffer.write(clean[i]);
    }
    final formatted = buffer.toString();

    int cursorPos = 0;
    int digitsSeen = 0;
    while (cursorPos < formatted.length && digitsSeen < digitsBeforeCursor) {
      if (formatted[cursorPos] != '.') digitsSeen++;
      cursorPos++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPos),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadonlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '...' : value,
            style: TextStyle(
              color: value.isEmpty
                  ? AppTheme.textSecondary.withValues(alpha: 0.4)
                  : AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
