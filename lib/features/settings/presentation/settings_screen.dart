import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/settings_service.dart';
import '../../transactions/models/transaction_item.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static Future<void> navigateTo(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final currentTheme = settings.themeBackground;
        final currentLang = settings.language;
        final currentCurr = settings.currency;

        return Scaffold(
          backgroundColor: currentTheme.background,
          appBar: AppBar(
            backgroundColor: currentTheme.background,
            title: const Text('Cài Đặt & Tùy Chọn'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // SECTION 1: GIAO DIỆN & NỀN
              _buildSectionHeader(
                title: 'GIAO DIỆN & MÀU NỀN',
                subtitle: 'Tối ưu cho hiển thị sắc nét, không chói mắt',
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: currentTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: currentTheme.border),
                ),
                child: Column(
                  children: AppThemeBackground.values.map((bg) {
                    final isSelected = bg == currentTheme;
                    return InkWell(
                      onTap: () => settings.setThemeBackground(bg),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: bg.background,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 2),
                              ),
                              child: Center(
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: bg.surfaceElevated,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bg.label,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    bg.description,
                                    style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 20)
                            else
                              const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textTertiary, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 28),

              // SECTION 2: ĐƠN VỊ TIỀN TỆ
              _buildSectionHeader(
                title: 'TIỀN TỆ HIỂN THỊ',
                subtitle: 'Quy đổi cách trình bày số tiền trên toàn bộ ứng dụng',
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: currentTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: currentTheme.border),
                ),
                child: Column(
                  children: AppCurrency.values.map((curr) {
                    final isSelected = curr == currentCurr;
                    return InkWell(
                      onTap: () => settings.setCurrency(curr),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: currentTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: currentTheme.border),
                              ),
                              child: Text(
                                curr.symbol,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${curr.code} (${curr.symbol})',
                                    style: TextStyle(
                                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    curr.name,
                                    style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 20)
                            else
                              const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textTertiary, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 28),

              // SECTION 3: NGÔN NGỮ
              _buildSectionHeader(
                title: 'NGÔN NGỮ (LANGUAGE)',
                subtitle: 'Chọn ngôn ngữ giao diện ưa thích',
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: currentTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: currentTheme.border),
                ),
                child: Column(
                  children: AppLanguage.values.map((lang) {
                    final isSelected = lang == currentLang;
                    return InkWell(
                      onTap: () => settings.setLanguage(lang),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Text(lang.flag, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                lang.label,
                                style: TextStyle(
                                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 20)
                            else
                              const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textTertiary, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 28),

              // SECTION 4: THÔNG TIN ỨNG DỤNG & DỮ LIỆU
              _buildSectionHeader(
                title: 'HỆ THỐNG & DỮ LIỆU',
                subtitle: 'Offline-First • Không gửi dữ liệu tài chính ra ngoài',
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: currentTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: currentTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Phiên bản', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('1.1.0 (Taste-Skill Release)', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Động cơ OCR', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('Google ML Kit On-Device', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const Divider(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cơ sở dữ liệu', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('SQLite Local-First Storage', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const Divider(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmResetData(context),
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.expense),
                        label: const Text('Đặt lại dữ liệu ban đầu', style: TextStyle(color: AppColors.expense, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _confirmResetData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xác nhận đặt lại?', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
        content: const Text(
          'Hành động này sẽ xóa các giao dịch hiện tại và khôi phục dữ liệu mẫu ban đầu để bạn thử nghiệm.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final db = await DatabaseHelper.instance.database;
              await db.delete(DatabaseHelper.tableTransactions);
              await db.delete(DatabaseHelper.tableSubscriptions);
              await DatabaseHelper.instance.database; // Re-triggers or we can seed
              // Reload seed
              final helper = DatabaseHelper.instance;
              // Add a test seed transaction
              final now = DateTime.now();
              await helper.insertTransaction(
                TransactionItem(
                  title: 'Lương tháng ${now.month}',
                  amount: 20000000,
                  type: TransactionType.income,
                  category: CategoryType.salary,
                  transactionDate: DateTime(now.year, now.month, 1),
                  source: 'MANUAL',
                ),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã khôi phục dữ liệu mẫu!'),
                    backgroundColor: AppColors.income,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );
  }
}
