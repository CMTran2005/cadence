import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../localization/app_localizations.dart';

enum AppLanguage {
  vi('vi', 'Tiếng Việt', 'VI'),
  en('en', 'English', 'EN'),
  fr('fr', 'Français', 'FR'),
  ja('ja', '日本語', 'JA'),
  zh('zh', '简体中文', 'ZH');

  final String code;
  final String label;
  final String shortCode;
  const AppLanguage(this.code, this.label, this.shortCode);

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
  jpy('JPY', '¥', 'ja_JP', 0, 'Japanese Yen'),
  gbp('GBP', '£', 'en_GB', 2, 'British Pound'),
  krw('KRW', '₩', 'ko_KR', 0, 'Korean Won'),
  sgd('SGD', 'S\$', 'en_SG', 2, 'Singapore Dollar');

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
  zinc('zinc', 'Zinc', Color(0xFF09090B), Color(0xFF121215), Color(0xFF18181B), Color(0xFF27272A)),
  oled('oled', 'OLED', Color(0xFF000000), Color(0xFF0C0C0C), Color(0xFF161616), Color(0xFF222222)),
  slate('slate', 'Slate', Color(0xFF0A0F1D), Color(0xFF111827), Color(0xFF1E293B), Color(0xFF2E3D52)),
  charcoal('charcoal', 'Charcoal', Color(0xFF141416), Color(0xFF1C1C1F), Color(0xFF26262B), Color(0xFF33333A)),
  emerald('emerald', 'Forest', Color(0xFF06120B), Color(0xFF0D1C13), Color(0xFF14291D), Color(0xFF1C3B2A)),
  violet('violet', 'Obsidian', Color(0xFF0E0919), Color(0xFF161026), Color(0xFF211938), Color(0xFF322654)),
  crimson('crimson', 'Crimson', Color(0xFF14080B), Color(0xFF1D0E12), Color(0xFF29151A), Color(0xFF3D1E26)),
  nord('nord', 'Arctic', Color(0xFF0F141C), Color(0xFF161E2A), Color(0xFF202B3C), Color(0xFF2F3E55));

  final String keyName;
  final String label;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;

  const AppThemeBackground(
    this.keyName,
    this.label,
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

  String tr(String key, [Map<String, String>? params]) {
    return AppLocalizations.get(key, _language.code, params);
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
        decimalDigits: _currency.decimalDigits > 0 ? 1 : 0,
      );
      return fmt.format(amount).trim();
    } catch (_) {
      return formatCurrency(amount);
    }
  }
}
