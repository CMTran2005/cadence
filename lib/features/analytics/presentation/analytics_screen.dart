import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/currency_formatter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  double _income = 0.0;
  double _expense = 0.0;
  double _subscriptionFixed = 0.0;
  Map<CategoryType, double> _categoryExpenses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final income = await DatabaseHelper.instance.getCurrentMonthIncome();
    final expense = await DatabaseHelper.instance.getCurrentMonthExpense();
    final subFixed = await DatabaseHelper.instance.getMonthlySubscriptionTotal();
    final categories = await DatabaseHelper.instance.getCategoryExpenseBreakdown();

    if (mounted) {
      setState(() {
        _income = income;
        _expense = expense;
        _subscriptionFixed = subFixed;
        _categoryExpenses = categories;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final netCashflow = _income - _expense;
    final isSurplus = netCashflow >= 0;
    final totalCategorized = _categoryExpenses.values.fold(0.0, (sum, val) => sum + val);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Phân Tích Dòng Tiền'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: AppColors.textPrimary,
              backgroundColor: AppColors.surface,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Net Flow Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dòng tiền ròng tháng này',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              CurrencyFormatter.formatVND(netCashflow.abs()),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: isSurplus ? AppColors.income : AppColors.expense,
                                letterSpacing: -0.8,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSurplus ? AppColors.incomeSubtle : AppColors.expenseSubtle,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isSurplus ? 'Thặng dư' : 'Thâm hụt',
                                style: TextStyle(
                                  color: isSurplus ? AppColors.income : AppColors.expense,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.borderSubtle, height: 1),
                        const SizedBox(height: 14),

                        // Income vs Expense comparison
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _miniMetric('Tổng thu', _income, AppColors.income),
                            _miniMetric('Tổng chi', _expense, AppColors.expense),
                            _miniMetric('Gói cố định', _subscriptionFixed, AppColors.accent),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Breakdown Section
                  const Text(
                    'Phân bổ chi tiêu theo danh mục',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_categoryExpenses.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      alignment: Alignment.center,
                      child: const Text(
                        'Chưa có dữ liệu chi tiêu tháng này',
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                      ),
                    )
                  else
                    ..._categoryExpenses.entries.map((entry) {
                      final category = entry.key;
                      final amount = entry.value;
                      final percent = totalCategorized > 0 ? (amount / totalCategorized) : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: category.color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(category.icon, size: 18, color: category.color),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category.displayName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatVND(amount),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(percent * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: AppColors.surfaceElevated,
                                valueColor: AlwaysStoppedAnimation<Color>(category.color),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _miniMetric(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        const SizedBox(height: 3),
        Text(
          CurrencyFormatter.formatCompact(value),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
