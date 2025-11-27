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

@DriftDatabase(tables: [Users, Incomes, ExpenseCategories, Expenses, Budgets, AiChatSessions, AiChatMessages, UserStats, Achievements, UserAchievements, RecurringExpenses])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
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
  
  Future<bool> deleteCategory(int categoryId) =>
      (delete(expenseCategories)..where((tbl) => tbl.id.equals(categoryId))).go().then((val) => val > 0);

  // ===== EXPENSE OPERATIONS =====
  Future<int> insertExpense(ExpensesCompanion expense) =>
      into(expenses).insert(expense);
  
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
  Stream<List<CategorySpending>> watchSpendingByCategoryWithId(int userId) {
    return customSelect(
      '''SELECT ec.id, ec.name, SUM(e.amount) as total FROM expenses e 
         JOIN expense_categories ec ON e.category_id = ec.id 
         WHERE e.user_id = ? GROUP BY ec.id, ec.name''',
      variables: [Variable.withInt(userId)],
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.db'));
    return NativeDatabase(file);
  });
}
