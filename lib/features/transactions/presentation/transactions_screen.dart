import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/database/database_helper.dart';
import '../../scanner/presentation/camera_scanner_screen.dart';
import '../models/transaction_item.dart';
import 'widgets/quick_manual_entry_sheet.dart';
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

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final items = await DatabaseHelper.instance.getAllTransactions(
      type: _selectedTypeFilter,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
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
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sổ Giao Dịch'),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CameraScannerScreen()),
              );
              if (result == true) _loadTransactions();
            },
            icon: const Icon(Icons.document_scanner_outlined, color: AppColors.textPrimary),
          ),
          IconButton(
            onPressed: () async {
              final added = await QuickManualEntrySheet.show(context);
              if (added == true) _loadTransactions();
            },
            icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên cửa hàng, ghi chú...',
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
                      label: 'Tất cả',
                      isSelected: _selectedTypeFilter == null,
                      onTap: () {
                        setState(() => _selectedTypeFilter = null);
                        _loadTransactions();
                      },
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Chi tiêu',
                      isSelected: _selectedTypeFilter == TransactionType.expense,
                      color: AppColors.expense,
                      onTap: () {
                        setState(() => _selectedTypeFilter = TransactionType.expense);
                        _loadTransactions();
                      },
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Thu nhập',
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
          const SizedBox(height: 8),

          // Transaction List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTransactions,
                    color: AppColors.textPrimary,
                    backgroundColor: AppColors.surface,
                    child: _transactions.isEmpty
                        ? ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 60),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textTertiary),
                                      SizedBox(height: 12),
                                      Text(
                                        'Không tìm thấy giao dịch nào',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                              );
                            },
                          ),
                  ),
          ),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor.withOpacity(0.4) : AppColors.border,
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
