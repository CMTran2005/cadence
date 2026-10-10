import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../models/transaction_item.dart';

class TransactionCard extends StatelessWidget {
  final TransactionItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.item,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('tx_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expenseSubtle,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              // Category Icon Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.category.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.category.icon,
                  color: item.category.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormatter.formatRelative(item.transactionDate),
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        ),
                        if (item.isFromOcr) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.document_scanner_outlined, size: 10, color: AppColors.accent),
                                SizedBox(width: 3),
                                Text(
                                  'OCR',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Signed Tabular Amount
              Text(
                CurrencyFormatter.formatSignedVND(item.amount, isIncome: item.isIncome),
                style: TextStyle(
                  color: item.isIncome ? AppColors.income : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
