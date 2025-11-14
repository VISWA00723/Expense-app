import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_app_new/database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// User expenses
final userExpensesProvider = FutureProvider.family<List<Expense>, int>((ref, userId) async {
  final db = ref.watch(databaseProvider);
  return db.getUserExpenses(userId);
});

// Recent expenses for user
final recentExpensesProvider = FutureProvider.family<List<Expense>, (int, int)>((ref, params) async {
  final db = ref.watch(databaseProvider);
  return db.getRecentExpenses(params.$1, params.$2);
});

// Current month total for user
final currentMonthTotalProvider = FutureProvider.family<double, (int, String)>((ref, params) async {
  final db = ref.watch(databaseProvider);
  return db.getTotalByMonth(params.$1, params.$2);
});

// Spending by category for user
final spendingByCategoryProvider = FutureProvider.family<Map<String, double>, int>((ref, userId) async {
  final db = ref.watch(databaseProvider);
  return db.getSpendingByCategory(userId);
});

// Expenses by month for user
final expensesByMonthProvider = FutureProvider.family<List<Expense>, (int, String)>((ref, params) async {
  final db = ref.watch(databaseProvider);
  return db.getExpensesByMonth(params.$1, params.$2);
});

// Expenses by category for user
final expensesByCategoryProvider = FutureProvider.family<List<Expense>, (int, int)>((ref, params) async {
  final db = ref.watch(databaseProvider);
  return db.getExpensesByCategory(params.$1, params.$2);
});

// User categories
final userCategoriesProvider = FutureProvider.family<List<ExpenseCategory>, int>((ref, userId) async {
  final db = ref.watch(databaseProvider);
  return db.getUserCategories(userId);
});

// User incomes
final userIncomesProvider = FutureProvider.family<List<Income>, int>((ref, userId) async {
  final db = ref.watch(databaseProvider);
  return db.getUserIncomes(userId);
});
