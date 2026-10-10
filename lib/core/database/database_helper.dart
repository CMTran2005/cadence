import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/transactions/models/transaction_item.dart';
import '../../features/subscriptions/models/subscription_item.dart';
import '../constants/categories.dart';
import '../services/app_data_notifier.dart';

class DatabaseHelper {
  static const String _dbName = 'cadence_finance.db';
  static const int _dbVersion = 2;

  static const String tableTransactions = 'transactions';
  static const String tableSubscriptions = 'subscriptions';
  static const String tableSettings = 'settings';
  static const String tableCustomCategories = 'custom_categories';

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    await cleanSampleDataIfNeeded();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = join(await getDatabasesPath(), _dbName);

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

        // Custom Categories table
        await db.execute('''
          CREATE TABLE $tableCustomCategories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            iconCode INTEGER NOT NULL,
            colorValue INTEGER NOT NULL,
            type TEXT NOT NULL
          )
        ''');

        // Seed default target savings setting only (NO sample transactions/subs)
        await db.insert(tableSettings, {
          'key': 'target_savings',
          'value': '3000000',
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableCustomCategories (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              iconCode INTEGER NOT NULL,
              colorValue INTEGER NOT NULL,
              type TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  /// Clean legacy seeded mock data if present on existing user storage
  Future<void> cleanSampleDataIfNeeded() async {
    try {
      final db = _database;
      if (db == null) return;
      final flag = await getSetting('sample_purged_v2');
      if (flag != 'true') {
        // Purge mock demo items from transactions
        await db.delete(
          tableTransactions,
          where: "title LIKE 'Lương chuyển khoản tháng%' OR title LIKE 'WinMart+ Đà Nẵng%' OR title LIKE 'Highlands Coffee%' OR title LIKE 'Tiền thưởng dự án%' OR title LIKE 'Shopee Đơn%' OR title LIKE 'Đổ xăng Petrolimex%'",
        );
        // Purge mock demo items from subscriptions
        await db.delete(
          tableSubscriptions,
          where: "name IN ('Netflix 4K Family', 'Spotify Premium', 'Apple iCloud (50GB)', 'Internet Viettel Cáp Quang', 'Gói 4G 120GB/tháng')",
        );
        await setSetting('sample_purged_v2', 'true');
      }
    } catch (_) {}
  }

  /// Wipe all user data completely (Transactions, Subscriptions, Custom Categories)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableTransactions);
    await db.delete(tableSubscriptions);
    try {
      await db.delete(tableCustomCategories);
    } catch (_) {}
    AppDataNotifier.instance.notifyDataChanged();
  }

  // ================= TRANSACTIONS =================

  Future<int> insertTransaction(TransactionItem item) async {
    final db = await database;
    final id = await db.insert(tableTransactions, item.toMap());
    AppDataNotifier.instance.notifyDataChanged();
    return id;
  }

  Future<List<TransactionItem>> getAllTransactions({
    TransactionType? type,
    CategoryType? category,
    String? searchQuery,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
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

    if (startDate != null) {
      final startMs = startDate.millisecondsSinceEpoch;
      if (whereClause != null) {
        whereClause += ' AND transactionDate >= ?';
      } else {
        whereClause = 'transactionDate >= ?';
      }
      whereArgs.add(startMs);
    }

    if (endDate != null) {
      final endMs = endDate.millisecondsSinceEpoch;
      if (whereClause != null) {
        whereClause += ' AND transactionDate <= ?';
      } else {
        whereClause = 'transactionDate <= ?';
      }
      whereArgs.add(endMs);
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
    final rows = await db.update(
      tableTransactions,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    AppDataNotifier.instance.notifyDataChanged();
    return rows;
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
    final rows = await db.delete(tableTransactions, where: 'id = ?', whereArgs: [id]);
    AppDataNotifier.instance.notifyDataChanged();
    return rows;
  }

  // ================= SUBSCRIPTIONS =================

  Future<int> insertSubscription(SubscriptionItem sub) async {
    final db = await database;
    final id = await db.insert(tableSubscriptions, sub.toMap());
    AppDataNotifier.instance.notifyDataChanged();
    return id;
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
    final rows = await db.update(
      tableSubscriptions,
      sub.toMap(),
      where: 'id = ?',
      whereArgs: [sub.id],
    );
    AppDataNotifier.instance.notifyDataChanged();
    return rows;
  }

  Future<int> deleteSubscription(int id) async {
    final db = await database;
    final rows = await db.delete(tableSubscriptions, where: 'id = ?', whereArgs: [id]);
    AppDataNotifier.instance.notifyDataChanged();
    return rows;
  }

  Future<void> toggleSubscriptionActive(int id, bool isActive) async {
    final db = await database;
    await db.update(
      tableSubscriptions,
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    AppDataNotifier.instance.notifyDataChanged();
  }

  // ================= CUSTOM CATEGORIES =================

  Future<void> insertCustomCategory(CategoryItemData cat) async {
    final db = await database;
    await db.insert(
      tableCustomCategories,
      cat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppDataNotifier.instance.notifyDataChanged();
  }

  Future<List<CategoryItemData>> getAllCustomCategories() async {
    final db = await database;
    try {
      final maps = await db.query(tableCustomCategories);
      return maps.map((m) => CategoryItemData.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteCustomCategory(String id) async {
    final db = await database;
    try {
      await db.delete(tableCustomCategories, where: 'id = ?', whereArgs: [id]);
      AppDataNotifier.instance.notifyDataChanged();
    } catch (_) {}
  }

  // ================= FINANCIAL AGGREGATIONS =================

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

  Future<double> getMonthlySubscriptionTotal() async {
    final activeSubs = await getActiveSubscriptions();
    double total = 0.0;
    for (final s in activeSubs) {
      total += s.monthlyNormalizedAmount;
    }
    return total;
  }

  Future<double> calculateSafeToSpendToday() async {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = (daysInMonth - now.day + 1).clamp(1, 31);

    final income = await getCurrentMonthIncome();
    final fixedCosts = await getMonthlySubscriptionTotal();
    final currentExpenses = await getCurrentMonthExpense();

    final targetSavings = (income > 0) ? income * 0.15 : 2000000.0;

    final disposablePool = income - fixedCosts - targetSavings - currentExpenses;
    if (disposablePool <= 0) return 0.0;

    return disposablePool / daysRemaining;
  }

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

  Future<Map<CategoryType, double>> getCategoryExpenseBreakdownForRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final startMs = startDate.millisecondsSinceEpoch;
    final endMs = endDate.millisecondsSinceEpoch;

    final results = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM $tableTransactions
      WHERE type = 'EXPENSE' AND transactionDate >= ? AND transactionDate <= ?
      GROUP BY category
      ORDER BY total DESC
    ''', [startMs, endMs]);

    final Map<CategoryType, double> map = {};
    for (final row in results) {
      final cat = CategoryType.fromString(row['category'] as String?);
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      map[cat] = total;
    }
    return map;
  }

  Future<Map<String, double>> getPeriodSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final startMs = startDate.millisecondsSinceEpoch;
    final endMs = endDate.millisecondsSinceEpoch;

    final incomeRes = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM $tableTransactions
      WHERE type = 'INCOME' AND transactionDate >= ? AND transactionDate <= ?
    ''', [startMs, endMs]);

    final expenseRes = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM $tableTransactions
      WHERE type = 'EXPENSE' AND transactionDate >= ? AND transactionDate <= ?
    ''', [startMs, endMs]);

    final income = (incomeRes.first['total'] as num?)?.toDouble() ?? 0.0;
    final expense = (expenseRes.first['total'] as num?)?.toDouble() ?? 0.0;

    return {'income': income, 'expense': expense};
  }

  Future<List<double>> getDailyExpensesForRange({
    required DateTime startDate,
    required int numDays,
  }) async {
    final db = await database;
    final List<double> dailyTotals = [];

    for (int i = 0; i < numDays; i++) {
      final dayStart = DateTime(startDate.year, startDate.month, startDate.day + i);
      final dayEnd = DateTime(dayStart.year, dayStart.month, dayStart.day, 23, 59, 59, 999);

      final res = await db.rawQuery('''
        SELECT SUM(amount) as total
        FROM $tableTransactions
        WHERE type = 'EXPENSE' AND transactionDate >= ? AND transactionDate <= ?
      ''', [dayStart.millisecondsSinceEpoch, dayEnd.millisecondsSinceEpoch]);

      final total = (res.first['total'] as num?)?.toDouble() ?? 0.0;
      dailyTotals.add(total);
    }

    return dailyTotals;
  }

  Future<List<double>> getMonthlyExpensesForYear(int year) async {
    final db = await database;
    final List<double> monthlyTotals = [];

    for (int m = 1; m <= 12; m++) {
      final monthStart = DateTime(year, m, 1);
      final monthEnd = DateTime(year, m + 1, 0, 23, 59, 59, 999);

      final res = await db.rawQuery('''
        SELECT SUM(amount) as total
        FROM $tableTransactions
        WHERE type = 'EXPENSE' AND transactionDate >= ? AND transactionDate <= ?
      ''', [monthStart.millisecondsSinceEpoch, monthEnd.millisecondsSinceEpoch]);

      final total = (res.first['total'] as num?)?.toDouble() ?? 0.0;
      monthlyTotals.add(total);
    }

    return monthlyTotals;
  }

  Future<List<int>> getAvailableYears() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT transactionDate FROM $tableTransactions ORDER BY transactionDate DESC
    ''');

    final Set<int> years = {DateTime.now().year};
    for (final row in results) {
      final ms = row['transactionDate'] as int?;
      if (ms != null) {
        years.add(DateTime.fromMillisecondsSinceEpoch(ms).year);
      }
    }

    final list = years.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  // ================= SETTINGS =================

  Future<String?> getSetting(String key, {String? defaultValue}) async {
    final db = await database;
    final res = await db.query(
      tableSettings,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return res.first['value'] as String?;
    }
    return defaultValue;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      tableSettings,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
