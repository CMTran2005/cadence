import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../models/transaction_item.dart';

class ManualEntryScreen extends StatefulWidget {
  final TransactionType initialType;

  const ManualEntryScreen({super.key, this.initialType = TransactionType.expense});

  static Future<bool?> navigateTo(BuildContext context, {TransactionType initialType = TransactionType.expense}) {
    return Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        pageBuilder: (context, animation, secondaryAnimation) => ManualEntryScreen(initialType: initialType),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.08);
          const end = Offset.zero;
          final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: begin, end: end).animate(curve),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  late TransactionType _type;
  late CategoryType _category;
  late DateTime _date;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<double> _quickAddAmounts = [20000, 50000, 100000, 200000, 500000];

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

  void _addQuickAmount(double delta) {
    HapticFeedback.selectionClick();
    final current = CurrencyFormatter.parseAmount(_amountController.text);
    final updated = current + delta;
    _amountController.text = updated.toInt().toString();
    setState(() {});
  }

  Future<void> _submit() async {
    final amount = CurrencyFormatter.parseAmount(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền lớn hơn 0'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? (_type == TransactionType.expense ? _category.displayName : 'Thu nhập mới')
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
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.income,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _type == TransactionType.expense;
    final currentTheme = SettingsService.instance.themeBackground;

    return Scaffold(
      backgroundColor: currentTheme.background,
      appBar: AppBar(
        backgroundColor: currentTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          isExpense ? 'Ghi chép chi tiêu' : 'Ghi chép thu nhập',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: _submit,
            style: TextButton.styleFrom(
              foregroundColor: isExpense ? AppColors.expense : AppColors.income,
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            child: const Text('LƯU'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // Type Switcher: Expense vs Income
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: currentTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: currentTheme.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_type != TransactionType.expense) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _type = TransactionType.expense;
                                  _category = CategoryType.food;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isExpense ? AppColors.expenseSubtle : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isExpense ? Border.all(color: AppColors.expense, width: 1.2) : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Khoản Chi (-)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isExpense ? AppColors.expense : AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_type != TransactionType.income) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _type = TransactionType.income;
                                  _category = CategoryType.salary;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isExpense ? AppColors.incomeSubtle : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: !isExpense ? Border.all(color: AppColors.income, width: 1.2) : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Khoản Thu (+)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: !isExpense ? AppColors.income : AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Amount Hero Input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: currentTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: currentTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SỐ TIỀN (${SettingsService.instance.currency.symbol})',
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              isExpense ? '-' : '+',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: isExpense ? AppColors.expense : AppColors.income,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -1.0,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textTertiary.withOpacity(0.5),
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  fillColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Quick Add Buttons (+50k, +100k, etc.)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickAddAmounts.map((q) {
                            return InkWell(
                              onTap: () => _addQuickAmount(q),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: currentTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: currentTheme.border),
                                ),
                                child: Text(
                                  '+${CurrencyFormatter.formatCompact(q)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title / Merchant Input
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Tên mục / Cửa hàng',
                      hintText: isExpense ? 'Ví dụ: Cơm trưa, Siêu thị WinMart...' : 'Ví dụ: Lương thưởng, Hoàn tiền...',
                      prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.textTertiary, size: 20),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Category Selector Chips
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DANH MỤC PHÂN LOẠI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CategoryType.values.map((cat) {
                          final isSelected = cat == _category;
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(cat.icon, size: 14, color: isSelected ? Colors.black : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(cat.displayName),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                HapticFeedback.selectionClick();
                                setState(() => _category = cat);
                              }
                            },
                            selectedColor: isExpense ? AppColors.expense : AppColors.income,
                            backgroundColor: currentTheme.surfaceElevated,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : currentTheme.border,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Date Picker Row
                  InkWell(
                    onTap: _selectDate,
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
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textTertiary),
                              const SizedBox(width: 12),
                              const Text('Ngày giao dịch', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                DateFormatter.formatVietnameseDate(_date),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Notes Input
                  TextField(
                    controller: _notesController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (Tùy chọn)',
                      hintText: 'Thêm chi tiết hóa đơn hoặc lưu ý cá nhân...',
                      prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textTertiary, size: 20),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),

            // Bottom Confirm Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: currentTheme.surface,
                border: Border(top: BorderSide(color: currentTheme.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    isExpense ? 'Lưu Khoản Chi Tiêu' : 'Lưu Khoản Thu Nhập',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExpense ? AppColors.expense : AppColors.income,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
