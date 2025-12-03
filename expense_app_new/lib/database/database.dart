import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get password => text()();
  TextColumn get name => text()();
  TextColumn get lifestyle => text()(); // bachelor, married, family
  RealColumn get monthlySalary => real()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get preferredCurrency => text().withDefault(const Constant('INR'))();
}

class Incomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  RealColumn get amount => real()();
  TextColumn get source => text()();
  TextColumn get date => text()(); // ISO format: yyyy-mm-dd
  TextColumn get createdAt => text()();


}

class ExpenseCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  IntColumn get color => integer().nullable()(); // Color value (0xFF...)
  TextColumn get iconPath => text().nullable()(); // Path to custom image
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  IntColumn get categoryId => integer()();
  TextColumn get notes => text().nullable()();
  TextColumn get date => text()(); // ISO format: yyyy-mm-dd
  TextColumn get createdAt => text()();
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {id},
  ];


}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  IntColumn get categoryId => integer()();
  RealColumn get amount => real()();
  TextColumn get month => text()(); // Format: 'yyyy-MM'
  TextColumn get createdAt => text()();
}

class AiChatSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  TextColumn get title => text()();
  TextColumn get createdAt => text()();
}

class AiChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(AiChatSessions, #id)();
  BoolColumn get isUser => boolean()(); // true = user, false = AI
  TextColumn get content => text()();
  TextColumn get createdAt => text()();
}

class UserStats extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get wellnessScore => integer().withDefault(const Constant(50))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  TextColumn get lastLoginDate => text().clientDefault(() => DateTime.now().toIso8601String().split('T')[0])(); // ISO format: yyyy-mm-dd
  IntColumn get totalPoints => integer().withDefault(const Constant(0))();
}

class Achievements extends Table {
  TextColumn get id => text()(); // String ID like 'first_expense'
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get iconName => text()();
  IntColumn get points => integer()();
  TextColumn get conditionType => text()(); // 'streak', 'budget', 'savings'
  IntColumn get conditionValue => integer()();
  
  @override
  Set<Column> get primaryKey => {id};
}

class UserAchievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get achievementId => text().references(Achievements, #id)();
  TextColumn get unlockedAt => text()();
}

class RecurringExpenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().references(ExpenseCategories, #id)();
  TextColumn get frequency => text()(); // 'daily', 'weekly', 'monthly', 'yearly'
  TextColumn get nextDueDate => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get autoPay => boolean().withDefault(const Constant(false))();
}

class Assets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'bank', 'cash', 'stock', 'real_estate', 'gold', 'other'
  RealColumn get value => real()();
  TextColumn get updatedAt => text()();
}

class Liabilities extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'loan', 'credit_card', 'mortgage', 'other'
  RealColumn get totalAmount => real()();
  RealColumn get remainingAmount => real()();
  RealColumn get interestRate => real().nullable()();
  TextColumn get dueDate => text().nullable()();
  TextColumn get updatedAt => text()();
}

class Envelopes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get categoryId => integer().references(ExpenseCategories, #id)();
  RealColumn get amount => real()(); // Allocated amount
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  TextColumn get updatedAt => text().clientDefault(() => DateTime.now().toIso8601String())();
  
  @override
  List<String> get customConstraints => [
    'UNIQUE(user_id, category_id, month, year)'
  ];
}

class EnvelopeTransfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get fromEnvelopeId => integer().nullable().references(Envelopes, #id)(); // Null if from "To be Budgeted"
  IntColumn get toEnvelopeId => integer().references(Envelopes, #id)();
  RealColumn get amount => real()();
  TextColumn get date => text()();
  TextColumn get createdAt => text().clientDefault(() => DateTime.now().toIso8601String())();
}

class NetWorthHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  RealColumn get totalAssets => real()();
  RealColumn get totalLiabilities => real()();
  RealColumn get netWorth => real()();
  TextColumn get date => text()(); // yyyy-mm-dd
}

