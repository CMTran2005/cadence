import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../subscriptions/models/subscription_item.dart';

class UpcomingBillsStrip extends StatelessWidget {
  final List<SubscriptionItem> upcomingSubs;
  final VoidCallback onViewAll;

  const UpcomingBillsStrip({
    super.key,
    required this.upcomingSubs,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (upcomingSubs.isEmpty) return const SizedBox.shrink();
    final currentTheme = SettingsService.instance.themeBackground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  tr('upcoming_bills'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Text(tr('view_all'), style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: upcomingSubs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final sub = upcomingSubs[index];
              return Container(
                width: 170,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: currentTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sub.isDueSoon ? AppColors.warning.withOpacity(0.4) : currentTheme.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(sub.category.icon, size: 14, color: sub.category.color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sub.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      SettingsService.instance.formatCurrency(sub.amount),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: currentTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sub.daysUntilDue <= 0
                            ? tr('due_today')
                            : tr('days_remaining', {'days': '${sub.daysUntilDue}'}),
                        style: TextStyle(
                          color: sub.isDueSoon ? AppColors.warning : AppColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
