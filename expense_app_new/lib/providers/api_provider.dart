import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_app_new/services/api_service.dart';
import 'package:expense_app_new/models/expense_model.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final analyzeExpensesProvider = FutureProvider.family<
    dynamic,
    ({String question, List<ExpenseModel> expenses})>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.analyzeExpenses(
    question: params.question,
    expenses: params.expenses,
  );
});
