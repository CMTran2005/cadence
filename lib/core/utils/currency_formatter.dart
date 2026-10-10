import 'package:intl/intl.dart';
import '../services/settings_service.dart';

class CurrencyFormatter {
  static final NumberFormat _defaultVndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _defaultCompactFormat = NumberFormat.compactCurrency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 1,
  );

  /// Format double to active currency setting (defaults to VND if settings uninitialized)
  static String format(double amount) {
    if (SettingsService.instance.isInitialized) {
      return SettingsService.instance.formatCurrency(amount);
    }
    return _defaultVndFormat.format(amount).trim();
  }

  /// Format double to Vietnamese currency format: "150.000 ₫"
  static String formatVND(double amount) {
    return format(amount);
  }

  /// Compact format for dashboard badges: "150K ₫" or "1.5M ₫"
  static String formatCompact(double amount) {
    if (SettingsService.instance.isInitialized) {
      return SettingsService.instance.formatCompactCurrency(amount);
    }
    return _defaultCompactFormat.format(amount).trim();
  }

  /// Format double with sign: "+15.000.000 ₫" or "-45.000 ₫"
  static String formatSignedVND(double amount, {required bool isIncome}) {
    if (SettingsService.instance.isInitialized) {
      return SettingsService.instance.formatSignedCurrency(amount, isIncome: isIncome);
    }
    final formatted = formatVND(amount.abs());
    return isIncome ? '+$formatted' : '-$formatted';
  }

  /// Parse currency strings with mixed separators (., space, symbols) into a double
  static double parseAmount(String raw) {
    if (raw.trim().isEmpty) return 0.0;

    String cleaned = raw
        .replaceAll(RegExp(r'[VNDvndVNĐvnđ₫đ$€¥\s]'), '')
        .trim();

    if (cleaned.contains('.') && cleaned.contains(',')) {
      final lastDot = cleaned.lastIndexOf('.');
      final lastComma = cleaned.lastIndexOf(',');
      if (lastDot > lastComma) {
        cleaned = cleaned.replaceAll(',', '');
      } else {
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        cleaned = cleaned.replaceAll('.', '');
      }
    } else if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        cleaned = cleaned.replaceAll(',', '');
      } else {
        cleaned = cleaned.replaceAll(',', '.');
      }
    }

    return double.tryParse(cleaned) ?? 0.0;
  }
}
