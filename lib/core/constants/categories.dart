import 'package:flutter/material.dart';

enum TransactionType {
  expense,
  income;

  String get id => name.toUpperCase();
  String get displayName => this == expense ? 'Chi tiêu' : 'Thu nhập';
}

enum CategoryType {
  // Expenses
  food,
  shopping,
  transport,
  bills,
  subscriptions,
  entertainment,
  health,
  education,
  // Income
  salary,
  freelance,
  investment,
  gift,
  other;

  String get id => name;

  String get displayName {
    switch (this) {
      case CategoryType.food:
        return 'Ăn uống';
      case CategoryType.shopping:
        return 'Mua sắm';
      case CategoryType.transport:
        return 'Di chuyển';
      case CategoryType.bills:
        return 'Hóa đơn & Tiện ích';
      case CategoryType.subscriptions:
        return 'Dịch vụ định kỳ';
      case CategoryType.entertainment:
        return 'Giải trí';
      case CategoryType.health:
        return 'Y tế & Sức khỏe';
      case CategoryType.education:
        return 'Học tập & Sách';
      case CategoryType.salary:
        return 'Lương';
      case CategoryType.freelance:
        return 'Việc làm thêm';
      case CategoryType.investment:
        return 'Đầu tư / Tiết kiệm';
      case CategoryType.gift:
        return 'Thưởng / Quà tặng';
      case CategoryType.other:
        return 'Khác';
    }
  }

  IconData get icon {
    switch (this) {
      case CategoryType.food:
        return Icons.restaurant_rounded;
      case CategoryType.shopping:
        return Icons.shopping_bag_outlined;
      case CategoryType.transport:
        return Icons.directions_car_outlined;
      case CategoryType.bills:
        return Icons.receipt_long_outlined;
      case CategoryType.subscriptions:
        return Icons.repeat_rounded;
      case CategoryType.entertainment:
        return Icons.sports_esports_outlined;
      case CategoryType.health:
        return Icons.favorite_border_rounded;
      case CategoryType.education:
        return Icons.menu_book_outlined;
      case CategoryType.salary:
        return Icons.payments_outlined;
      case CategoryType.freelance:
        return Icons.laptop_chromebook_outlined;
      case CategoryType.investment:
        return Icons.trending_up_rounded;
      case CategoryType.gift:
        return Icons.card_giftcard_rounded;
      case CategoryType.other:
        return Icons.grid_view_rounded;
    }
  }

  Color get color {
    switch (this) {
      case CategoryType.food:
        return const Color(0xFFF59E0B); // Amber
      case CategoryType.shopping:
        return const Color(0xFFEC4899); // Pink
      case CategoryType.transport:
        return const Color(0xFF06B6D4); // Cyan
      case CategoryType.bills:
        return const Color(0xFFEF4444); // Red
      case CategoryType.subscriptions:
        return const Color(0xFF8B5CF6); // Purple
      case CategoryType.entertainment:
        return const Color(0xFFF97316); // Orange
      case CategoryType.health:
        return const Color(0xFF10B981); // Emerald
      case CategoryType.education:
        return const Color(0xFF3B82F6); // Blue
      case CategoryType.salary:
        return const Color(0xFF10B981); // Emerald
      case CategoryType.freelance:
        return const Color(0xFF6366F1); // Indigo
      case CategoryType.investment:
        return const Color(0xFF14B8A6); // Teal
      case CategoryType.gift:
        return const Color(0xFFA855F7); // Violet
      case CategoryType.other:
        return const Color(0xFF94A3B8); // Slate
    }
  }

  static CategoryType fromString(String? value) {
    if (value == null) return CategoryType.other;
    for (final cat in CategoryType.values) {
      if (cat.name.toLowerCase() == value.toLowerCase() ||
          cat.displayName.toLowerCase() == value.toLowerCase()) {
        return cat;
      }
    }
    return CategoryType.other;
  }
}
