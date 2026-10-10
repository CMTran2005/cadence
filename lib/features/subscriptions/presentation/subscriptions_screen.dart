import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/currency_formatter.dart';
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
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
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
    // 1. Advance next billing date
    final nextDate = sub.billingCycle == 'YEARLY'
        ? DateTime(sub.nextBillingDate.year + 1, sub.nextBillingDate.month, sub.nextBillingDate.day)
        : DateTime(sub.nextBillingDate.year, sub.nextBillingDate.month + 1, sub.nextBillingDate.day);

    await DatabaseHelper.instance.updateSubscription(
      sub.copyWith(nextBillingDate: nextDate),
    );

    // 2. Insert expense transaction record
    final tx = TransactionItem(
      title: 'Gia hạn: ${sub.name}',
      amount: sub.amount,
      type: TransactionType.expense,
      category: sub.category,
      transactionDate: DateTime.now(),
      source: 'MANUAL',
      notes: 'Thanh toán định kỳ ${sub.billingCycle.toLowerCase()}',
    );
    await DatabaseHelper.instance.insertTransaction(tx);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã ghi nhận thanh toán & chuyển kỳ tới sang ${nextDate.day}/${nextDate.month}'),
          backgroundColor: AppColors.income,
        ),
      );
    }
    _loadData();
  }

  Future<void> _toggleActive(SubscriptionItem sub, bool active) async {
    await DatabaseHelper.instance.toggleSubscriptionActive(sub.id!, active);
    _loadData();
  }

  Future<void> _deleteSub(SubscriptionItem sub) async {
    await DatabaseHelper.instance.deleteSubscription(sub.id!);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gói Dịch Vụ Định Kỳ'),
        actions: [
          IconButton(
            onPressed: () async {
              final added = await AddSubscriptionSheet.show(context);
              if (added == true) _loadData();
            },
            icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.textPrimary,
              backgroundColor: AppColors.surface,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Monthly Fixed Costs Banner
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
                        const Row(
                          children: [
                            Icon(Icons.repeat_rounded, size: 16, color: AppColors.accent),
                            SizedBox(width: 8),
                            Text(
                              'Chi phí cố định định kỳ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          CurrencyFormatter.formatVND(_monthlyTotal),
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
                          'Ước tính tiêu tốn ~${CurrencyFormatter.formatVND(_monthlyTotal * 12)} / năm',
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subscriptions list header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Danh sách dịch vụ (${_subscriptions.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final added = await AddSubscriptionSheet.show(context);
                          if (added == true) _loadData();
                        },
                        icon: const Icon(Icons.add, size: 14, color: AppColors.textSecondary),
                        label: const Text('Thêm mới', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_subscriptions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(Icons.subscriptions_outlined, size: 40, color: AppColors.textTertiary),
                          SizedBox(height: 12),
                          Text(
                            'Chưa có dịch vụ định kỳ nào',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Bấm nút "+" để thêm Netflix, iCloud, tiền trọ, 4G...',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
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
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
