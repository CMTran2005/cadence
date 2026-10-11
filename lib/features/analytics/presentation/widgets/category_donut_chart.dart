import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/settings_service.dart';

class CategoryDonutChart extends StatefulWidget {
  final Map<CategoryType, double> categoryExpenses;
  final double totalExpense;

  const CategoryDonutChart({
    super.key,
    required this.categoryExpenses,
    required this.totalExpense,
  });

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  CategoryType? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final currentTheme = SettingsService.instance.themeBackground;
    final entries = widget.categoryExpenses.entries.toList();

    if (widget.totalExpense <= 0 || entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        child: Column(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _EmptyDonutPainter(trackColor: currentTheme.surfaceElevated),
                child: Center(
                  child: Text(
                    '0%',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr('no_data_period'),
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final selectedCategory = _selectedCategory;
    final selectedAmount = selectedCategory != null
        ? (widget.categoryExpenses[selectedCategory] ?? 0.0)
        : widget.totalExpense;
    final selectedPercent = widget.totalExpense > 0
        ? (selectedAmount / widget.totalExpense * 100)
        : 0.0;

    return Column(
      children: [
        // Donut Chart Graphic with Central Detail
        SizedBox(
          width: 190,
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(190, 190),
                painter: _DonutChartPainter(
                  entries: entries,
                  total: widget.totalExpense,
                  selectedCategory: selectedCategory,
                  backgroundColor: currentTheme.surfaceElevated,
                ),
              ),
              // Center Display Hole
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = null);
                },
                child: Container(
                  width: 114,
                  height: 114,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentTheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (selectedCategory != null) ...[
                            Icon(selectedCategory.icon, size: 16, color: selectedCategory.color),
                            const SizedBox(height: 2),
                            Text(
                              selectedCategory.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selectedCategory.color,
                              ),
                            ),
                            Text(
                              '${selectedPercent.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ] else ...[
                            Text(
                              tr('spent'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              SettingsService.instance.formatCompactCurrency(widget.totalExpense),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const Text(
                              '100%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Interactive Category Pills
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: entries.map((entry) {
            final cat = entry.key;
            final isSelected = cat == selectedCategory;
            final percent = (entry.value / widget.totalExpense * 100).toStringAsFixed(0);

            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedCategory = isSelected ? null : cat;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cat.color.withValues(alpha: 0.2)
                      : currentTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? cat.color : currentTheme.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: cat.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${cat.displayName} $percent%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<CategoryType, double>> entries;
  final double total;
  final CategoryType? selectedCategory;
  final Color backgroundColor;

  _DonutChartPainter({
    required this.entries,
    required this.total,
    required this.selectedCategory,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0 || entries.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 22.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -math.pi / 2;
    const gapAngle = 0.04; // rad (~2.3 degrees)

    for (final entry in entries) {
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      final effectiveSweep = sweepAngle > gapAngle ? sweepAngle - gapAngle : sweepAngle;
      final isSelected = entry.key == selectedCategory;

      final paint = Paint()
        ..color = entry.key.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidth + 6 : strokeWidth
        ..strokeCap = StrokeCap.round;

      if (effectiveSweep > 0.01) {
        final drawRect = isSelected
            ? Rect.fromCircle(center: center, radius: radius + 2)
            : rect;
        canvas.drawArc(drawRect, startAngle + (gapAngle / 2), effectiveSweep, false, paint);
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.entries != entries;
  }
}

class _EmptyDonutPainter extends CustomPainter {
  final Color trackColor;
  _EmptyDonutPainter({required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    final paint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _EmptyDonutPainter oldDelegate) => false;
}
