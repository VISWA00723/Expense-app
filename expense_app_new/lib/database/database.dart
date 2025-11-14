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
}

@DriftDatabase(tables: [Users, Incomes, ExpenseCategories, Expenses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
  
  Future<bool> updateExpense(Expense expense) => update(expenses).replace(expense);
  
  Future<int> deleteExpense(int id) =>
      (delete(expenses)..where((tbl) => tbl.id.equals(id))).go();
  
  Future<double> getTotalByMonth(int userId, String month) async {
    final result = await customSelect(
      'SELECT SUM(amount) as total FROM expenses WHERE user_id = ? AND date LIKE ?',
      variables: [Variable.withInt(userId), Variable.withString('$month%')],
      readsFrom: {expenses},
    ).getSingleOrNull();
    final total = result?.read<double?>('total');
    return total ?? 0.0;
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.db'));
    return NativeDatabase(file);
  });
}
