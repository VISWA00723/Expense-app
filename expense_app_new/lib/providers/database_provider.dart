import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_app_new/database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// User expenses
final userExpensesProvider = StreamProvider.autoDispose.family<List<Expense>, int>((ref, userId) {
  final db = ref.watch(databaseProvider);
  return db.watchUserExpenses(userId).distinct();
});

// Recent expenses for user
final recentExpensesProvider = StreamProvider.autoDispose.family<List<Expense>, (int, int)>((ref, params) {
  final db = ref.watch(databaseProvider);
  return db.watchRecentExpenses(params.$1, params.$2).distinct();
});

// Current month total for user
final currentMonthTotalProvider = StreamProvider.autoDispose.family<double, (int, String)>((ref, params) {
  final db = ref.watch(databaseProvider);
  return db.watchTotalByMonth(params.$1, params.$2).distinct();
});

// Spending by category for user
final spendingByCategoryProvider = StreamProvider.autoDispose.family<Map<String, double>, int>((ref, userId) {
  final db = ref.watch(databaseProvider);
  return db.watchSpendingByCategory(userId).distinct();
});

// Spending by category with IDs for color assignment
final spendingByCategoryWithIdProvider = StreamProvider.autoDispose.family<List<CategorySpending>, (int, String?, String?, int?)>((ref, params) {
  final db = ref.watch(databaseProvider);
  return db.watchSpendingByCategoryWithId(params.$1, startDate: params.$2, endDate: params.$3, categoryId: params.$4).distinct();
});

// Expenses by month for user
final expensesByMonthProvider = FutureProvider.autoDispose.family<List<Expense>, (int, String)>((ref, params) async {
  final db = ref.watch(databaseProvider);
  return db.getExpensesByMonth(params.$1, params.$2);
});

// Expenses by category for user
final expensesByCategoryProvider = FutureProvider.autoDispose.family<List<Expense>, (int, int)>((ref, params) async {
  final db = ref.watch(databaseProvider);
  return db.getExpensesByCategory(params.$1, params.$2);
});

// User categories
final userCategoriesProvider = FutureProvider.autoDispose.family<List<ExpenseCategory>, int>((ref, userId) async {
  final db = ref.watch(databaseProvider);
  return db.getUserCategories(userId);
});

// User incomes
final userIncomesProvider = FutureProvider.autoDispose.family<List<Income>, int>((ref, userId) async {
  final db = ref.watch(databaseProvider);
  return db.getUserIncomes(userId);
});

// Budgets for user and month
final budgetsProvider = StreamProvider.autoDispose.family<List<Budget>, (int, String)>((ref, params) {
  final db = ref.watch(databaseProvider);
  return db.watchBudgetsForMonth(params.$1, params.$2).distinct();
});

// Chat sessions for user
final chatSessionsProvider = StreamProvider.autoDispose.family<List<AiChatSession>, int>((ref, userId) {
  final db = ref.watch(databaseProvider);
  return db.watchChatSessions(userId).distinct();
});

// Chat messages for session
final chatMessagesProvider = StreamProvider.autoDispose.family<List<AiChatMessage>, int>((ref, sessionId) {
  final db = ref.watch(databaseProvider);
  return db.watchChatMessages(sessionId).distinct();
});
