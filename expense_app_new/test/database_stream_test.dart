import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Stream emits new values when expense is added', () async {
    // 1. Setup User and Category
    final userId = await db.createUser(UsersCompanion(
      email: drift.Value('test@test.com'),
      password: drift.Value('password'),
      name: drift.Value('Test User'),
      lifestyle: drift.Value('bachelor'),
      monthlySalary: drift.Value(5000.0),
      createdAt: drift.Value(DateTime.now().toIso8601String()),
      updatedAt: drift.Value(DateTime.now().toIso8601String()),
    ));

    final categoryId = await db.addCategory(ExpenseCategoriesCompanion(
      userId: drift.Value(userId),
      name: drift.Value('Food'),
      icon: drift.Value('food_icon'),
      createdAt: drift.Value(DateTime.now().toIso8601String()),
    ));

    // 2. Listen to streams
    final totalStream = db.watchTotalByMonth(userId, '2023-10');
    final userExpensesStream = db.watchUserExpenses(userId);
    
    expectLater(
      totalStream,
      emitsInOrder([
        0.0, // Initial value
        100.0, // After first add
        150.0, // After second add
      ]),
    );

    expectLater(
      userExpensesStream,
      emitsInOrder([
        isEmpty, // Initial value
        hasLength(1), // After first add
        hasLength(2), // After second add
      ]),
    );

    // 3. Add expenses
    await Future.delayed(const Duration(milliseconds: 100)); // Wait for initial emit
    
    await db.insertExpense(ExpensesCompanion(
      userId: drift.Value(userId),
      title: drift.Value('Lunch'),
      amount: drift.Value(100.0),
      categoryId: drift.Value(categoryId),
      date: drift.Value('2023-10-25'),
      createdAt: drift.Value(DateTime.now().toIso8601String()),
    ));

    await Future.delayed(const Duration(milliseconds: 100));

    await db.insertExpense(ExpensesCompanion(
      userId: drift.Value(userId),
      title: drift.Value('Snack'),
      amount: drift.Value(50.0),
      categoryId: drift.Value(categoryId),
      date: drift.Value('2023-10-26'),
      createdAt: drift.Value(DateTime.now().toIso8601String()),
    ));
  });
}
