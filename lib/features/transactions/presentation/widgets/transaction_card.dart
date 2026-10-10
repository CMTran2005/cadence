import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../models/transaction_item.dart';

class TransactionCard extends StatelessWidget {
  final TransactionItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.item,
    this.onDelete,
    this.onEdit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = SettingsService.instance.themeBackground;

    return Dismissible(
      key: Key('tx_${item.id}_${item.title}_${item.amount}'),
      direction: DismissDirection.horizontal,
      // Dragging Right -> Edit
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.income.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.income.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_rounded, color: AppColors.income, size: 22),
            const SizedBox(width: 8),
            Text(
              tr('edit'),
              style: const TextStyle(
                color: AppColors.income,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      // Dragging Left -> Delete
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expenseSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.expense.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              tr('delete'),
              style: const TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 22),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          // Edit action
          onEdit?.call();
          return false; // Do not dismiss card
        } else {
          // Delete action
          onDelete?.call();
          return true; // Dismiss card
        }
      },
      child: InkWell(
        onTap: onTap ?? onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: currentTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: currentTheme.border, width: 1),
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
                              color: currentTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: currentTheme.border),
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

              // Dynamic Signed Tabular Amount
              Text(
                SettingsService.instance.formatSignedCurrency(item.amount, isIncome: item.isIncome),
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
