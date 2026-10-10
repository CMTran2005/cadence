import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/app_data_notifier.dart';
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
    AppDataNotifier.instance.addListener(_loadDashboardData);
    SettingsService.instance.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppDataNotifier.instance.removeListener(_loadDashboardData);
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final safe = await DatabaseHelper.instance.calculateSafeToSpendToday();
    final income = await DatabaseHelper.instance.getCurrentMonthIncome();
    final expense = await DatabaseHelper.instance.getCurrentMonthExpense();
    final fixed = await DatabaseHelper.instance.getMonthlySubscriptionTotal();
    final allSubs = await DatabaseHelper.instance.getActiveSubscriptions();
    final recent = await DatabaseHelper.instance.getAllTransactions(limit: 6);

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
    await ManualEntryScreen.navigateTo(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = SettingsService.instance.themeBackground;

    return Scaffold(
      backgroundColor: currentTheme.background,
      appBar: AppBar(
        backgroundColor: currentTheme.background,
        title: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: 10),
            Text(tr('app_name')),
          ],
        ),
        actions: [
          // Streamlined: only Settings action in Dashboard AppBar.
          IconButton(
            onPressed: () => SettingsScreen.navigateTo(context),
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            tooltip: tr('settings_title'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppColors.textPrimary,
              backgroundColor: currentTheme.surface,
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

                  // Dedicated Primary Action Buttons (Quét hóa đơn OCR vs Nhập tay)
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: _openCameraScanner,
                          icon: const Icon(Icons.document_scanner_rounded, size: 18),
                          label: Text(
                            tr('scan_receipt_ocr'),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
                          label: Text(
                            tr('manual_entry_btn'),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(color: currentTheme.border),
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
                      Text(
                        tr('recent_transactions'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onNavigateToTransactions,
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        child: Text(tr('view_all'), style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_recentTx.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      alignment: Alignment.center,
                      child: Text(
                        tr('no_transactions'),
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
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
                          },
                          onEdit: () async {
                            await ManualEntryScreen.navigateTo(context, existingItem: tx);
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
