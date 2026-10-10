import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

enum TransactionType {
  expense,
  income;

  String get id => name.toUpperCase();
  String get displayName => this == expense ? tr('expense') : tr('income');
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
  sales,
  other;

  String get id => name;

  String get displayName {
    switch (this) {
      case CategoryType.food:
        return tr('cat_food');
      case CategoryType.shopping:
        return tr('cat_shopping');
      case CategoryType.transport:
        return tr('cat_transport');
      case CategoryType.bills:
        return tr('cat_bills');
      case CategoryType.subscriptions:
        return tr('cat_subscriptions');
      case CategoryType.entertainment:
        return tr('cat_entertainment');
      case CategoryType.health:
        return tr('cat_health');
      case CategoryType.education:
        return tr('cat_education');
      case CategoryType.salary:
        return tr('cat_salary');
      case CategoryType.freelance:
        return tr('cat_freelance');
      case CategoryType.investment:
        return tr('cat_investment');
      case CategoryType.gift:
        return tr('cat_gift');
      case CategoryType.sales:
        return tr('cat_sales');
      case CategoryType.other:
        return tr('cat_other');
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
      case CategoryType.sales:
        return Icons.point_of_sale_rounded;
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
      case CategoryType.sales:
        return const Color(0xFF0284C7); // Sky
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

/// Rich category item supporting both built-in and user-created custom categories
class CategoryItemData {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;
  final bool isCustom;

  const CategoryItemData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isCustom = false,
  });

  String get displayName => isCustom ? name : tr('cat_$id');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCode': icon.codePoint,
      'colorValue': color.value,
      'type': type.id,
      'isCustom': 1,
    };
  }

  factory CategoryItemData.fromMap(Map<String, dynamic> map) {
    return CategoryItemData(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: IconData(map['iconCode'] as int? ?? Icons.grid_view_rounded.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(map['colorValue'] as int? ?? 0xFF94A3B8),
      type: (map['type'] == 'INCOME') ? TransactionType.income : TransactionType.expense,
      isCustom: true,
    );
  }
}
