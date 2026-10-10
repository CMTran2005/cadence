import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/app_data_notifier.dart';
import '../../../core/services/settings_service.dart';
import '../../transactions/models/transaction_item.dart';
import '../models/subscription_item.dart';
import 'widgets/subscription_card.dart';
import 'widgets/add_subscription_sheet.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List<SubscriptionItem> _subscriptions = [];
  double _monthlyTotal = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    AppDataNotifier.instance.addListener(_loadData);
    SettingsService.instance.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppDataNotifier.instance.removeListener(_loadData);
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  Future<void> _loadData() async {
    final subs = await DatabaseHelper.instance.getAllSubscriptions();
    final monthlyTotal = await DatabaseHelper.instance.getMonthlySubscriptionTotal();

    if (mounted) {
      setState(() {
        _subscriptions = subs;
        _monthlyTotal = monthlyTotal;
        _isLoading = false;
      });
    }
  }

  Future<void> _markPaid(SubscriptionItem sub) async {
    final nextDate = sub.billingCycle == 'YEARLY'
        ? DateTime(sub.nextBillingDate.year + 1, sub.nextBillingDate.month, sub.nextBillingDate.day)
        : DateTime(sub.nextBillingDate.year, sub.nextBillingDate.month + 1, sub.nextBillingDate.day);

    await DatabaseHelper.instance.updateSubscription(
      sub.copyWith(nextBillingDate: nextDate),
    );

    final tx = TransactionItem(
      title: sub.name,
      amount: sub.amount,
      type: TransactionType.expense,
      category: sub.category,
      transactionDate: DateTime.now(),
      source: 'MANUAL',
      notes: sub.billingCycle.toLowerCase(),
    );
    await DatabaseHelper.instance.insertTransaction(tx);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('paid_success', {'date': '${nextDate.day}/${nextDate.month}'})),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }

  Future<void> _toggleActive(SubscriptionItem sub, bool active) async {
    await DatabaseHelper.instance.toggleSubscriptionActive(sub.id!, active);
  }

  Future<void> _deleteSub(SubscriptionItem sub) async {
    await DatabaseHelper.instance.deleteSubscription(sub.id!);
  }

  Future<void> _editSub(SubscriptionItem sub) async {
    await AddSubscriptionSheet.show(context, existingSub: sub);
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = SettingsService.instance.themeBackground;

    return Scaffold(
      backgroundColor: currentTheme.background,
      appBar: AppBar(
        backgroundColor: currentTheme.background,
        title: Text(tr('subscriptions_title')),
        actions: [
          // Streamlined: Single add button in the AppBar for recurring services
          IconButton(
            onPressed: () async {
              await AddSubscriptionSheet.show(context);
            },
            icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
            tooltip: tr('add_subscription'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.textPrimary,
              backgroundColor: currentTheme.surface,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Monthly Fixed Costs Banner
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
                          children: [
                            const Icon(Icons.repeat_rounded, size: 16, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Text(
                              tr('fixed_costs_monthly'),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          SettingsService.instance.formatCurrency(_monthlyTotal),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.8,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr('estimated_per_year', {
                            'amount': SettingsService.instance.formatCurrency(_monthlyTotal * 12),
                          }),
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subscriptions list header (single label, no duplicate add button)
                  Text(
                    tr('services_list', {'count': '${_subscriptions.length}'}),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_subscriptions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.subscriptions_outlined, size: 40, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text(
                            tr('no_subscriptions'),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('add_subscription_prompt'),
                            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._subscriptions.map((sub) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SubscriptionCard(
                          sub: sub,
                          onMarkPaid: () => _markPaid(sub),
                          onToggleActive: (val) => _toggleActive(sub, val),
                          onDelete: () => _deleteSub(sub),
                          onEdit: () => _editSub(sub),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
