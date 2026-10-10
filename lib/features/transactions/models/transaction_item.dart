import '../../../core/constants/categories.dart';

class TransactionItem {
  final int? id;
  final String title;
  final double amount;
  final TransactionType type;
  final CategoryType category;
  final DateTime transactionDate;
  final String source; // 'OCR_SCAN' or 'MANUAL'
  final String? receiptImagePath;
  final String? rawOcrText;
  final String? notes;
  final DateTime createdAt;

  TransactionItem({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.transactionDate,
    this.source = 'MANUAL',
    this.receiptImagePath,
    this.rawOcrText,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isFromOcr => source == 'OCR_SCAN';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'type': type.id,
      'category': category.id,
      'transactionDate': transactionDate.millisecondsSinceEpoch,
      'source': source,
      'receiptImagePath': receiptImagePath,
      'rawOcrText': rawOcrText,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Giao dịch',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: (map['type'] == 'INCOME') ? TransactionType.income : TransactionType.expense,
      category: CategoryType.fromString(map['category'] as String?),
      transactionDate: DateTime.fromMillisecondsSinceEpoch(
        map['transactionDate'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      source: map['source'] as String? ?? 'MANUAL',
      receiptImagePath: map['receiptImagePath'] as String?,
      rawOcrText: map['rawOcrText'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  TransactionItem copyWith({
    int? id,
    String? title,
    double? amount,
    TransactionType? type,
    CategoryType? category,
    DateTime? transactionDate,
    String? source,
    String? receiptImagePath,
    String? rawOcrText,
    String? notes,
    DateTime? createdAt,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      transactionDate: transactionDate ?? this.transactionDate,
      source: source ?? this.source,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
