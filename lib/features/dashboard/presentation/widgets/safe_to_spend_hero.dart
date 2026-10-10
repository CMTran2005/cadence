import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Label & Days Remaining Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: AppColors.income),
                  SizedBox(width: 8),
                  Text(
                    'An toàn để tiêu hôm nay',
                    style: TextStyle(
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
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Còn $daysRemaining ngày trong tháng',
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
            CurrencyFormatter.formatVND(safeToSpendDaily),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -1.2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hạn mức mỗi ngày để cuối tháng không bị âm quỹ tiết kiệm',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 16),

          // Monthly In/Out Mini Bar
          Row(
            children: [
              Expanded(
                child: _statColumn(
                  label: 'Thu tháng này',
                  amount: monthlyIncome,
                  color: AppColors.income,
                  isPositive: true,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              Expanded(
                child: _statColumn(
                  label: 'Đã chi tiêu',
                  amount: monthlyExpense,
                  color: AppColors.expense,
                  isPositive: false,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              Expanded(
                child: _statColumn(
                  label: 'Gói định kỳ',
                  amount: fixedSubTotal,
                  color: AppColors.accent,
                  isPositive: false,
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
    required bool isPositive,
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
            CurrencyFormatter.formatCompact(amount),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
