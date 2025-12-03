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

final categoriesStreamProvider = StreamProvider.autoDispose.family<List<ExpenseCategory>, int>((ref, userId) {
  final db = ref.watch(databaseProvider);
  return db.watchCategories(userId);
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

// Assets for user
final assetsProvider = StreamProvider.autoDispose.family<List<Asset>, int>((ref, userId) {
  final db = ref.watch(databaseProvider);
  return db.watchAssets(userId).distinct();
});

// Liabilities for user
final liabilitiesProvider = StreamProvider.autoDispose.family<List<Liability>, int>((ref, userId) {
  final db = ref.watch(databaseProvider);
  return db.watchLiabilities(userId).distinct();
});

// Net Worth History for user
final netWorthHistoryProvider = StreamProvider.autoDispose.family<List<NetWorthHistoryData>, int>((ref, userId) {
  final db = ref.watch(databaseProvider);
  return db.watchNetWorthHistory(userId).distinct();
});

// Envelopes for user/month/year
final envelopesProvider = StreamProvider.autoDispose.family<List<Envelope>, (int, int, int)>((ref, params) {
  final (userId, month, year) = params;
  final db = ref.watch(databaseProvider);
  return db.watchEnvelopes(userId, month, year).distinct();
});

// Monthly Income Provider
final monthlyIncomeProvider = StreamProvider.autoDispose.family<double, (int, int, int)>((ref, params) {
  final (userId, month, year) = params;
  final db = ref.watch(databaseProvider);
  
  return (db.select(db.incomes)..where((t) => t.userId.equals(userId))).watch().map((incomes) {
    return incomes.where((i) {
      final date = DateTime.parse(i.date);
      return date.month == month && date.year == year;
    }).fold(0.0, (sum, item) => sum + item.amount);
  });
});

// Monthly Allocations Provider
final monthlyAllocationsProvider = StreamProvider.autoDispose.family<double, (int, int, int)>((ref, params) {
  final (userId, month, year) = params;
  final db = ref.watch(databaseProvider);
  
  return db.watchEnvelopes(userId, month, year).map((envelopes) {
    return envelopes.fold(0.0, (sum, item) => sum + item.amount);
  });
});

// To Be Budgeted (Income - Allocations)
final toBeBudgetedProvider = Provider.autoDispose.family<AsyncValue<double>, (int, int, int)>((ref, params) {
  final incomeAsync = ref.watch(monthlyIncomeProvider(params));
  final allocationsAsync = ref.watch(monthlyAllocationsProvider(params));

  return incomeAsync.whenData((income) {
    return allocationsAsync.whenData((allocations) {
      return income - allocations;
    }).value ?? 0.0;
  });
});

