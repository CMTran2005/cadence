import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _ddMMyyyy = DateFormat('dd/MM/yyyy');
  static final DateFormat _ddMM = DateFormat('dd/MM');
  static final DateFormat _hhmm = DateFormat('HH:mm');

  static String formatDate(DateTime date) => _ddMMyyyy.format(date);
  static String formatShortDate(DateTime date) => _ddMM.format(date);
  static String formatTime(DateTime date) => _hhmm.format(date);
  static String formatVietnameseDate(DateTime date) => 'Ngày ${date.day}/${date.month}/${date.year}';

  /// Friendly relative date: "Hôm nay", "Hôm qua", "2 ngày trước", "dd/MM"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    if (diff == -1) return 'Ngày mai';
    if (diff > 1 && diff <= 7) return '$diff ngày trước';
    if (diff < -1 && diff >= -7) return 'Sau ${-diff} ngày';

    return _ddMMyyyy.format(date);
  }

  /// Format billing countdown: "Hôm nay", "Còn 2 ngày", "Quá hạn 1 ngày"
  static String formatDaysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays == 0) return 'Đến hạn hôm nay';
    if (diffDays == 1) return 'Còn 1 ngày';
    if (diffDays > 1) return 'Còn $diffDays ngày';
    if (diffDays == -1) return 'Quá hạn 1 ngày';
    return 'Quá hạn ${-diffDays} ngày';
  }
}