@DriftDatabase(tables: [Users, Incomes, ExpenseCategories, Expenses, Budgets, AiChatSessions, AiChatMessages, UserStats, Achievements, UserAchievements, RecurringExpenses, Assets, Liabilities, NetWorthHistory, Envelopes, EnvelopeTransfers])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Create indexes for new installs
        await m.issueCustomQuery('CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses(user_id, date)');
        await m.issueCustomQuery('CREATE INDEX IF NOT EXISTS idx_expenses_user_category ON expenses(user_id, category_id)');
        await m.issueCustomQuery('CREATE INDEX IF NOT EXISTS idx_incomes_user_date ON incomes(user_id, date)');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration from v1 to v2: Add new tables
        if (from == 1) {
          // Create new tables for v2
          await m.create(users);
          await m.create(incomes);
          await m.create(expenseCategories);
          // Expenses table needs to be recreated with new schema
          await m.deleteTable('expenses');
          await m.create(expenses);
        }
        
        // Migration from v2 to v3: Add Budgets and AI Chat tables
        if (from < 3) {
          await m.create(budgets);
          await m.create(aiChatSessions);
          await m.create(aiChatMessages);
        }

        // Migration from v3 to v4: Add Gamification and Recurring Expenses tables
        if (from < 4) {
          await m.create(userStats);
          await m.create(achievements);
          await m.create(userAchievements);
          await m.create(recurringExpenses);
        }

        // Migration from v4 to v5: Add Currency support
        if (from < 5) {
          await m.addColumn(expenses, expenses.currencyCode);
          await m.addColumn(users, users.preferredCurrency);
        }

        // Migration from v5 to v6: Add Indexes
        if (from < 6) {
          // Indexes are added via customConstraints, so we might need to recreate tables or just add indices manually
          // Drift usually handles index creation if they are part of createAll, but for migration we need to add them.
          // Since we added customConstraints, we should run custom SQL to create indexes.
          await m.issueCustomQuery('CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses(user_id, date)');
          await m.issueCustomQuery('CREATE INDEX IF NOT EXISTS idx_expenses_user_category ON expenses(user_id, category_id)');
          await m.issueCustomQuery('CREATE INDEX IF NOT EXISTS idx_incomes_user_date ON incomes(user_id, date)');
        }

        // Migration from v6 to v7: Add Custom Category columns
        if (from < 7) {
          await m.addColumn(expenseCategories, expenseCategories.color);
          await m.addColumn(expenseCategories, expenseCategories.iconPath);
        }

        // Migration from v7 to v8: Add Net Worth tables
        if (from < 8) {
          await m.create(assets);
          await m.create(liabilities);
          await m.create(netWorthHistory);
        }

        // Migration from v8 to v9: Add Envelope Budgeting tables
        if (from < 9) {
          await m.create(envelopes);
          await m.create(envelopeTransfers);
        }
      },
    );
  }

  // ===== USER OPERATIONS =====
  Future<int> createUser(UsersCompanion user) => into(users).insert(user);
  
  Future<User?> getUserByEmail(String email) =>
      (select(users)..where((tbl) => tbl.email.equals(email))).getSingleOrNull();
  
  Future<User?> getUserById(int id) =>
      (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  
  Future<bool> updateUser(User user) => update(users).replace(user);

  // ===== INCOME OPERATIONS =====
  Future<int> addIncome(IncomesCompanion income) => into(incomes).insert(income);
  
  Future<List<Income>> getUserIncomes(int userId) =>
      (select(incomes)..where((tbl) => tbl.userId.equals(userId))).get();
  
  Future<double> getTotalIncomeForMonth(int userId, String month) async {
    final result = await customSelect(
      'SELECT SUM(amount) as total FROM incomes WHERE user_id = ? AND date LIKE ?',
      variables: [Variable.withInt(userId), Variable.withString('$month%')],
      readsFrom: {incomes},
    ).getSingleOrNull();
    final total = result?.read<double?>('total');
    return total ?? 0.0;
  }

  Stream<double> watchTotalIncomeForMonth(int userId, String month) {
    return customSelect(
      'SELECT SUM(amount) as total FROM incomes WHERE user_id = ? AND date LIKE ?',
      variables: [Variable.withInt(userId), Variable.withString('$month%')],
      readsFrom: {incomes},
    ).watchSingleOrNull().map((row) => row?.read<double?>('total') ?? 0.0);
  }

  // ===== CATEGORY OPERATIONS =====
  Future<int> addCategory(ExpenseCategoriesCompanion category) =>
      into(expenseCategories).insert(category);
  
  Future<List<ExpenseCategory>> getUserCategories(int userId) =>
      (select(expenseCategories)..where((tbl) => tbl.userId.equals(userId))).get();

  Stream<List<ExpenseCategory>> watchCategories(int userId) =>
      (select(expenseCategories)..where((tbl) => tbl.userId.equals(userId))).watch();
  
  Future<bool> deleteCategory(int categoryId) =>
      (delete(expenseCategories)..where((tbl) => tbl.id.equals(categoryId))).go().then((val) => val > 0);

  // ===== EXPENSE OPERATIONS =====
  Future<int> insertExpense(ExpensesCompanion expense) {
    // Validate currency code
    final allowedCurrencies = ['INR', 'USD', 'EUR', 'GBP', 'AUD', 'CAD', 'JPY', 'CNY'];
    if (expense.currencyCode.present && !allowedCurrencies.contains(expense.currencyCode.value)) {
      throw ArgumentError('Invalid currency code: ${expense.currencyCode.value}. Allowed: $allowedCurrencies');
    }
    return into(expenses).insert(expense);
  }
  
  Future<List<Expense>> getUserExpenses(int userId) =>
      (select(expenses)..where((tbl) => tbl.userId.equals(userId))).get();

  Stream<List<Expense>> watchUserExpenses(int userId) =>
      (select(expenses)..where((tbl) => tbl.userId.equals(userId))).watch();
  
  Future<List<Expense>> getExpensesByMonth(int userId, String month) =>
      (select(expenses)
            ..where((tbl) => tbl.userId.equals(userId) & tbl.date.like('$month%')))
          .get();
  
  Future<List<Expense>> getExpensesByCategory(int userId, int categoryId) =>
      (select(expenses)
            ..where((tbl) => tbl.userId.equals(userId) & tbl.categoryId.equals(categoryId)))
          .get();
  
  Future<List<Expense>> getRecentExpenses(int userId, int limit) =>
      (select(expenses)
            ..where((tbl) => tbl.userId.equals(userId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.date, mode: OrderingMode.desc)])
            ..limit(limit))
          .get();

  Stream<List<Expense>> watchRecentExpenses(int userId, int limit) =>
      (select(expenses)
            ..where((tbl) => tbl.userId.equals(userId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.date, mode: OrderingMode.desc)])
            ..limit(limit))
          .watch();
  
  Future<bool> updateExpense(Expense expense) => update(expenses).replace(expense);
  
  Future<int> deleteExpense(int id) =>
      (delete(expenses)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> getExpenseCount(int userId) {
    final count = expenses.id.count();
    final query = selectOnly(expenses)
      ..addColumns([count])
      ..where(expenses.userId.equals(userId));
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }
  
  Future<double> getTotalByMonth(int userId, String month) async {
    final result = await customSelect(
      'SELECT SUM(amount) as total FROM expenses WHERE user_id = ? AND date LIKE ?',
      variables: [Variable.withInt(userId), Variable.withString('$month%')],
      readsFrom: {expenses},
    ).getSingleOrNull();
    final total = result?.read<double?>('total');
    return total ?? 0.0;
  }

  Stream<double> watchTotalByMonth(int userId, String month) {
    return customSelect(
      'SELECT SUM(amount) as total FROM expenses WHERE user_id = ? AND date LIKE ?',
      variables: [Variable.withInt(userId), Variable.withString('$month%')],
      readsFrom: {expenses},
    ).watchSingleOrNull().map((row) => row?.read<double?>('total') ?? 0.0);
  }
  
  Future<Map<String, double>> getSpendingByCategory(int userId) async {
    final result = await customSelect(
      '''SELECT ec.name, SUM(e.amount) as total FROM expenses e 
         JOIN expense_categories ec ON e.category_id = ec.id 
         WHERE e.user_id = ? GROUP BY ec.name''',
      variables: [Variable.withInt(userId)],
      readsFrom: {expenses, expenseCategories},
    ).get();
    
    final map = <String, double>{};
    for (final row in result) {
      map[row.read<String>('name')] = (row.read<double>('total')).toDouble();
    }
    return map;
  }

  Stream<Map<String, double>> watchSpendingByCategory(int userId) {
    return customSelect(
      '''SELECT ec.name, SUM(e.amount) as total FROM expenses e 
         JOIN expense_categories ec ON e.category_id = ec.id 
         WHERE e.user_id = ? GROUP BY ec.name''',
      variables: [Variable.withInt(userId)],
      readsFrom: {expenses, expenseCategories},
    ).watch().map((rows) {
      final map = <String, double>{};
      for (final row in rows) {
        map[row.read<String>('name')] = (row.read<double>('total')).toDouble();
      }
      return map;
    });
  }

  // Get spending by category with IDs for color assignment
  Stream<List<CategorySpending>> watchSpendingByCategoryWithId(int userId, {String? startDate, String? endDate, int? categoryId}) {
    String query = '''SELECT ec.id, ec.name, SUM(e.amount) as total FROM expenses e 
         JOIN expense_categories ec ON e.category_id = ec.id 
         WHERE e.user_id = ?''';
    
    final variables = <Variable>[Variable.withInt(userId)];

    if (startDate != null) {
      query += ' AND e.date >= ?';
      variables.add(Variable.withString(startDate));
    }
    if (endDate != null) {
      query += ' AND e.date <= ?';
      variables.add(Variable.withString(endDate));
    }
    if (categoryId != null) {
      query += ' AND e.category_id = ?';
      variables.add(Variable.withInt(categoryId));
    }

    query += ' GROUP BY ec.id, ec.name';

    return customSelect(
      query,
      variables: variables,
      readsFrom: {expenses, expenseCategories},
    ).watch().map((rows) {
      return rows.map((row) => CategorySpending(
        categoryId: row.read<int>('id'),
        categoryName: row.read<String>('name'),
        totalAmount: row.read<double>('total'),
      )).toList();
    });
  }
  // ===== BUDGET OPERATIONS =====
  Future<int> setBudget(BudgetsCompanion budget) => into(budgets).insertOnConflictUpdate(budget);

  Future<Budget?> getBudgetForCategory(int userId, int categoryId, String month) =>
      (select(budgets)..where((tbl) => 
        tbl.userId.equals(userId) & 
        tbl.categoryId.equals(categoryId) & 
        tbl.month.equals(month)
      )).getSingleOrNull();

  Stream<List<Budget>> watchBudgetsForMonth(int userId, String month) =>
      (select(budgets)..where((tbl) => 
        tbl.userId.equals(userId) & 
        tbl.month.equals(month)
      )).watch();

  // ===== AI CHAT OPERATIONS =====
  Future<int> createChatSession(AiChatSessionsCompanion session) => into(aiChatSessions).insert(session);

  Stream<List<AiChatSession>> watchChatSessions(int userId) =>
      (select(aiChatSessions)
        ..where((tbl) => tbl.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
      ).watch();

  Future<int> addChatMessage(AiChatMessagesCompanion message) => into(aiChatMessages).insert(message);

  Stream<List<AiChatMessage>> watchChatMessages(int sessionId) =>
      (select(aiChatMessages)
        ..where((tbl) => tbl.sessionId.equals(sessionId))
        ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)])
      ).watch();

  // ===== NET WORTH OPERATIONS =====
  Future<int> addAsset(AssetsCompanion asset) => into(assets).insert(asset);
  Future<bool> updateAsset(Asset asset) => update(assets).replace(asset);
  Future<int> deleteAsset(int id) => (delete(assets)..where((t) => t.id.equals(id))).go();
  Stream<List<Asset>> watchAssets(int userId) => (select(assets)..where((t) => t.userId.equals(userId))).watch();
  Future<List<Asset>> getAssets(int userId) => (select(assets)..where((t) => t.userId.equals(userId))).get();

  Future<int> addLiability(LiabilitiesCompanion liability) => into(liabilities).insert(liability);
  Future<bool> updateLiability(Liability liability) => update(liabilities).replace(liability);
  Future<int> deleteLiability(int id) => (delete(liabilities)..where((t) => t.id.equals(id))).go();
  Stream<List<Liability>> watchLiabilities(int userId) => (select(liabilities)..where((t) => t.userId.equals(userId))).watch();
  Future<List<Liability>> getLiabilities(int userId) => (select(liabilities)..where((t) => t.userId.equals(userId))).get();

  Future<int> addNetWorthSnapshot(NetWorthHistoryCompanion snapshot) => into(netWorthHistory).insert(snapshot);
  Stream<List<NetWorthHistoryData>> watchNetWorthHistory(int userId) => 
      (select(netWorthHistory)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc)])
      ).watch();

  // ===== ENVELOPE BUDGETING OPERATIONS =====
  Future<int> addEnvelope(EnvelopesCompanion envelope) => into(envelopes).insert(envelope);
  Future<bool> updateEnvelope(Envelope envelope) => update(envelopes).replace(envelope);
  Future<int> deleteEnvelope(int id) => (delete(envelopes)..where((t) => t.id.equals(id))).go();
  
  Stream<List<Envelope>> watchEnvelopes(int userId, int month, int year) => 
      (select(envelopes)
        ..where((t) => t.userId.equals(userId) & t.month.equals(month) & t.year.equals(year))
      ).watch();

  Future<Envelope?> getEnvelope(int userId, int categoryId, int month, int year) =>
      (select(envelopes)
        ..where((t) => t.userId.equals(userId) & t.categoryId.equals(categoryId) & t.month.equals(month) & t.year.equals(year))
      ).getSingleOrNull();

  Future<int> addEnvelopeTransfer(EnvelopeTransfersCompanion transfer) => into(envelopeTransfers).insert(transfer);
}

// Helper class for category spending data
class CategorySpending {
  final int categoryId;
  final String categoryName;
  final double totalAmount;

  CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorySpending &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          categoryName == other.categoryName &&
          totalAmount == other.totalAmount;

  @override
  int get hashCode => categoryId.hashCode ^ categoryName.hashCode ^ totalAmount.hashCode;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.db'));
    return NativeDatabase(file);
  });
}
