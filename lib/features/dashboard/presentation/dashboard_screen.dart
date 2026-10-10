import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/settings_service.dart';
import '../../scanner/presentation/camera_scanner_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../subscriptions/models/subscription_item.dart';
import '../../transactions/models/transaction_item.dart';
import '../../transactions/presentation/manual_entry_screen.dart';
import '../../transactions/presentation/widgets/transaction_card.dart';
import 'widgets/safe_to_spend_hero.dart';
import 'widgets/upcoming_bills_strip.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToSubscriptions;
  final VoidCallback onNavigateToTransactions;

  const DashboardScreen({
    super.key,
    required this.onNavigateToSubscriptions,
    required this.onNavigateToTransactions,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _safeToSpend = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpense = 0.0;
  double _fixedSubTotal = 0.0;
  List<SubscriptionItem> _upcomingSubs = [];
  List<TransactionItem> _recentTx = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final safe = await DatabaseHelper.instance.calculateSafeToSpendToday();
    final income = await DatabaseHelper.instance.getCurrentMonthIncome();
    final expense = await DatabaseHelper.instance.getCurrentMonthExpense();
    final fixed = await DatabaseHelper.instance.getMonthlySubscriptionTotal();
    final allSubs = await DatabaseHelper.instance.getActiveSubscriptions();
    final recent = await DatabaseHelper.instance.getAllTransactions(limit: 6);

    // Filter subs due in next 10 days
    final upcoming = allSubs.where((s) => s.daysUntilDue >= -2 && s.daysUntilDue <= 10).toList();

    if (mounted) {
      setState(() {
        _safeToSpend = safe;
        _monthlyIncome = income;
        _monthlyExpense = expense;
        _fixedSubTotal = fixed;
        _upcomingSubs = upcoming;
        _recentTx = recent;
        _isLoading = false;
      });
    }
  }

  Future<void> _openCameraScanner() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CameraScannerScreen()),
    );
    if (result == true) {
      _loadDashboardData();
    } else if (result == 'MANUAL') {
      _openQuickManualEntry();
    }
  }

  Future<void> _openQuickManualEntry() async {
    HapticFeedback.lightImpact();
    final added = await ManualEntryScreen.navigateTo(context);
    if (added == true) {
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = SettingsService.instance.themeBackground;

    return AnimatedBuilder(
      animation: SettingsService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: currentTheme.background,
          appBar: AppBar(
            backgroundColor: currentTheme.background,
            title: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Cadence Finance'),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _openCameraScanner,
                icon: const Icon(Icons.document_scanner_outlined, color: AppColors.textPrimary),
                tooltip: 'Quét hóa đơn',
              ),
              IconButton(
                onPressed: () => SettingsScreen.navigateTo(context),
                icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
                tooltip: 'Cài đặt',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
              color: AppColors.textPrimary,
              backgroundColor: AppColors.surface,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Safe-to-Spend Hero
                  SafeToSpendHero(
                    safeToSpendDaily: _safeToSpend,
                    monthlyIncome: _monthlyIncome,
                    monthlyExpense: _monthlyExpense,
                    fixedSubTotal: _fixedSubTotal,
                  ),
                  const SizedBox(height: 18),

                  // Dual Action Buttons (Quét hóa đơn OCR vs Nhập thủ công)
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: _openCameraScanner,
                          icon: const Icon(Icons.document_scanner_rounded, size: 18),
                          label: const Text(
                            'Quét Hóa Đơn (OCR)',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.textPrimary,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: _openQuickManualEntry,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text(
                            'Nhập Tay',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Upcoming Subscriptions strip
                  if (_upcomingSubs.isNotEmpty) ...[
                    UpcomingBillsStrip(
                      upcomingSubs: _upcomingSubs,
                      onViewAll: widget.onNavigateToSubscriptions,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Giao dịch gần đây',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onNavigateToTransactions,
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        child: const Text('Xem tất cả', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_recentTx.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      alignment: Alignment.center,
                      child: const Text(
                        'Chưa có giao dịch nào',
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                      ),
                    )
                  else
                    ..._recentTx.map((tx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TransactionCard(
                          item: tx,
                          onDelete: () async {
                            await DatabaseHelper.instance.deleteTransaction(tx.id!);
                            _loadDashboardData();
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
        );
      },
    );
  }
}
