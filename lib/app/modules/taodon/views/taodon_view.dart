import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/theme/app_theme.dart';
import '../controllers/taodon_controller.dart';
import '../models/customer_model.dart';

class _RainbowSpinner extends StatefulWidget {
  final double size;
  const _RainbowSpinner({this.size = 24});

  @override
  State<_RainbowSpinner> createState() => _RainbowSpinnerState();
}

class _RainbowSpinnerState extends State<_RainbowSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Color(0xFFFF0000),
              Color(0xFFFF7F00),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF0000FF),
              Color(0xFF4B0082),
              Color(0xFF8B00FF),
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: widget.size * 0.7,
            height: widget.size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceCard,
            ),
          ),
        ),
      ),
    );
  }
}

class TaodonView extends GetView<TaodonController> {
  const TaodonView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.sendCheckTaodon();
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppTheme.buildAppBar(title: 'Tạo Đơn'),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentCyan),
          );
        }

        if (controller.customers.isEmpty) {
          return Center(
            child: Text(
              'Không có dữ liệu khách hàng',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Chọn khách hàng để tạo đơn',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // ComboBox for customer selection - using maKH as value
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: DropdownButton<String>(
                  value: controller.selectedMaKH.value,
                  isExpanded: true,
                  dropdownColor: AppTheme.surfaceCard,
                  hint: Text(
                    'Chọn khách hàng...',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                  underline: const SizedBox(),
                  items: controller.customers.map((customer) {
                    return DropdownMenuItem<String>(
                      value: customer.maKH,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${customer.tenKH} - ${customer.maKH}',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (customer.isChooseHopDong)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'HĐ: ${customer.sttHopDong}',
                                style: const TextStyle(
                                    color: AppTheme.successGreen, fontSize: 11),
                              ),
                            )
                          else
                            Text(
                              'Không HĐ',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    controller.selectedMaKH.value = value;
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Display selected customer info
              Obx(() {
                final selectedMaKH = controller.selectedMaKH.value;
                if (selectedMaKH == null) {
                  return const SizedBox();
                }
                
                // Find customer by maKH
                Customer? customer;
                try {
                  customer = controller.customers.firstWhere(
                    (c) => c.maKH == selectedMaKH,
                  );
                } catch (e) {
                  customer = null;
                }
                
                if (customer == null) {
                  return const SizedBox();
                }
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.accentCyan.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: AppTheme.accentCyan, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              customer.tenKH,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mã KH: ${customer.maKH}',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      if (customer.address.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on,
                                color: AppTheme.textSecondary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                customer.address,
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (customer.isChooseHopDong)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.successGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Đang có hợp đồng (${customer.sttHopDong})',
                                style: const TextStyle(
                                    color: AppTheme.successGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Không có hợp đồng',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Check portal button
              Obx(() {
                final checking = controller.isChecking.value;
                final canEnter = controller.canGoToNhapHang;
                final hdrId = controller.checkHdrId.value;

                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: canEnter ? controller.goToNhapHang : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canEnter
                          ? AppTheme.accentCyan
                          : Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: checking
                          ? AppTheme.surfaceCard
                          : Colors.grey.shade700,
                      disabledForegroundColor: Colors.white54,
                      elevation: canEnter ? 4 : 0,
                      shadowColor:
                          AppTheme.accentCyan.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: checking
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _RainbowSpinner(size: 22),
                              const SizedBox(width: 10),
                              const Text(
                                'Đang kiểm tra...',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                canEnter
                                    ? Icons.check_circle_rounded
                                    : Icons.hourglass_empty_rounded,
                                size: 20,
                                color: canEnter
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                canEnter
                                    ? 'Vào nhập hàng (HDR: $hdrId)'
                                    : 'Chưa có dữ liệu',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Create order button
              Obx(() {
                final isSelected = controller.selectedMaKH.value != null;
                final isLoading = controller.isButtonLoading.value;
                final isEnabled = isSelected && !isLoading;

                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isEnabled
                        ? () {
                            final maKH = controller.selectedMaKH.value!;
                            Customer? customer;
                            try {
                              customer = controller.customers.firstWhere(
                                (c) => c.maKH == maKH,
                              );
                            } catch (e) {
                              customer = null;
                            }
                            if (customer != null) {
                              controller.selectCustomer(customer);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnabled
                          ? AppTheme.accentCyan
                          : isLoading
                              ? AppTheme.accentCyan.withValues(alpha: 0.6)
                              : Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isLoading
                          ? AppTheme.accentCyan.withValues(alpha: 0.6)
                          : Colors.grey.shade700,
                      disabledForegroundColor: Colors.white70,
                      elevation: isEnabled ? 4 : 0,
                      shadowColor: AppTheme.accentCyan.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? Row(
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
                              Obx(() => Text(
                                    controller.stateText.value.isNotEmpty
                                        ? controller.stateText.value
                                        : 'Đang xử lý...',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  )),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.post_add_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isSelected
                                    ? 'Tạo đơn cho ${controller.selectedMaKH.value}'
                                    : 'Chọn khách hàng trước',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Optional: Show full customer list for reference
              ExpansionTile(
                title: Text(
                  'Xem danh sách (${controller.customers.length} khách hàng)',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                collapsedIconColor: AppTheme.textSecondary,
                iconColor: AppTheme.textSecondary,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.customers.length,
                      itemBuilder: (context, index) {
                        final customer = controller.customers[index];
                        final isSelected =
                            controller.selectedMaKH.value == customer.maKH;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppTheme.accentCyan
                                : AppTheme.surfaceCard,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            customer.tenKH,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.accentCyan
                                  : AppTheme.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            customer.maKH,
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: AppTheme.accentCyan)
                              : null,
                          onTap: () {
                            controller.selectedMaKH.value = customer.maKH;
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
