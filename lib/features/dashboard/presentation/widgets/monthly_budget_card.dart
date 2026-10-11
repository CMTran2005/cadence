import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/settings_service.dart';

class MonthlyBudgetCard extends StatelessWidget {
  final double currentExpense;
  final VoidCallback onBudgetChanged;

  const MonthlyBudgetCard({
    super.key,
    required this.currentExpense,
    required this.onBudgetChanged,
  });

  void _showSetBudgetDialog(BuildContext context) {
    final settings = SettingsService.instance;
    final currentBudget = settings.monthlyBudget;
    final controller = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        final currentTheme = settings.themeBackground;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: currentTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: currentTheme.border),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.income),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    currentBudget > 0 ? tr('edit_budget') : tr('set_budget'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('budget_desc'),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: tr('enter_budget_hint'),
                        prefixText: '${settings.currency.symbol} ',
                        prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.income),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Quick Increment Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [1000000, 2000000, 5000000, 10000000, 20000000].map((amt) {
                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            controller.text = amt.toString();
                            setDialogState(() {});
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: currentTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: currentTheme.border),
                            ),
                            child: Text(
                              '+${settings.formatCompactCurrency(amt.toDouble())}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                if (currentBudget > 0)
                  TextButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await settings.setMonthlyBudget(0.0);
                      onBudgetChanged();
                    },
                    child: Text(tr('clear_all_data'), style: const TextStyle(color: AppColors.expense, fontSize: 13)),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(tr('cancel'), style: const TextStyle(color: AppColors.textTertiary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final raw = controller.text.replaceAll(RegExp(r'[^0-9.]'), '');
                    final parsed = double.tryParse(raw) ?? 0.0;
                    Navigator.of(ctx).pop();
                    await settings.setMonthlyBudget(parsed);
                    onBudgetChanged();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(tr('save'), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    final currentTheme = settings.themeBackground;
    final monthlyBudget = settings.monthlyBudget;

    // IF NO BUDGET CONFIGURED YET: Show an inviting setup banner
    if (monthlyBudget <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: currentTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: currentTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: currentTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: currentTheme.border),
              ),
              child: const Icon(Icons.tune_rounded, size: 20, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('monthly_budget'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr('budget_prompt'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _showSetBudgetDialog(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.income,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              child: Text(
                tr('set_budget'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    // IF BUDGET IS CONFIGURED: Rich interactive progress & warning card
    final ratio = (currentExpense / monthlyBudget);
    final remaining = monthlyBudget - currentExpense;
    final isExceeded = currentExpense > monthlyBudget;
    final isWarning = ratio >= 0.7 && !isExceeded;

    final Color statusColor = isExceeded
        ? AppColors.expense
        : isWarning
            ? const Color(0xFFF59E0B)
            : AppColors.income;

    final String statusLabel = isExceeded
        ? tr('budget_exceeded')
        : isWarning
            ? tr('budget_warning')
            : tr('budget_safe');

    final IconData statusIcon = isExceeded
        ? Icons.error_outline_rounded
        : isWarning
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: currentTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExceeded
              ? AppColors.expense.withValues(alpha: 0.5)
              : currentTheme.border,
          width: isExceeded ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    tr('monthly_budget'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showSetBudgetDialog(context),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr('edit_budget'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.edit_rounded, size: 12, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Metric: Remaining vs Exceeded
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isExceeded
                        ? tr('budget_exceeded_by', {'amount': settings.formatCurrency(remaining.abs())})
                        : tr('budget_remaining', {'amount': settings.formatCurrency(remaining)}),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: currentTheme.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),

          // Footer Details: Spent / Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${tr('spent')}: ${settings.formatCurrency(currentExpense)} (${(ratio * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${tr('budget_limit')}: ${settings.formatCurrency(monthlyBudget)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
