import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/settings_service.dart';

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
            title: Text(tr('settings_title')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // SECTION 1: GIAO DIỆN & NỀN (Vòng tròn màu tinh gọn)
              _buildSectionHeader(
                title: tr('appearance_theme'),
                subtitle: tr('appearance_subtitle'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: currentTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: currentTheme.border),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceAround,
                  children: AppThemeBackground.values.map((bg) {
                    final isSelected = bg == currentTheme;
                    return GestureDetector(
                      onTap: () => settings.setThemeBackground(bg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [bg.background, bg.surfaceElevated],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: isSelected ? Colors.white : bg.border,
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.2),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: bg.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: bg.border),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bg.label,
                            style: TextStyle(
                              color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 28),

              // SECTION 2: ĐƠN VỊ TIỀN TỆ
              _buildSectionHeader(
                title: tr('display_currency'),
                subtitle: tr('currency_subtitle'),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                title: tr('language'),
                subtitle: tr('language_subtitle'),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.income.withOpacity(0.15) : currentTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isSelected ? AppColors.income.withOpacity(0.3) : currentTheme.border),
                              ),
                              child: Text(
                                lang.shortCode,
                                style: TextStyle(
                                  color: isSelected ? AppColors.income : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
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

              // SECTION 4: HỆ THỐNG & DỮ LIỆU
              _buildSectionHeader(
                title: tr('system_data'),
                subtitle: tr('system_subtitle'),
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
                    _buildInfoRow(tr('version'), '1.1.4 (Clean & Optimized)'),
                    const Divider(height: 24),
                    _buildInfoRow(tr('architecture'), tr('architecture_value')),
                    const Divider(height: 24),
                    _buildInfoRow(tr('ocr_engine'), tr('ocr_engine_value')),
                    const Divider(height: 24),
                    _buildInfoRow(tr('database_type'), tr('database_value')),
                    const Divider(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmResetData(context),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 17, color: AppColors.expense),
                        label: Text(tr('clear_all_data'), style: const TextStyle(color: AppColors.expense, fontSize: 13)),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
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
        title: Text(tr('clear_confirm_title'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text(
          tr('clear_confirm_desc'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('cancel'), style: const TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await DatabaseHelper.instance.clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr('clear_success')),
                    backgroundColor: AppColors.income,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
  }
}
