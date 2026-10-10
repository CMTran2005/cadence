import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/settings_service.dart';

class SafeToSpendHero extends StatelessWidget {
  final double safeToSpendDaily;
  final double monthlyIncome;
  final double monthlyExpense;
  final double fixedSubTotal;

  const SafeToSpendHero({
    super.key,
    required this.safeToSpendDaily,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.fixedSubTotal,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = (daysInMonth - now.day + 1).clamp(1, 31);
    final currentTheme = SettingsService.instance.themeBackground;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: currentTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: currentTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Label & Days Remaining Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: AppColors.income),
                  const SizedBox(width: 8),
                  Text(
                    tr('safe_to_spend_today'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: currentTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: currentTheme.border),
                ),
                child: Text(
                  tr('days_remaining', {'days': '$daysRemaining'}),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Big Metric (Safe-to-Spend per day)
          Text(
            SettingsService.instance.formatCurrency(safeToSpendDaily),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -1.2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('safe_to_spend_desc'),
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Divider(color: currentTheme.border, height: 1),
          const SizedBox(height: 16),

          // Monthly In/Out Mini Bar
          Row(
            children: [
              Expanded(
                child: _statColumn(
                  label: tr('total_income'),
                  amount: monthlyIncome,
                  color: AppColors.income,
                ),
              ),
              Container(width: 1, height: 32, color: currentTheme.border),
              Expanded(
                child: _statColumn(
                  label: tr('spent'),
                  amount: monthlyExpense,
                  color: AppColors.expense,
                ),
              ),
              Container(width: 1, height: 32, color: currentTheme.border),
              Expanded(
                child: _statColumn(
                  label: tr('recurring'),
                  amount: fixedSubTotal,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            SettingsService.instance.formatCompactCurrency(amount),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
