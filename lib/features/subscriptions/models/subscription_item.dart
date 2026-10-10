import '../../../core/constants/categories.dart';

class SubscriptionItem {
  final int? id;
  final String name;
  final double amount;
  final String billingCycle; // 'MONTHLY', 'YEARLY', 'WEEKLY'
  final DateTime nextBillingDate;
  final CategoryType category;
  final String? iconName;
  final int reminderDaysBefore;
  final bool isActive;
  final DateTime createdAt;

  SubscriptionItem({
    this.id,
    required this.name,
    required this.amount,
    this.billingCycle = 'MONTHLY',
    required this.nextBillingDate,
    required this.category,
    this.iconName,
    this.reminderDaysBefore = 2,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Normalized monthly cost for comparison
  double get monthlyNormalizedAmount {
    switch (billingCycle) {
      case 'YEARLY':
        return amount / 12.0;
      case 'WEEKLY':
        return amount * 4.33;
      case 'MONTHLY':
      default:
        return amount;
    }
  }

  /// Days left until next payment
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextBillingDate.year, nextBillingDate.month, nextBillingDate.day);
    return target.difference(today).inDays;
  }

  bool get isDueSoon => daysUntilDue >= 0 && daysUntilDue <= 3;
  bool get isOverdue => daysUntilDue < 0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'amount': amount,
      'billingCycle': billingCycle,
      'nextBillingDate': nextBillingDate.millisecondsSinceEpoch,
      'category': category.id,
      'iconName': iconName,
      'reminderDaysBefore': reminderDaysBefore,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SubscriptionItem.fromMap(Map<String, dynamic> map) {
    return SubscriptionItem(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Dịch vụ',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      billingCycle: map['billingCycle'] as String? ?? 'MONTHLY',
      nextBillingDate: DateTime.fromMillisecondsSinceEpoch(
        map['nextBillingDate'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      category: CategoryType.fromString(map['category'] as String?),
      iconName: map['iconName'] as String?,
      reminderDaysBefore: map['reminderDaysBefore'] as int? ?? 2,
      isActive: (map['isActive'] as int? ?? 1) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  SubscriptionItem copyWith({
    int? id,
    String? name,
    double? amount,
    String? billingCycle,
    DateTime? nextBillingDate,
    CategoryType? category,
    String? iconName,
    int? reminderDaysBefore,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return SubscriptionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
