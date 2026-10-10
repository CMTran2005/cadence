import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

enum AppLanguage {
  vi('vi', 'Tiếng Việt', '🇻🇳'),
  en('en', 'English', '🇬🇧');

  final String code;
  final String label;
  final String flag;
  const AppLanguage(this.code, this.label, this.flag);

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.vi,
    );
  }
}

enum AppCurrency {
  vnd('VND', '₫', 'vi_VN', 0, 'Việt Nam Đồng'),
  usd('USD', '\$', 'en_US', 2, 'US Dollar'),
  eur('EUR', '€', 'de_DE', 2, 'Euro'),
  jpy('JPY', '¥', 'ja_JP', 0, 'Japanese Yen');

  final String code;
  final String symbol;
  final String locale;
  final int decimalDigits;
  final String name;
  const AppCurrency(this.code, this.symbol, this.locale, this.decimalDigits, this.name);

  static AppCurrency fromCode(String? code) {
    return AppCurrency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => AppCurrency.vnd,
    );
  }
}

enum AppThemeBackground {
  zinc('zinc', 'Dark Zinc', 'Nền Zinc 950 cân bằng, chuẩn Taste-Skill', Color(0xFF09090B), Color(0xFF121215), Color(0xFF18181B), Color(0xFF27272A)),
  oled('oled', 'OLED Pure Black', 'Đen tuyệt đối #000000, tiết kiệm pin tối đa', Color(0xFF000000), Color(0xFF0C0C0C), Color(0xFF161616), Color(0xFF222222)),
  slate('slate', 'Midnight Slate', 'Xanh đen nửa đêm sâu thẳm, hiện đại', Color(0xFF0A0F1D), Color(0xFF111827), Color(0xFF1E293B), Color(0xFF2E3D52)),
  charcoal('charcoal', 'Warm Charcoal', 'Than chì ấm áp, giảm mỏi mắt', Color(0xFF121214), Color(0xFF1A1A1E), Color(0xFF242429), Color(0xFF2F2F37));

  final String keyName;
  final String label;
  final String description;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;

  const AppThemeBackground(
    this.keyName,
    this.label,
    this.description,
    this.background,
    this.surface,
    this.surfaceElevated,
    this.border,
  );

  static AppThemeBackground fromKey(String? key) {
    return AppThemeBackground.values.firstWhere(
      (t) => t.keyName == key,
      orElse: () => AppThemeBackground.zinc,
    );
  }
}

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  AppLanguage _language = AppLanguage.vi;
  AppCurrency _currency = AppCurrency.vnd;
  AppThemeBackground _themeBackground = AppThemeBackground.zinc;
  bool _isInitialized = false;

  AppLanguage get language => _language;
  AppCurrency get currency => _currency;
  AppThemeBackground get themeBackground => _themeBackground;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    try {
      final langKey = await DatabaseHelper.instance.getSetting('app_language', defaultValue: 'vi');
      final currKey = await DatabaseHelper.instance.getSetting('app_currency', defaultValue: 'VND');
      final bgKey = await DatabaseHelper.instance.getSetting('app_theme_bg', defaultValue: 'zinc');

      _language = AppLanguage.fromCode(langKey);
      _currency = AppCurrency.fromCode(currKey);
      _themeBackground = AppThemeBackground.fromKey(bgKey);
      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      _isInitialized = true;
    }
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    await DatabaseHelper.instance.setSetting('app_language', lang.code);
  }

  Future<void> setCurrency(AppCurrency curr) async {
    if (_currency == curr) return;
    _currency = curr;
    notifyListeners();
    await DatabaseHelper.instance.setSetting('app_currency', curr.code);
  }

  Future<void> setThemeBackground(AppThemeBackground bg) async {
    if (_themeBackground == bg) return;
    _themeBackground = bg;
    notifyListeners();
    await DatabaseHelper.instance.setSetting('app_theme_bg', bg.keyName);
  }

  // --- Dynamic Currency Formatting ---

  String formatCurrency(double amount) {
    try {
      final fmt = NumberFormat.currency(
        locale: _currency.locale,
        symbol: _currency.symbol,
        decimalDigits: _currency.decimalDigits,
      );
      return fmt.format(amount).trim();
    } catch (_) {
      return '${amount.toStringAsFixed(_currency.decimalDigits)} ${_currency.symbol}';
    }
  }

  String formatSignedCurrency(double amount, {required bool isIncome}) {
    final formatted = formatCurrency(amount.abs());
    return isIncome ? '+$formatted' : '-$formatted';
  }

  String formatCompactCurrency(double amount) {
    try {
      final fmt = NumberFormat.compactCurrency(
        locale: _currency.locale,
        symbol: _currency.symbol,
        decimalDigits: 1,
      );
      return fmt.format(amount).trim();
    } catch (_) {
      return formatCurrency(amount);
    }
  }
}
