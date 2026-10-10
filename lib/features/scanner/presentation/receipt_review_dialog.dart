import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../transactions/models/transaction_item.dart';
import '../models/parsed_receipt_draft.dart';

class ReceiptReviewDialog extends StatefulWidget {
  final ParsedReceiptDraft draft;

  const ReceiptReviewDialog({super.key, required this.draft});

  static Future<TransactionItem?> show(BuildContext context, ParsedReceiptDraft draft) {
    return showModalBottomSheet<TransactionItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReceiptReviewDialog(draft: draft),
    );
  }

  @override
  State<ReceiptReviewDialog> createState() => _ReceiptReviewDialogState();
}

class _ReceiptReviewDialogState extends State<ReceiptReviewDialog> {
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late TransactionType _type;
  late CategoryType _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _type = TransactionType.expense;
    _merchantController = TextEditingController(text: widget.draft.merchant);
    _amountController = TextEditingController(
      text: widget.draft.totalAmount > 0
          ? widget.draft.totalAmount.toInt().toString()
          : '',
    );
    _notesController = TextEditingController();
    _selectedCategory = widget.draft.suggestedCategory;
    _selectedDate = widget.draft.transactionDate;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _changeType(TransactionType newType) {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      _selectedCategory = (newType == TransactionType.income) ? CategoryType.sales : CategoryType.food;
    });
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('validation_amount'))),
      );
      return;
    }

    final tx = TransactionItem(
      title: _merchantController.text.trim().isEmpty ? tr('scan_title') : _merchantController.text.trim(),
      amount: amount,
      type: _type,
      category: _selectedCategory,
      transactionDate: _selectedDate,
      source: 'OCR_SCAN',
      receiptImagePath: widget.draft.imagePath,
      rawOcrText: widget.draft.rawText,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    Navigator.of(context).pop(tx);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentTheme = SettingsService.instance.themeBackground;
    final isExpense = _type == TransactionType.expense;

    final categories = isExpense
        ? [
            CategoryType.food,
            CategoryType.shopping,
            CategoryType.transport,
            CategoryType.bills,
            CategoryType.subscriptions,
            CategoryType.entertainment,
            CategoryType.health,
            CategoryType.other,
          ]
        : [
            CategoryType.sales,
            CategoryType.salary,
            CategoryType.freelance,
            CategoryType.gift,
            CategoryType.investment,
            CategoryType.other,
          ];

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
        border: Border(
          top: BorderSide(color: currentTheme.border, width: 1),
        ),
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

            // Header & Confidence Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('scan_title'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.incomeSubtle,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.income.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.income),
                      const SizedBox(width: 4),
                      Text(
                        tr('confidence', {'percent': '${(widget.draft.confidenceScore * 100).toInt()}'}),
                        style: const TextStyle(
                          color: AppColors.income,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Type Toggle: Chi tiêu vs Thu nhập (Bill khách chuyển)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: currentTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: currentTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _changeType(TransactionType.expense),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isExpense ? AppColors.expense.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          border: isExpense ? Border.all(color: AppColors.expense.withOpacity(0.4)) : null,
                        ),
                        child: Center(
                          child: Text(
                            tr('scan_type_expense'),
                            style: TextStyle(
                              color: isExpense ? AppColors.expense : AppColors.textSecondary,
                              fontWeight: isExpense ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () => _changeType(TransactionType.income),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: !isExpense ? AppColors.income.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          border: !isExpense ? Border.all(color: AppColors.income.withOpacity(0.4)) : null,
                        ),
                        child: Center(
                          child: Text(
                            tr('scan_type_income'),
                            style: TextStyle(
                              color: !isExpense ? AppColors.income : AppColors.textSecondary,
                              fontWeight: !isExpense ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Amount field
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: tr('amount'),
                prefixText: '${SettingsService.instance.currency.symbol} ',
                prefixStyle: TextStyle(
                  color: isExpense ? AppColors.expense : AppColors.income,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Merchant / Title field
            TextField(
              controller: _merchantController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: isExpense ? tr('item_name_label') : tr('service_name'),
                prefixIcon: const Icon(Icons.storefront_outlined, color: AppColors.textTertiary),
              ),
            ),

            const SizedBox(height: 14),

            // Category Chips (Filtered by Type)
            Text(
              tr('category'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat.displayName),
                  avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.black : cat.color),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                  selectedColor: isExpense ? AppColors.expense : AppColors.income,
                  backgroundColor: currentTheme.surfaceElevated,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: currentTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Date preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: currentTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: currentTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 8),
                  Text(
                    '${tr('transaction_date')}: ${DateFormatter.formatDate(_selectedDate)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Notes field
            TextField(
              controller: _notesController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: tr('notes_optional'),
                prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.textTertiary),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: currentTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(tr('cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(tr('save_transaction'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
