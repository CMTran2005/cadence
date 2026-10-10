import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../models/subscription_item.dart';

class SubscriptionCard extends StatelessWidget {
  final SubscriptionItem sub;
  final VoidCallback? onMarkPaid;
  final ValueChanged<bool>? onToggleActive;
  final VoidCallback? onDelete;

  const SubscriptionCard({
    super.key,
    required this.sub,
    this.onMarkPaid,
    this.onToggleActive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDueSoon = sub.isDueSoon;
    final isOverdue = sub.isOverdue;

    Color badgeColor = AppColors.textTertiary;
    Color badgeBg = AppColors.surfaceElevated;
    if (isOverdue) {
      badgeColor = AppColors.expense;
      badgeBg = AppColors.expenseSubtle;
    } else if (isDueSoon) {
      badgeColor = AppColors.warning;
      badgeBg = AppColors.warningSubtle;
    }

    return Dismissible(
      key: Key('sub_${sub.id}'),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDueSoon ? AppColors.warning.withOpacity(0.3) : AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Category Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sub.category.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(sub.category.icon, color: sub.category.color, size: 22),
                ),
                const SizedBox(width: 14),

                // Name and Billing Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.name,
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: badgeColor.withOpacity(0.2)),
                            ),
                            child: Text(
                              DateFormatter.formatDaysUntil(sub.nextBillingDate),
                              style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${DateFormatter.formatDate(sub.nextBillingDate)}',
                            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatVND(sub.amount),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub.billingCycle == 'MONTHLY' ? '/tháng' : '/năm',
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 10),

            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 36,
                      child: Switch(
                        value: sub.isActive,
                        onChanged: onToggleActive,
                        activeColor: AppColors.income,
                        activeTrackColor: AppColors.incomeSubtle,
                        inactiveThumbColor: AppColors.textTertiary,
                        inactiveTrackColor: AppColors.surfaceElevated,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sub.isActive ? 'Đang kích hoạt' : 'Tạm dừng',
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: onMarkPaid,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.income),
                  label: const Text('Đã thanh toán kỳ này', style: TextStyle(color: AppColors.income, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
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
