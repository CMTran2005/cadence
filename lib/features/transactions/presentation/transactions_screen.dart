import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/app_data_notifier.dart';
import '../../../core/services/settings_service.dart';
import '../../scanner/presentation/camera_scanner_screen.dart';
import '../models/transaction_item.dart';
import 'manual_entry_screen.dart';
import 'widgets/transaction_card.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<TransactionItem> _transactions = [];
  TransactionType? _selectedTypeFilter;
  String _searchQuery = '';
  bool _isLoading = true;

  DateTime? _selectedTimelineMonth;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedTimelineMonth = DateTime(now.year, now.month, 1);
    _loadTransactions();

    // Listen to real-time data changes across the entire app
    AppDataNotifier.instance.addListener(_loadTransactions);
    SettingsService.instance.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppDataNotifier.instance.removeListener(_loadTransactions);
    SettingsService.instance.removeListener(_onSettingsChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    DateTime? startDate;
    DateTime? endDate;

    if (_selectedTimelineMonth != null) {
      final y = _selectedTimelineMonth!.year;
      final m = _selectedTimelineMonth!.month;
      startDate = DateTime(y, m, 1);
      endDate = DateTime(y, m + 1, 0, 23, 59, 59, 999);
    }

    final items = await DatabaseHelper.instance.getAllTransactions(
      type: _selectedTypeFilter,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      startDate: startDate,
      endDate: endDate,
    );

    if (mounted) {
      setState(() {
        _transactions = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTx(TransactionItem item) async {
    await DatabaseHelper.instance.deleteTransaction(item.id!);
  }

  Future<void> _editTx(TransactionItem item) async {
    await ManualEntryScreen.navigateTo(context, existingItem: item);
  }

  void _previousMonth() {
    HapticFeedback.selectionClick();
    if (_selectedTimelineMonth == null) {
      final now = DateTime.now();
      _selectedTimelineMonth = DateTime(now.year, now.month - 1, 1);
    } else {
      _selectedTimelineMonth = DateTime(
        _selectedTimelineMonth!.year,
        _selectedTimelineMonth!.month - 1,
        1,
      );
    }
    _loadTransactions();
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    if (_selectedTimelineMonth == null) {
      final now = DateTime.now();
      _selectedTimelineMonth = DateTime(now.year, now.month + 1, 1);
    } else {
      _selectedTimelineMonth = DateTime(
        _selectedTimelineMonth!.year,
        _selectedTimelineMonth!.month + 1,
        1,
      );
    }
    _loadTransactions();
  }

  void _showMonthYearPicker() async {
    final now = DateTime.now();
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
                      tr('transaction_date'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() => _selectedTimelineMonth = null);
                        _loadTransactions();
                      },
                      child: Text(tr('view_all'), style: const TextStyle(color: AppColors.income)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
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
                      final targetYear = _selectedTimelineMonth?.year ?? now.year;
                      final isSelected = _selectedTimelineMonth != null &&
                          _selectedTimelineMonth!.year == targetYear &&
                          _selectedTimelineMonth!.month == m;

                      return InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          setState(() => _selectedTimelineMonth = DateTime(targetYear, m, 1));
                          _loadTransactions();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.income : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : AppColors.border,
                            ),
                          ),
                          child: Text(
                            'T$m',
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
                if (availableYears.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: availableYears.map((yr) {
                      final isYrSelected = (_selectedTimelineMonth?.year ?? now.year) == yr;
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
                            final m = _selectedTimelineMonth?.month ?? now.month;
                            setState(() => _selectedTimelineMonth = DateTime(yr, m, 1));
                            _loadTransactions();
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
    final currentTheme = SettingsService.instance.themeBackground;

    return Scaffold(
      backgroundColor: currentTheme.background,
      appBar: AppBar(
        backgroundColor: currentTheme.background,
        title: Text(tr('tab_transactions')),
        actions: [
          // Streamlined: only the scanner action is in AppBar. The + button is the FAB.
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CameraScannerScreen()),
              );
            },
            icon: const Icon(Icons.document_scanner_outlined, color: AppColors.textPrimary),
            tooltip: tr('scan_receipt'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Timeline Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                // Timeline Month Navigator Strip
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
                        onPressed: _previousMonth,
                        visualDensity: VisualDensity.compact,
                      ),
                      GestureDetector(
                        onTap: _showMonthYearPicker,
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.textTertiary),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTimelineMonth == null
                                  ? tr('all')
                                  : '${_selectedTimelineMonth!.month}/${_selectedTimelineMonth!.year}',
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
                        onPressed: _nextMonth,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Search Input
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: tr('search_hint'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textTertiary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textTertiary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadTransactions();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                    _loadTransactions();
                  },
                ),

                const SizedBox(height: 10),

                // Filter Chips (All, Expense, Income)
                Row(
                  children: [
                    _filterChip(
                      label: '${tr('all')} (${_transactions.length})',
                      isSelected: _selectedTypeFilter == null,
                      onTap: () {
                        setState(() => _selectedTypeFilter = null);
                        _loadTransactions();
                      },
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: tr('expense'),
                      isSelected: _selectedTypeFilter == TransactionType.expense,
                      color: AppColors.expense,
                      onTap: () {
                        setState(() => _selectedTypeFilter = TransactionType.expense);
                        _loadTransactions();
                      },
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: tr('income'),
                      isSelected: _selectedTypeFilter == TransactionType.income,
                      color: AppColors.income,
                      onTap: () {
                        setState(() => _selectedTypeFilter = TransactionType.income);
                        _loadTransactions();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Transaction List with swipe left to delete and swipe right to edit
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTransactions,
                    color: AppColors.textPrimary,
                    backgroundColor: currentTheme.surface,
                    child: _transactions.isEmpty
                        ? ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 60),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textTertiary),
                                      const SizedBox(height: 12),
                                      Text(
                                        tr('no_transactions'),
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                      ),
                                      const SizedBox(height: 16),
                                      OutlinedButton.icon(
                                        onPressed: () => ManualEntryScreen.navigateTo(context),
                                        icon: const Icon(Icons.add_rounded, size: 16),
                                        label: Text(tr('add_first_transaction')),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.textPrimary,
                                          side: BorderSide(color: currentTheme.border),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _transactions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _transactions[index];
                              return TransactionCard(
                                item: item,
                                onDelete: () => _deleteTx(item),
                                onEdit: () => _editTx(item),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      // Single unified Add Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          ManualEntryScreen.navigateTo(context);
        },
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.background,
        elevation: 2,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final activeColor = color ?? AppColors.textPrimary;
    final currentTheme = SettingsService.instance.themeBackground;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : currentTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor.withOpacity(0.4) : currentTheme.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
