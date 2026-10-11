import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../models/transaction_item.dart';

class ManualEntryScreen extends StatefulWidget {
  final TransactionType initialType;
  final TransactionItem? existingItem;

  const ManualEntryScreen({
    super.key,
    this.initialType = TransactionType.expense,
    this.existingItem,
  });

  static Future<bool?> navigateTo(
    BuildContext context, {
    TransactionType initialType = TransactionType.expense,
    TransactionItem? existingItem,
  }) {
    return Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        pageBuilder: (context, animation, secondaryAnimation) => ManualEntryScreen(
          initialType: initialType,
          existingItem: existingItem,
        ),
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

  List<CategoryItemData> _customCategories = [];

  final List<double> _quickAddAmounts = [20000, 50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _type = item.type;
      _category = item.category;
      _date = item.transactionDate;
      _amountController.text = item.amount.toInt().toString();
      _titleController.text = item.title;
      _notesController.text = item.notes ?? '';
    } else {
      _type = widget.initialType;
      _category = _type == TransactionType.expense ? CategoryType.food : CategoryType.salary;
      _date = DateTime.now();
    }
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final list = await DatabaseHelper.instance.getAllCustomCategories();
    if (mounted) {
      setState(() => _customCategories = list);
    }
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

  List<CategoryType> get _expenseCategories => const [
    CategoryType.food,
    CategoryType.shopping,
    CategoryType.transport,
    CategoryType.bills,
    CategoryType.subscriptions,
    CategoryType.entertainment,
    CategoryType.health,
    CategoryType.education,
    CategoryType.other,
  ];

  List<CategoryType> get _incomeCategories => const [
    CategoryType.salary,
    CategoryType.freelance,
    CategoryType.investment,
    CategoryType.gift,
    CategoryType.sales,
    CategoryType.other,
  ];

  void _changeType(TransactionType newType) {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      // Auto-switch to valid category for new type
      _category = newType == TransactionType.expense ? CategoryType.food : CategoryType.salary;
    });
  }

  Future<void> _submit() async {
    final amount = CurrencyFormatter.parseAmount(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('validation_amount')),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? (_type == TransactionType.expense ? _category.displayName : tr('cat_salary'))
        : _titleController.text.trim();

    if (widget.existingItem != null) {
      final updated = widget.existingItem!.copyWith(
        title: title,
        amount: amount,
        type: _type,
        category: _category,
        transactionDate: _date,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      await DatabaseHelper.instance.updateTransaction(updated);
    } else {
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
    }

    final monthlyBudget = SettingsService.instance.monthlyBudget;
    String? warningMsg;
    if (_type == TransactionType.expense && monthlyBudget > 0) {
      final currentExpense = await DatabaseHelper.instance.getCurrentMonthExpense();
      if (currentExpense > monthlyBudget) {
        warningMsg = tr('budget_exceeded_snack');
      } else if (currentExpense >= monthlyBudget * 0.8) {
        warningMsg = tr('budget_warning_snack');
      }
    }

    if (mounted) {
      HapticFeedback.mediumImpact();
      if (warningMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(warningMsg),
            backgroundColor: AppColors.expense,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    IconData selectedIcon = Icons.stars_rounded;
    Color selectedColor = const Color(0xFFF59E0B);

    const availableIcons = CategoryItemData.selectableIcons;

    final availableColors = [
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF06B6D4),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFEF4444),
      const Color(0xFF14B8A6),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(tr('add_category'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: tr('category_name'),
                      hintText: tr('category_name_hint'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(tr('choose_icon'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableIcons.map((ic) {
                      final isSelected = ic == selectedIcon;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedIcon = ic),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.income.withOpacity(0.2) : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? AppColors.income : AppColors.border),
                          ),
                          child: Icon(ic, size: 20, color: isSelected ? AppColors.income : AppColors.textSecondary),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(tr('choose_color'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: availableColors.map((clr) {
                      final isSelected = clr == selectedColor;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = clr),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: clr,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(tr('cancel'), style: const TextStyle(color: AppColors.textTertiary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final newCat = CategoryItemData(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    icon: selectedIcon,
                    color: selectedColor,
                    type: _type,
                    isCustom: true,
                  );
                  await DatabaseHelper.instance.insertCustomCategory(newCat);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  await _loadCustomCategories();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.background,
                ),
                child: Text(tr('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _type == TransactionType.expense;
    final currentTheme = SettingsService.instance.themeBackground;
    final isEditing = widget.existingItem != null;

    final displayedCategories = isExpense ? _expenseCategories : _incomeCategories;
    final customForType = _customCategories.where((c) => c.type == _type).toList();

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
          isEditing
              ? tr('edit_entry_title')
              : (isExpense ? tr('entry_expense_title') : tr('entry_income_title')),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _submit,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.income,
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              child: Text(isEditing ? tr('update_transaction') : tr('save')),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Dual Type Segmented Switch (Chi tiêu vs Thu nhập)
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
                          child: InkWell(
                            onTap: () => _changeType(TransactionType.expense),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isExpense ? AppColors.expense.withOpacity(0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isExpense
                                    ? Border.all(color: AppColors.expense.withOpacity(0.5))
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: isExpense ? AppColors.expense : AppColors.textTertiary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr('expense'),
                                    style: TextStyle(
                                      color: isExpense ? AppColors.expense : AppColors.textSecondary,
                                      fontWeight: isExpense ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () => _changeType(TransactionType.income),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isExpense ? AppColors.income.withOpacity(0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: !isExpense
                                    ? Border.all(color: AppColors.income.withOpacity(0.5))
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: !isExpense ? AppColors.income : AppColors.textTertiary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr('income'),
                                    style: TextStyle(
                                      color: !isExpense ? AppColors.income : AppColors.textSecondary,
                                      fontWeight: !isExpense ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 14,
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

                  const SizedBox(height: 20),

                  // Large Hero Amount Input Field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: currentTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: currentTheme.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              SettingsService.instance.currency.symbol,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: isExpense ? AppColors.textTertiary : AppColors.income,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                autofocus: !isEditing,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -1.0,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                                decoration: InputDecoration(
                                  hintText: tr('enter_amount_hint'),
                                  hintStyle: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textTertiary.withOpacity(0.3),
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  fillColor: Colors.transparent,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Quick increment amount chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _quickAddAmounts.map((amt) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () => _addQuickAmount(amt),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: currentTheme.surfaceElevated,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: currentTheme.border),
                                    ),
                                    child: Text(
                                      '+${SettingsService.instance.formatCompactCurrency(amt)}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Item Name Field
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: tr('item_name_label'),
                      hintText: isExpense ? tr('item_expense_hint') : tr('item_income_hint'),
                      prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.textTertiary, size: 20),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Filtered Category Selector Chips (Separated by Type + Custom Categories)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('category_classify'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showAddCategoryDialog,
                            icon: const Icon(Icons.add_rounded, size: 14),
                            label: Text(tr('add_category'), style: const TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.income,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Standard Categories for current type
                          ...displayedCategories.map((cat) {
                            final isSelected = cat == _category;
                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(cat.icon, size: 14, color: isSelected ? Colors.black : cat.color),
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
                          }),
                          // Custom Categories created by user
                          ...customForType.map((customCat) {
                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(customCat.icon, size: 14, color: customCat.color),
                                  const SizedBox(width: 6),
                                  Text(customCat.name),
                                ],
                              ),
                              selected: false,
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                _titleController.text = customCat.name;
                                setState(() => _category = CategoryType.other);
                              },
                              backgroundColor: currentTheme.surfaceElevated,
                              labelStyle: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              side: BorderSide(color: currentTheme.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            );
                          }),
                        ],
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
                              Text(tr('transaction_date'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
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

                  // Notes Field
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: tr('notes_optional'),
                      hintText: tr('notes_hint'),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.notes_rounded, color: AppColors.textTertiary, size: 20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isEditing ? tr('update_transaction') : tr('save_transaction'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
