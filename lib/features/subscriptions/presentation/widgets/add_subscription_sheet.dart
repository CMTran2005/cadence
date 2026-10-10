import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/constants/subscription_presets.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../models/subscription_item.dart';

class AddSubscriptionSheet extends StatefulWidget {
  const AddSubscriptionSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddSubscriptionSheet(),
    );
  }

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  CategoryType _category = CategoryType.subscriptions;
  String _billingCycle = 'MONTHLY'; // 'MONTHLY', 'YEARLY'
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 7));
  final int _reminderDays = 2;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _applyPreset(SubscriptionPreset preset) {
    setState(() {
      _nameController.text = preset.name;
      _amountController.text = preset.defaultAmount.toInt().toString();
      _category = CategoryType.fromString(preset.category);
      _billingCycle = preset.billingCycle;
    });
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên gói dịch vụ')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    final sub = SubscriptionItem(
      name: name,
      amount: amount,
      billingCycle: _billingCycle,
      nextBillingDate: _nextBillingDate,
      category: _category,
      reminderDaysBefore: _reminderDays,
      isActive: true,
    );

    await DatabaseHelper.instance.insertSubscription(sub);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: bottomInset + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Thêm gói dịch vụ định kỳ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // Presets quick scroll
            const Text(
              'Gợi ý phổ biến (chạm để chọn nhanh):',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: SubscriptionPresets.popular.map((preset) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(preset.icon, size: 14, color: preset.brandColor),
                      label: Text(preset.name),
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onPressed: () => _applyPreset(preset),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Name
            const Text('Tên dịch vụ / Khoản chi', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Ví dụ: Netflix, Tiền trọ, Gym...',
                prefixIcon: Icon(Icons.repeat_rounded, size: 20, color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            const Text('Số tiền mỗi kỳ (VND)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              decoration: const InputDecoration(
                prefixText: '₫ ',
                prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                hintText: '0',
              ),
            ),
            const SizedBox(height: 16),

            // Billing Cycle & Next Date row
            Row(
              children: [
                // Billing Cycle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chu kỳ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _billingCycle,
                        dropdownColor: AppColors.surfaceElevated,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                        items: const [
                          DropdownMenuItem(value: 'MONTHLY', child: Text('Hàng tháng')),
                          DropdownMenuItem(value: 'YEARLY', child: Text('Hàng năm')),
                        ],
                        onChanged: (val) => setState(() => _billingCycle = val ?? 'MONTHLY'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Next Billing Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kỳ tới', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _nextBillingDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _nextBillingDate = picked);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            DateFormatter.formatDate(_nextBillingDate),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Lưu Gói Dịch Vụ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
