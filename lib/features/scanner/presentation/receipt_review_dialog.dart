import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
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
  late CategoryType _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
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

  void _save() {
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    final tx = TransactionItem(
      title: _merchantController.text.trim().isEmpty ? 'Hóa đơn quét' : _merchantController.text.trim(),
      amount: amount,
      type: TransactionType.expense,
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
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
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
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header & Confidence Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Xác nhận hóa đơn OCR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
                        'Độ tin cậy ${(widget.draft.confidenceScore * 100).toInt()}%',
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
            const SizedBox(height: 20),

            // Amount field
            const Text('Số tiền (VND)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.expense,
                letterSpacing: -0.5,
              ),
              decoration: InputDecoration(
                prefixText: '₫ ',
                prefixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.expense),
                hintText: '0',
                filled: true,
                fillColor: AppColors.surfaceElevated,
              ),
            ),
            const SizedBox(height: 16),

            // Merchant field
            const Text('Nơi bán / Cửa hàng', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _merchantController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Tên cửa hàng hoặc dịch vụ',
                prefixIcon: Icon(Icons.storefront_outlined, size: 20, color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 16),

            // Category selector
            const Text('Danh mục chi tiêu', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CategoryType.values.take(8).map((cat) {
                final isSelected = _selectedCategory == cat;
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
                    side: BorderSide(
                      color: isSelected ? cat.color : AppColors.border,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Date picker row
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _selectedDate = picked);
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
                      'Ngày giao dịch: ${DateFormatter.formatDate(_selectedDate)}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                  ],
                ),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
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
                    child: const Text(
                      'Lưu Giao Dịch',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
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
