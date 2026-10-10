import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/transactions/models/transaction_item.dart';
import '../../features/subscriptions/models/subscription_item.dart';
import '../constants/categories.dart';

class DatabaseHelper {
  static const String _dbName = 'cadence_finance.db';
  static const int _dbVersion = 1;

  static const String tableTransactions = 'transactions';
  static const String tableSubscriptions = 'subscriptions';
  static const String tableSettings = 'settings';

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, _dbName);

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Transactions table (Income & Expenses, Manual or OCR)
        await db.execute('''
          CREATE TABLE $tableTransactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            transactionDate INTEGER NOT NULL,
            source TEXT NOT NULL,
            receiptImagePath TEXT,
            rawOcrText TEXT,
            notes TEXT,
            createdAt INTEGER NOT NULL
          )
        ''');

        // Subscriptions & Recurring Bills table
        await db.execute('''
          CREATE TABLE $tableSubscriptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            amount REAL NOT NULL,
            billingCycle TEXT NOT NULL,
            nextBillingDate INTEGER NOT NULL,
            category TEXT NOT NULL,
            iconName TEXT,
            reminderDaysBefore INTEGER DEFAULT 2,
            isActive INTEGER DEFAULT 1,
            createdAt INTEGER NOT NULL
          )
        ''');

        // Settings / Metadata table
        await db.execute('''
          CREATE TABLE $tableSettings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        // Seed initial starter data so app is immediately full and delightful
        await _seedInitialData(db);
      },
    );
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();

    // 1. Seed Subscriptions
    final initialSubscriptions = [
      SubscriptionItem(
        name: 'Netflix 4K Family',
        amount: 260000,
        billingCycle: 'MONTHLY',
        nextBillingDate: DateTime(now.year, now.month, 15),
        category: CategoryType.entertainment,
      ),
      SubscriptionItem(
        name: 'Spotify Premium',
        amount: 59000,
        billingCycle: 'MONTHLY',
        nextBillingDate: DateTime(now.year, now.month, 22),
        category: CategoryType.entertainment,
      ),
      SubscriptionItem(
        name: 'Apple iCloud (50GB)',
        amount: 19000,
        billingCycle: 'MONTHLY',
        nextBillingDate: DateTime(now.year, now.month, 18),
        category: CategoryType.subscriptions,
      ),
      SubscriptionItem(
        name: 'Internet Viettel Cáp Quang',
        amount: 220000,
        billingCycle: 'MONTHLY',
        nextBillingDate: DateTime(now.year, now.month, 28),
        category: CategoryType.bills,
      ),
      SubscriptionItem(
        name: 'Gói 4G 120GB/tháng',
        amount: 120000,
        billingCycle: 'MONTHLY',
        nextBillingDate: DateTime(now.year, now.month, 10),
        category: CategoryType.bills,
      ),
    ];

    for (final sub in initialSubscriptions) {
      await db.insert(tableSubscriptions, sub.toMap());
    }

    // 2. Seed Transactions (Income + Expenses)
    final initialTransactions = [
      TransactionItem(
        title: 'Lương chuyển khoản tháng ${now.month}',
        amount: 18500000,
        type: TransactionType.income,
        category: CategoryType.salary,
        transactionDate: DateTime(now.year, now.month, 1),
        source: 'MANUAL',
      ),
      TransactionItem(
        title: 'WinMart+ Đà Nẵng',
        amount: 105000,
        type: TransactionType.expense,
        category: CategoryType.food,
        transactionDate: DateTime(now.year, now.month, now.day - 1, 14, 30),
        source: 'OCR_SCAN',
        notes: 'Sữa tươi, bánh mì sandwich, xúc xích',
      ),
      TransactionItem(
        title: 'Highlands Coffee',
        amount: 59000,
        type: TransactionType.expense,
        category: CategoryType.food,
        transactionDate: DateTime(now.year, now.month, now.day, 8, 45),
        source: 'MANUAL',
      ),
      TransactionItem(
        title: 'Tiền thưởng dự án Q3',
        amount: 2000000,
        type: TransactionType.income,
        category: CategoryType.gift,
        transactionDate: DateTime(now.year, now.month, 3),
        source: 'MANUAL',
      ),
      TransactionItem(
        title: 'Shopee Đơn công nghệ',
        amount: 320000,
        type: TransactionType.expense,
        category: CategoryType.shopping,
        transactionDate: DateTime(now.year, now.month, now.day - 2),
        source: 'MANUAL',
      ),
      TransactionItem(
        title: 'Đổ xăng Petrolimex',
        amount: 80000,
        type: TransactionType.expense,
        category: CategoryType.transport,
        transactionDate: DateTime(now.year, now.month, now.day - 3),
        source: 'OCR_SCAN',
      ),
    ];

    for (final tx in initialTransactions) {
      await db.insert(tableTransactions, tx.toMap());
    }

    // Default monthly target savings
    await db.insert(tableSettings, {
      'key': 'target_savings',
      'value': '3000000',
    });
  }

  // ================= TRANSACTIONS =================

  Future<int> insertTransaction(TransactionItem item) async {
    final db = await database;
    return await db.insert(tableTransactions, item.toMap());
  }

  Future<List<TransactionItem>> getAllTransactions({
    TransactionType? type,
    CategoryType? category,
    String? searchQuery,
    int? limit,
  }) async {
    final db = await database;
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (type != null) {
      whereClause = 'type = ?';
      whereArgs.add(type.id);
    }

    if (category != null) {
      if (whereClause != null) {
        whereClause += ' AND category = ?';
      } else {
        whereClause = 'category = ?';
      }
      whereArgs.add(category.id);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      if (whereClause != null) {
        whereClause += ' AND title LIKE ?';
      } else {
        whereClause = 'title LIKE ?';
      }
      whereArgs.add('%$searchQuery%');
    }

    final maps = await db.query(
      tableTransactions,
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'transactionDate DESC',
      limit: limit,
    );

    return maps.map((m) => TransactionItem.fromMap(m)).toList();
  }

  Future<int> updateTransaction(TransactionItem item) async {
    final db = await database;
    return await db.update(
      tableTransactions,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    final itemMap = await db.query(tableTransactions, where: 'id = ?', whereArgs: [id]);
    if (itemMap.isNotEmpty) {
      final imgPath = itemMap.first['receiptImagePath'] as String?;
      if (imgPath != null) {
        try {
          final file = File(imgPath);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }
    return await db.delete(tableTransactions, where: 'id = ?', whereArgs: [id]);
  }

  // ================= SUBSCRIPTIONS =================

  Future<int> insertSubscription(SubscriptionItem sub) async {
    final db = await database;
    return await db.insert(tableSubscriptions, sub.toMap());
  }

  Future<List<SubscriptionItem>> getAllSubscriptions() async {
    final db = await database;
    final maps = await db.query(
      tableSubscriptions,
      orderBy: 'nextBillingDate ASC',
    );
    return maps.map((m) => SubscriptionItem.fromMap(m)).toList();
  }

  Future<List<SubscriptionItem>> getActiveSubscriptions() async {
    final db = await database;
    final maps = await db.query(
      tableSubscriptions,
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'nextBillingDate ASC',
    );
    return maps.map((m) => SubscriptionItem.fromMap(m)).toList();
  }

  Future<int> updateSubscription(SubscriptionItem sub) async {
    final db = await database;
    return await db.update(
      tableSubscriptions,
      sub.toMap(),
      where: 'id = ?',
      whereArgs: [sub.id],
    );
  }

  Future<int> deleteSubscription(int id) async {
    final db = await database;
    return await db.delete(tableSubscriptions, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleSubscriptionActive(int id, bool isActive) async {
    final db = await database;
    await db.update(
      tableSubscriptions,
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= FINANCIAL AGGREGATIONS =================

  /// Get total income for the current month
  Future<double> getCurrentMonthIncome() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;

    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM $tableTransactions
      WHERE type = 'INCOME' AND transactionDate >= ?
    ''', [startOfMonth]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total expenses for the current month
  Future<double> getCurrentMonthExpense() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;

    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM $tableTransactions
      WHERE type = 'EXPENSE' AND transactionDate >= ?
    ''', [startOfMonth]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Total monthly fixed subscription burden
  Future<double> getMonthlySubscriptionTotal() async {
    final activeSubs = await getActiveSubscriptions();
    double total = 0.0;
    for (final s in activeSubs) {
      total += s.monthlyNormalizedAmount;
    }
    return total;
  }

  /// Safe-to-spend: (Income - FixedSub - TargetSavings - CurrentExpenses) / DaysRemaining
  Future<double> calculateSafeToSpendToday() async {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = (daysInMonth - now.day + 1).clamp(1, 31);

    final income = await getCurrentMonthIncome();
    final fixedCosts = await getMonthlySubscriptionTotal();
    final currentExpenses = await getCurrentMonthExpense();

    // Default target savings 15% of income or 2.000.000
    final targetSavings = (income > 0) ? income * 0.15 : 2000000.0;

    final disposablePool = income - fixedCosts - targetSavings - currentExpenses;
    if (disposablePool <= 0) return 0.0;

    return disposablePool / daysRemaining;
  }

  /// Category breakdown for current month expenses
  Future<Map<CategoryType, double>> getCategoryExpenseBreakdown() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;

    final results = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM $tableTransactions
      WHERE type = 'EXPENSE' AND transactionDate >= ?
      GROUP BY category
      ORDER BY total DESC
    ''', [startOfMonth]);

    final Map<CategoryType, double> map = {};
    for (final row in results) {
      final cat = CategoryType.fromString(row['category'] as String?);
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      map[cat] = total;
    }
    return map;
  }
}
