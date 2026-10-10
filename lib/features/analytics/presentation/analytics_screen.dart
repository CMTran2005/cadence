import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/currency_formatter.dart';
import 'widgets/spending_bar_chart.dart';

enum AnalyticsPeriod {
  week('Tuần', '7 ngày gần nhất'),
  month('Tháng', 'Theo từng tháng'),
  year('Năm', '12 tháng trong năm');

  final String label;
  final String sublabel;
  const AnalyticsPeriod(this.label, this.sublabel);
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _anchorDate = DateTime.now();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    DateTime startDate;
    DateTime endDate;
    List<ChartDataPoint> chartPoints = [];

    final y = _anchorDate.year;
    final m = _anchorDate.month;
    final d = _anchorDate.day;

    if (_selectedPeriod == AnalyticsPeriod.week) {
      // 7 days ending at anchorDate or current week Monday-Sunday
      final currentWeekday = _anchorDate.weekday; // 1 = Monday
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
      // Full month
      startDate = DateTime(y, m, 1);
      endDate = DateTime(y, m + 1, 0, 23, 59, 59, 999);

      // Divide month into 4-5 weekly buckets for chart
      final totalDays = endDate.day;
      const bucketSize = 7;
      final numBuckets = (totalDays / bucketSize).ceil();

      for (int b = 0; b < numBuckets; b++) {
        final bStart = DateTime(y, m, b * bucketSize + 1);
        final bEndDay = ((b + 1) * bucketSize).clamp(1, totalDays);
        final bEnd = DateTime(y, m, bEndDay, 23, 59, 59, 999);

        final summary = await DatabaseHelper.instance.getPeriodSummary(
          startDate: bStart,
          endDate: bEnd,
        );

        chartPoints.add(ChartDataPoint(
          label: 'Tuần ${b + 1}',
          value: summary['expense'] ?? 0.0,
          tooltipDetail: 'Ngày ${bStart.day} - ${bEnd.day}/$m',
        ));
      }
    } else {
      // Full Year
      startDate = DateTime(y, 1, 1);
      endDate = DateTime(y, 12, 31, 23, 59, 59, 999);

      final monthlyTotals = await DatabaseHelper.instance.getMonthlyExpensesForYear(y);
      for (int monthIdx = 1; monthIdx <= 12; monthIdx++) {
        chartPoints.add(ChartDataPoint(
          label: 'T$monthIdx',
          value: monthlyTotals[monthIdx - 1],
          tooltipDetail: 'Tháng $monthIdx/$y',
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

    if (mounted) {
      setState(() {
        _income = summary['income'] ?? 0.0;
        _expense = summary['expense'] ?? 0.0;
        _categoryExpenses = categories;
        _chartData = chartPoints;
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

  String _getPeriodDisplayTitle() {
    if (_selectedPeriod == AnalyticsPeriod.week) {
      final currentWeekday = _anchorDate.weekday;
      final start = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (currentWeekday - 1));
      final end = DateTime(start.year, start.month, start.day + 6);
      return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
    } else if (_selectedPeriod == AnalyticsPeriod.month) {
      return 'Tháng ${_anchorDate.month}, ${_anchorDate.year}';
    } else {
      return 'Năm ${_anchorDate.year}';
    }
  }

  void _showDatePickerModal() async {
    final availableYears = await DatabaseHelper.instance.getAvailableYears();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedPeriod == AnalyticsPeriod.year ? 'Chọn năm xem báo cáo' : 'Chọn tháng xem báo cáo',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() => _anchorDate = DateTime.now());
                        _loadAnalytics();
                      },
                      child: const Text('Hiện tại', style: TextStyle(color: AppColors.income)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_selectedPeriod == AnalyticsPeriod.year) ...[
                  Wrap(
                    spacing: 10,
                    children: availableYears.map((yr) {
                      final isSelected = yr == _anchorDate.year;
                      return ChoiceChip(
                        label: Text('$yr'),
                        selected: isSelected,
                        onSelected: (_) {
                          Navigator.of(ctx).pop();
                          setState(() => _anchorDate = DateTime(yr, 1, 1));
                          _loadAnalytics();
                        },
                        selectedColor: AppColors.income,
                        backgroundColor: AppColors.surfaceElevated,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  SizedBox(
                    height: 220,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1.8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, idx) {
                        final m = idx + 1;
                        final isSelected = _anchorDate.month == m;
                        return InkWell(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            setState(() => _anchorDate = DateTime(_anchorDate.year, m, 1));
                            _loadAnalytics();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.income : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSelected ? Colors.transparent : AppColors.border),
                            ),
                            child: Text(
                              'Thg $m',
                              style: TextStyle(
                                color: isSelected ? Colors.black : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: availableYears.map((yr) {
                      final isYrSelected = _anchorDate.year == yr;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ActionChip(
                          label: Text('$yr'),
                          backgroundColor: isYrSelected ? AppColors.textPrimary : AppColors.surfaceElevated,
                          labelStyle: TextStyle(
                            color: isYrSelected ? Colors.black : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            setState(() => _anchorDate = DateTime(yr, _anchorDate.month, 1));
                            _loadAnalytics();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final netCashflow = _income - _expense;
    final isSurplus = netCashflow >= 0;
    final savingsRate = _income > 0 ? ((netCashflow / _income) * 100).clamp(-100, 100) : 0.0;
    final totalCategorized = _categoryExpenses.values.fold(0.0, (sum, val) => sum + val);

    final currentTheme = SettingsService.instance.themeBackground;

    return AnimatedBuilder(
      animation: SettingsService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: currentTheme.background,
          appBar: AppBar(
            backgroundColor: currentTheme.background,
            title: const Text('Phân Tích Dòng Tiền'),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  color: AppColors.textPrimary,
                  backgroundColor: currentTheme.surface,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // Period Segmented Selector (Tuần | Tháng | Năm)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: currentTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: currentTheme.border),
                        ),
                        child: Row(
                          children: AnalyticsPeriod.values.map((period) {
                            final isSelected = period == _selectedPeriod;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (_selectedPeriod != period) {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedPeriod = period;
                                      _anchorDate = DateTime.now();
                                    });
                                    _loadAnalytics();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? currentTheme.surfaceElevated : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: isSelected ? Border.all(color: currentTheme.border) : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Theo ${period.label}',
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

                      const SizedBox(height: 12),

                      // Time Navigator Strip (< Tháng 10, 2026 >)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: currentTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: currentTheme.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.textSecondary),
                              onPressed: _previousPeriod,
                              visualDensity: VisualDensity.compact,
                            ),
                            GestureDetector(
                              onTap: _showDatePickerModal,
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.textTertiary),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getPeriodDisplayTitle(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textTertiary),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textSecondary),
                              onPressed: _nextPeriod,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Net Flow Hero Card
                      Container(
                        padding: const EdgeInsets.all(20),
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
                                  'DÒNG TIỀN RÒNG ${_getPeriodDisplayTitle().toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isSurplus ? AppColors.incomeSubtle : AppColors.expenseSubtle,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isSurplus
                                        ? '+${savingsRate.toStringAsFixed(1)}% thặng dư'
                                        : '${savingsRate.toStringAsFixed(1)}% thâm hụt',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isSurplus ? AppColors.income : AppColors.expense,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              CurrencyFormatter.format(netCashflow.abs()),
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: isSurplus ? AppColors.income : AppColors.expense,
                                letterSpacing: -0.8,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.income),
                                          SizedBox(width: 4),
                                          Text('Tổng Thu', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyFormatter.format(revenueOrZero(_income)),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 32, color: currentTheme.border),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.expense),
                                          SizedBox(width: 4),
                                          Text('Tổng Chi', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyFormatter.format(revenueOrZero(_expense)),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Interactive Spending Bar Chart
                      SpendingBarChart(
                        dataPoints: _chartData,
                        title: 'Biến động chi tiêu',
                        periodLabel: _getPeriodDisplayTitle(),
                      ),

                      const SizedBox(height: 24),

                      // Category Breakdown Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Phân bổ theo danh mục',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(totalCategorized),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Category Breakdown List
                      if (_categoryExpenses.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: currentTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: currentTheme.border),
                          ),
                          child: const Text(
                            'Chưa có dữ liệu chi tiêu trong khoảng thời gian này',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: currentTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: currentTheme.border),
                          ),
                          child: Column(
                            children: _categoryExpenses.entries.map((entry) {
                              final cat = entry.key;
                              final amount = entry.value;
                              final pct = totalCategorized > 0 ? (amount / totalCategorized) : 0.0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: currentTheme.surfaceElevated,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: currentTheme.border),
                                          ),
                                          child: Icon(cat.icon, size: 16, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cat.displayName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${(pct * 100).toStringAsFixed(1)}% tổng chi',
                                                style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(amount),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 5,
                                        backgroundColor: currentTheme.surfaceElevated,
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        );
      },
    );
  }

  double revenueOrZero(double val) => val < 0 ? 0.0 : val;
}
