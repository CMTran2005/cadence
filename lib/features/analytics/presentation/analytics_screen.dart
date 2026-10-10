import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/app_data_notifier.dart';
import '../../../core/services/settings_service.dart';
import 'widgets/spending_bar_chart.dart';

enum AnalyticsPeriod {
  week,
  month,
  year;

  String get label {
    switch (this) {
      case AnalyticsPeriod.week:
        return tr('period_week');
      case AnalyticsPeriod.month:
        return tr('period_month');
      case AnalyticsPeriod.year:
        return tr('period_year');
    }
  }
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.month;
  late DateTime _anchorDate;

  double _income = 0.0;
  double _expense = 0.0;
  Map<CategoryType, double> _categoryExpenses = {};
  List<ChartDataPoint> _chartData = [];
  String _averageUnitLabel = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _anchorDate = DateTime.now();
    _loadAnalytics();
    AppDataNotifier.instance.addListener(_loadAnalytics);
    SettingsService.instance.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppDataNotifier.instance.removeListener(_loadAnalytics);
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    DateTime startDate;
    DateTime endDate;
    List<ChartDataPoint> chartPoints = [];

    final y = _anchorDate.year;
    final m = _anchorDate.month;
    final d = _anchorDate.day;

    if (_selectedPeriod == AnalyticsPeriod.week) {
      // Current week Monday to Sunday
      final currentWeekday = _anchorDate.weekday; // 1 = Monday, 7 = Sunday
      startDate = DateTime(y, m, d - (currentWeekday - 1));
      endDate = DateTime(startDate.year, startDate.month, startDate.day + 6, 23, 59, 59, 999);

      final dailyExpenses = await DatabaseHelper.instance.getDailyExpensesForRange(
        startDate: startDate,
        numDays: 7,
      );

      final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      for (int i = 0; i < 7; i++) {
        final date = DateTime(startDate.year, startDate.month, startDate.day + i);
        chartPoints.add(ChartDataPoint(
          label: dayLabels[i],
          value: dailyExpenses[i],
          tooltipDetail: '${dayLabels[i]} (${date.day}/${date.month})',
        ));
      }
    } else if (_selectedPeriod == AnalyticsPeriod.month) {
      // Month real-time calendar weeks alignment
      startDate = DateTime(y, m, 1);
      final lastDayOfMonth = DateTime(y, m + 1, 0).day;
      endDate = DateTime(y, m, lastDayOfMonth, 23, 59, 59, 999);

      int currentStartDay = 1;
      int weekIndex = 1;

      while (currentStartDay <= lastDayOfMonth) {
        final dt = DateTime(y, m, currentStartDay);
        // Calculate days until next Sunday (weekday 7)
        final daysUntilSunday = 7 - dt.weekday;
        final currentEndDay = (currentStartDay + daysUntilSunday).clamp(1, lastDayOfMonth);

        final wStart = DateTime(y, m, currentStartDay);
        final wEnd = DateTime(y, m, currentEndDay, 23, 59, 59, 999);

        final summary = await DatabaseHelper.instance.getPeriodSummary(
          startDate: wStart,
          endDate: wEnd,
        );

        chartPoints.add(ChartDataPoint(
          label: 'T$weekIndex',
          value: summary['expense'] ?? 0.0,
          tooltipDetail: '${tr('period_week')} $weekIndex (${wStart.day}/$m - ${wEnd.day}/$m)',
        ));

        currentStartDay = currentEndDay + 1;
        weekIndex++;
      }
    } else {
      // Full Year (Jan to Dec)
      startDate = DateTime(y, 1, 1);
      endDate = DateTime(y, 12, 31, 23, 59, 59, 999);

      final monthlyTotals = await DatabaseHelper.instance.getMonthlyExpensesForYear(y);
      for (int monthIdx = 1; monthIdx <= 12; monthIdx++) {
        chartPoints.add(ChartDataPoint(
          label: 'T$monthIdx',
          value: monthlyTotals[monthIdx - 1],
          tooltipDetail: '${tr('period_month')} $monthIdx/$y',
        ));
      }
    }

    final summary = await DatabaseHelper.instance.getPeriodSummary(
      startDate: startDate,
      endDate: endDate,
    );
    final categories = await DatabaseHelper.instance.getCategoryExpenseBreakdownForRange(
      startDate: startDate,
      endDate: endDate,
    );

    final totalSpent = chartPoints.map((e) => e.value).fold(0.0, (prev, elem) => prev + elem);
    final avgSpent = chartPoints.isNotEmpty ? totalSpent / chartPoints.length : 0.0;
    final compactAvg = SettingsService.instance.formatCompactCurrency(avgSpent);

    String avgLabel;
    if (_selectedPeriod == AnalyticsPeriod.week) {
      avgLabel = tr('avg_day', {'amount': compactAvg});
    } else if (_selectedPeriod == AnalyticsPeriod.month) {
      avgLabel = tr('avg_week', {'amount': compactAvg});
    } else {
      avgLabel = tr('avg_month', {'amount': compactAvg});
    }

