import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/services/api_service.dart';
import 'package:expense_app_new/models/expense_model.dart';
import 'package:intl/intl.dart';

class FinancialAdvisorService {
  final AppDatabase _db;
  final ApiService _apiService;

  FinancialAdvisorService(this._db, this._apiService);

  // Generate a daily insight using Real AI
  Future<String> getDailyInsight(int userId) async {
    try {
      // 1. Fetch expenses for the CURRENT MONTH to give relevant context
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final dateFormat = DateFormat('yyyy-MM-dd');
      
      final recentExpenses = await (_db.select(_db.expenses)
        ..where((t) => t.userId.equals(userId) & t.date.isBiggerOrEqualValue(dateFormat.format(startOfMonth)))
        ..orderBy([(t) => OrderingTerm.desc(t.date)])
        // Remove limit to get full month context, or set a higher limit if worried about tokens
        ..limit(50) 
      ).get();

      if (recentExpenses.isEmpty) {
        return "No expenses this month yet. Start spending (wisely) to get insights!";
      }

      // Convert to ExpenseModel for API
      final expenseModels = recentExpenses.map((e) => ExpenseModel(
        id: e.id,
        title: e.title,
        amount: e.amount,
        date: e.date,
        category: 'Unknown',
        notes: e.notes,
        createdAt: e.createdAt,
      )).toList();

      // 2. Ask AI for an insight
      final response = await _apiService.analyzeExpenses(
        question: "Analyze these expenses for the current month. Give me a VERY short, single-sentence insight or tip (max 15 words). Focus on the highest spending category or a specific unusual expense. Be friendly.",
        expenses: expenseModels,
      );

      return response.answer;
    } catch (e) {
      print('❌ [Advisor] Failed to get AI insight: $e');
      // Fallback to basic logic if AI fails (offline, etc.)
      return _getBasicInsight(userId);
    }
  }

  // Fallback basic logic
  Future<String> _getBasicInsight(int userId) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
    
    final yesterdayExpenses = await (_db.select(_db.expenses)
      ..where((t) => t.userId.equals(userId) & t.date.like('$yesterdayStr%'))
    ).get();

    final yesterdayTotal = yesterdayExpenses.fold(0.0, (sum, e) => sum + e.amount);

    if (yesterdayTotal > 2000) {
      return "You spent ₹${yesterdayTotal.toStringAsFixed(0)} yesterday. Try to save more today!";
    }
    return "Track every rupee to reach your financial goals faster!";
  }

  // Analyze monthly spending trends
  Future<List<String>> analyzeMonthlyTrends(int userId) async {
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);
    final lastMonth = DateFormat('yyyy-MM').format(DateTime(now.year, now.month - 1, 1));

    final currentTotal = await _db.getTotalByMonth(userId, currentMonth);
    final lastTotal = await _db.getTotalByMonth(userId, lastMonth);

    final insights = <String>[];

    if (lastTotal > 0) {
      final diff = currentTotal - lastTotal;
      final percent = (diff / lastTotal) * 100;
      
      if (percent > 10) {
        insights.add("Spending is up ${percent.toStringAsFixed(1)}% compared to last month.");
      } else if (percent < -10) {
        insights.add("Great job! Spending is down ${percent.abs().toStringAsFixed(1)}% compared to last month.");
      }
    }

    return insights;
  }
}

final financialAdvisorServiceProvider = Provider<FinancialAdvisorService>((ref) {
  final db = ref.watch(databaseProvider);
  final apiService = ref.watch(apiServiceProvider);
  return FinancialAdvisorService(db, apiService);
});
