import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_app_new/database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// User expenses
final userExpensesProvider = StreamProvider.family<List<Expense>, int>((ref, userId) {
  final db = ref.watch(databaseProvider);
  return db.watchUserExpenses(userId);
});

// Recent expenses for user
final recentExpensesProvider = StreamProvider.family<List<Expense>, (int, int)>((ref, params) {
  final db = ref.watch(databaseProvider);
  return db.watchRecentExpenses(params.$1, params.$2);
});

// Current month total for user
final currentMonthTotalProvider = StreamProvider.family<double, (int, String)>((ref, params) {
  final db = ref.watch(databaseProvider);
  return db.watchTotalByMonth(params.$1, params.$2);
});

// Spending by category for user
final spendingByCategoryProvider = StreamProvider.family<Map<String, double>, int>((ref, userId) {
  final db = ref.watch(databaseProvider);
  return db.watchSpendingByCategory(userId);
});

// Spending by category with IDs for color assignment
final spendingByCategoryWithIdProvider = StreamProvider.family<List<CategorySpending>, int>((ref, userId) {
  final db = ref.watch(databaseProvider);
  return db.watchSpendingByCategoryWithId(userId);
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

// Budgets for user and month
final budgetsProvider = StreamProvider.family<List<Budget>, (int, String)>((ref, params) {
  final db = ref.watch(databaseProvider);
  return db.watchBudgetsForMonth(params.$1, params.$2);
});

// Chat sessions for user
final chatSessionsProvider = StreamProvider.family<List<AiChatSession>, int>((ref, userId) {
  final db = ref.watch(databaseProvider);
  return db.watchChatSessions(userId);
});

// Chat messages for session
final chatMessagesProvider = StreamProvider.family<List<AiChatMessage>, int>((ref, sessionId) {
  final db = ref.watch(databaseProvider);
  return db.watchChatMessages(sessionId);
});
