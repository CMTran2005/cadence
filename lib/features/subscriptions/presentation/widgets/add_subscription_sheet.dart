import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/constants/subscription_presets.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../models/subscription_item.dart';

class AddSubscriptionSheet extends StatefulWidget {
  final SubscriptionItem? existingSub;

  const AddSubscriptionSheet({super.key, this.existingSub});

  static Future<bool?> show(BuildContext context, {SubscriptionItem? existingSub}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddSubscriptionSheet(existingSub: existingSub),
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
  void initState() {
    super.initState();
    if (widget.existingSub != null) {
      final sub = widget.existingSub!;
      _nameController.text = sub.name;
      _amountController.text = sub.amount.toInt().toString();
      _category = sub.category;
      _billingCycle = sub.billingCycle;
      _nextBillingDate = sub.nextBillingDate;
    }
  }

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
        SnackBar(content: Text(tr('service_name_hint'))),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('validation_amount'))),
      );
      return;
    }

    if (widget.existingSub != null) {
      final updated = widget.existingSub!.copyWith(
        name: name,
        amount: amount,
        billingCycle: _billingCycle,
        nextBillingDate: _nextBillingDate,
        category: _category,
        reminderDaysBefore: _reminderDays,
      );
      await DatabaseHelper.instance.updateSubscription(updated);
    } else {
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
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentTheme = SettingsService.instance.themeBackground;
    final isEditing = widget.existingSub != null;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: bottomInset + 24,
      ),
      decoration: BoxDecoration(
        color: currentTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: currentTheme.border, width: 1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: currentTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Text(
              isEditing ? tr('edit_subscription') : tr('add_subscription'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // Presets row (only when adding new)
            if (!isEditing) ...[
              Text(
                tr('services_list', {'count': '${SubscriptionPresets.popular.length}'}),
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: SubscriptionPresets.popular.map((preset) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Icon(preset.icon, size: 16, color: preset.brandColor),
                        label: Text(preset.name),
                        backgroundColor: currentTheme.surfaceElevated,
                        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        side: BorderSide(color: currentTheme.border),
                        onPressed: () => _applyPreset(preset),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Service Name
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: tr('service_name'),
                hintText: tr('service_name_hint'),
                prefixIcon: const Icon(Icons.bookmark_outline_rounded, color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 14),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: tr('amount'),
                prefixText: '${SettingsService.instance.currency.symbol} ',
                prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 14),

            // Billing Cycle Segment
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text(tr('monthly'))),
                    selected: _billingCycle == 'MONTHLY',
                    onSelected: (val) {
                      if (val) setState(() => _billingCycle = 'MONTHLY');
                    },
                    selectedColor: AppColors.income,
                    backgroundColor: currentTheme.surfaceElevated,
                    labelStyle: TextStyle(
                      color: _billingCycle == 'MONTHLY' ? Colors.black : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(color: currentTheme.border),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text(tr('yearly'))),
                    selected: _billingCycle == 'YEARLY',
                    onSelected: (val) {
                      if (val) setState(() => _billingCycle = 'YEARLY');
                    },
                    selectedColor: AppColors.income,
                    backgroundColor: currentTheme.surfaceElevated,
                    labelStyle: TextStyle(
                      color: _billingCycle == 'YEARLY' ? Colors.black : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(color: currentTheme.border),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Next Billing Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _nextBillingDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.income,
                          onPrimary: Colors.black,
                          surface: AppColors.surface,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _nextBillingDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: currentTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: currentTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_outlined, size: 18, color: AppColors.textTertiary),
                        const SizedBox(width: 10),
                        Text(tr('next_billing_date'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                    Text(
                      DateFormatter.formatDate(_nextBillingDate),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isEditing ? tr('update_subscription') : tr('save_subscription'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
