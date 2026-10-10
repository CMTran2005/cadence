import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../models/transaction_item.dart';

class QuickManualEntrySheet extends StatefulWidget {
  final TransactionType initialType;

  const QuickManualEntrySheet({super.key, this.initialType = TransactionType.expense});

  static Future<bool?> show(BuildContext context, {TransactionType initialType = TransactionType.expense}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickManualEntrySheet(initialType: initialType),
    );
  }

  @override
  State<QuickManualEntrySheet> createState() => _QuickManualEntrySheetState();
}

class _QuickManualEntrySheetState extends State<QuickManualEntrySheet> {
  late TransactionType _type;
  late CategoryType _category;
  late DateTime _date;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _category = _type == TransactionType.expense ? CategoryType.food : CategoryType.salary;
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? (_type == TransactionType.expense ? _category.displayName : 'Khoản thu')
        : _titleController.text.trim();

    final tx = TransactionItem(
      title: title,
      amount: amount,
      type: _type,
      category: _category,
      transactionDate: _date,
      source: 'MANUAL',
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await DatabaseHelper.instance.insertTransaction(tx);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isExpense = _type == TransactionType.expense;

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

            // Segmented Type Switcher
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _type = TransactionType.expense;
                          _category = CategoryType.food;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isExpense ? AppColors.expenseSubtle : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isExpense ? Border.all(color: AppColors.expense.withOpacity(0.4)) : null,
                        ),
                        child: Center(
                          child: Text(
                            'Chi tiêu',
                            style: TextStyle(
                              color: isExpense ? AppColors.expense : AppColors.textSecondary,
                              fontWeight: isExpense ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _type = TransactionType.income;
                          _category = CategoryType.salary;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isExpense ? AppColors.incomeSubtle : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: !isExpense ? Border.all(color: AppColors.income.withOpacity(0.4)) : null,
                        ),
                        child: Center(
                          child: Text(
                            'Thu nhập',
                            style: TextStyle(
                              color: !isExpense ? AppColors.income : AppColors.textSecondary,
                              fontWeight: !isExpense ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Amount Input
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: isExpense ? AppColors.expense : AppColors.income,
                letterSpacing: -1.0,
              ),
              decoration: InputDecoration(
                prefixText: '₫ ',
                prefixStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: isExpense ? AppColors.expense : AppColors.income,
                ),
                hintText: '0',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Title / Description
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: isExpense ? 'Nơi bán / Khoản chi (Highlands, Ăn trưa...)' : 'Nguồn thu (Lương, Thưởng...)',
                prefixIcon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 16),

            // Category Chips
            Text(
              'Danh mục',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (isExpense
                      ? [
                          CategoryType.food,
                          CategoryType.shopping,
                          CategoryType.transport,
                          CategoryType.bills,
                          CategoryType.entertainment,
                          CategoryType.health,
                          CategoryType.education,
                          CategoryType.other,
                        ]
                      : [
                          CategoryType.salary,
                          CategoryType.freelance,
                          CategoryType.investment,
                          CategoryType.gift,
                          CategoryType.other,
                        ])
                  .map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 14, color: isSelected ? Colors.white : cat.color),
                      const SizedBox(width: 6),
                      Text(cat.displayName),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: cat.color,
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isSelected ? cat.color : AppColors.border),
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _category = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Date Picker Row
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _date = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textTertiary),
                    const SizedBox(width: 12),
                    Text(
                      'Ngày: ${DateFormatter.formatDate(_date)}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                  ],
                ),
              ),
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
                child: Text(
                  isExpense ? 'Lưu Khoản Chi' : 'Lưu Khoản Thu',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
