import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

class ChartDataPoint {
  final String label;
  final double value;
  final String? tooltipDetail;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.tooltipDetail,
  });
}

class SpendingBarChart extends StatefulWidget {
  final List<ChartDataPoint> dataPoints;
  final String title;
  final String periodLabel;

  const SpendingBarChart({
    super.key,
    required this.dataPoints,
    required this.title,
    required this.periodLabel,
  });

  @override
  State<SpendingBarChart> createState() => _SpendingBarChartState();
}

class _SpendingBarChartState extends State<SpendingBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = widget.dataPoints.map((e) => e.value).fold(0.0, (prev, elem) => elem > prev ? elem : prev);
    final totalSpent = widget.dataPoints.map((e) => e.value).fold(0.0, (prev, elem) => prev + elem);
    final avgSpent = widget.dataPoints.isNotEmpty ? totalSpent / widget.dataPoints.length : 0.0;

    final selectedPoint = _selectedIndex != null && _selectedIndex! < widget.dataPoints.length
        ? widget.dataPoints[_selectedIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Selected or Total Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.periodLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    selectedPoint != null
                        ? CurrencyFormatter.format(selectedPoint.value)
                        : CurrencyFormatter.format(totalSpent),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    selectedPoint != null
                        ? (selectedPoint.tooltipDetail ?? selectedPoint.label)
                        : 'Tổng chi kỳ này',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bar Visualization
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.dataPoints.length, (index) {
                final pt = widget.dataPoints[index];
                final isSelected = _selectedIndex == index;
                final isPeak = maxValue > 0 && pt.value == maxValue;
                final ratio = maxValue > 0 ? (pt.value / maxValue).clamp(0.04, 1.0) : 0.04;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _selectedIndex = (_selectedIndex == index) ? null : index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Bar
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                height: 120 * ratio,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : isPeak
                                          ? AppColors.expense
                                          : (pt.value > 0 ? AppColors.accent.withOpacity(0.75) : AppColors.surfaceElevated),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : isPeak
                                            ? AppColors.expense
                                            : AppColors.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Label
                          Text(
                            pt.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 14),

          // Footer Legend: Average and Tap prompt
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.expense, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  const Text('Điểm chi cao nhất', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                ],
              ),
              Text(
                'TB: ${CurrencyFormatter.formatCompact(avgSpent)} / mốc',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