    if (mounted) {
      setState(() {
        _income = summary['income'] ?? 0.0;
        _expense = summary['expense'] ?? 0.0;
        _categoryExpenses = categories;
        _chartData = chartPoints;
        _averageUnitLabel = avgLabel;
        _isLoading = false;
      });
    }
  }

  void _previousPeriod() {
    HapticFeedback.selectionClick();
    if (_selectedPeriod == AnalyticsPeriod.week) {
      _anchorDate = _anchorDate.subtract(const Duration(days: 7));
    } else if (_selectedPeriod == AnalyticsPeriod.month) {
      _anchorDate = DateTime(_anchorDate.year, _anchorDate.month - 1, 1);
    } else {
      _anchorDate = DateTime(_anchorDate.year - 1, 1, 1);
    }
    _loadAnalytics();
  }

  void _nextPeriod() {
    HapticFeedback.selectionClick();
    if (_selectedPeriod == AnalyticsPeriod.week) {
      _anchorDate = _anchorDate.add(const Duration(days: 7));
    } else if (_selectedPeriod == AnalyticsPeriod.month) {
      _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + 1, 1);
    } else {
      _anchorDate = DateTime(_anchorDate.year + 1, 1, 1);
    }
    _loadAnalytics();
  }

  String _formatPeriodTitle() {
    if (_selectedPeriod == AnalyticsPeriod.week) {
      final currentWeekday = _anchorDate.weekday;
      final start = _anchorDate.subtract(Duration(days: currentWeekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
    } else if (_selectedPeriod == AnalyticsPeriod.month) {
      return '${tr('period_month')} ${_anchorDate.month}/${_anchorDate.year}';
    } else {
      return '${tr('period_year')} ${_anchorDate.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = SettingsService.instance.themeBackground;
    final netCashFlow = _income - _expense;

    return Scaffold(
      backgroundColor: currentTheme.background,
      appBar: AppBar(
        backgroundColor: currentTheme.background,
        title: Text(tr('analytics_title')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: AppColors.textPrimary,
              backgroundColor: currentTheme.surface,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  // Period Segmented Selector (Tuần, Tháng, Năm)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: currentTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: currentTheme.border),
                    ),
                    child: Row(
                      children: AnalyticsPeriod.values.map((p) {
                        final isSelected = p == _selectedPeriod;
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              if (_selectedPeriod != p) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedPeriod = p);
                                _loadAnalytics();
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected ? currentTheme.surfaceElevated : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? Border.all(color: currentTheme.border) : null,
                              ),
                              child: Center(
                                child: Text(
                                  p.label,
                                  style: TextStyle(
                                    color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Navigator Strip (< Tháng 10/2026 >)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: currentTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: currentTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, size: 24, color: AppColors.textSecondary),
                          onPressed: _previousPeriod,
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          _formatPeriodTitle(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.textSecondary),
                          onPressed: _nextPeriod,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Net Cash Flow Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: currentTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: currentTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('net_flow'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: netCashFlow >= 0 ? AppColors.incomeSubtle : AppColors.expenseSubtle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                netCashFlow >= 0 ? tr('surplus') : tr('deficit'),
                                style: TextStyle(
                                  color: netCashFlow >= 0 ? AppColors.income : AppColors.expense,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          SettingsService.instance.formatSignedCurrency(netCashFlow, isIncome: netCashFlow >= 0),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: netCashFlow >= 0 ? AppColors.income : AppColors.expense,
                            letterSpacing: -0.6,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: currentTheme.border),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr('total_income'), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    SettingsService.instance.formatCurrency(_income),
                                    style: const TextStyle(
                                      color: AppColors.income,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 26, color: currentTheme.border),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tr('spent'), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      SettingsService.instance.formatCurrency(_expense),
                                      style: const TextStyle(
                                        color: AppColors.expense,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Spending Bar Chart
                  SpendingBarChart(
                    dataPoints: _chartData,
                    title: tr('spending_trend'),
                    periodLabel: _formatPeriodTitle(),
                    averageUnitLabel: _averageUnitLabel,
                  ),

                  const SizedBox(height: 16),

                  // Category Breakdown
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: currentTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: currentTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('category_breakdown'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_categoryExpenses.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Text(
                                tr('no_data_period'),
                                style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ..._categoryExpenses.entries.map((entry) {
                            final cat = entry.key;
                            final amount = entry.value;
                            final percentage = _expense > 0 ? (amount / _expense) : 0.0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(cat.icon, size: 16, color: cat.color),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          cat.displayName,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        SettingsService.instance.formatCurrency(amount),
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${(percentage * 100).toStringAsFixed(0)}%)',
                                        style: const TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      minHeight: 5,
                                      backgroundColor: currentTheme.surfaceElevated,
                                      valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
