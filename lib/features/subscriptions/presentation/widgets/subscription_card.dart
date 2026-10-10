import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../models/subscription_item.dart';

class SubscriptionCard extends StatelessWidget {
  final SubscriptionItem sub;
  final VoidCallback? onMarkPaid;
  final ValueChanged<bool>? onToggleActive;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const SubscriptionCard({
    super.key,
    required this.sub,
    this.onMarkPaid,
    this.onToggleActive,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = SettingsService.instance.themeBackground;
    final isDueSoon = sub.isDueSoon;
    final isOverdue = sub.isOverdue;

    Color badgeColor = AppColors.textTertiary;
    Color badgeBg = currentTheme.surfaceElevated;
    String badgeText = tr('days_remaining', {'days': '${sub.daysUntilDue}'});

    if (isOverdue) {
      badgeColor = AppColors.expense;
      badgeBg = AppColors.expenseSubtle;
      badgeText = tr('overdue', {'days': '${-sub.daysUntilDue}'});
    } else if (sub.daysUntilDue == 0) {
      badgeColor = AppColors.warning;
      badgeBg = AppColors.warningSubtle;
      badgeText = tr('due_today');
    } else if (isDueSoon) {
      badgeColor = AppColors.warning;
      badgeBg = AppColors.warningSubtle;
    }

    return Dismissible(
      key: Key('sub_${sub.id}_${sub.name}_${sub.amount}'),
      direction: DismissDirection.horizontal,
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
          onEdit?.call();
          return false;
        } else {
          onDelete?.call();
          return true;
        }
      },
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: currentTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDueSoon ? AppColors.warning.withOpacity(0.3) : currentTheme.border,
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
                                badgeText,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormatter.formatDate(sub.nextBillingDate),
                              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
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
                        SettingsService.instance.formatCurrency(sub.amount),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '/${sub.billingCycle == "YEARLY" ? tr('yearly') : tr('monthly')}',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: currentTheme.border),
              const SizedBox(height: 10),

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Active/Pause Toggle
                  Row(
                    children: [
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: sub.isActive,
                          onChanged: onToggleActive,
                          activeColor: AppColors.income,
                          activeTrackColor: AppColors.incomeSubtle,
                        ),
                      ),
                      Text(
                        sub.isActive ? 'Đang hoạt động' : 'Tạm dừng',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),

                  // Quick Paid Button
                  OutlinedButton.icon(
                    onPressed: onMarkPaid,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                    label: Text(tr('mark_paid')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.income,
                      side: BorderSide(color: AppColors.income.withOpacity(0.4)),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
