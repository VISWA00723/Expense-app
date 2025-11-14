import 'dart:io';
import 'package:dio/dio.dart';
import 'package:expense_app_new/models/expense_model.dart';

class AIResponse {
  final String answer;
  final ExpenseData? expenseData;

  AIResponse({required this.answer, this.expenseData});

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      answer: json['answer'] ?? '',
      expenseData: json['expenseData'] != null
          ? ExpenseData.fromJson(json['expenseData'])
          : null,
    );
  }
}

class ExpenseData {
  final String title;
  final double amount;
  final String category;
  final String? notes;
  final String date;

  ExpenseData({
    required this.title,
    required this.amount,
    required this.category,
    this.notes,
    required this.date,
  });

  factory ExpenseData.fromJson(Map<String, dynamic> json) {
    return ExpenseData(
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      notes: json['notes'],
      date: json['date'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'category': category,
    'notes': notes,
    'date': date,
  };
}

class ApiService {
  final Dio _dio;
  late final String baseUrl;

  ApiService({Dio? dio}) : _dio = dio ?? Dio() {
    // Use Netlify backend URL for production
    // For local development, uncomment the localhost/10.0.2.2 URLs
    baseUrl = 'https://expense-tacker-backend.netlify.app';
    
    // Uncomment below for local development:
    // if (Platform.isAndroid) {
    //   baseUrl = 'http://10.0.2.2:3000';
    // } else {
    //   baseUrl = 'http://localhost:3000';
    // }
    
    // Optimize for low-end devices
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  Future<AIResponse> analyzeExpenses({
    required String question,
    required List<ExpenseModel> expenses,
  }) async {
    try {
      print('🔍 [API] Starting request...');
      print('📍 [API] URL: $baseUrl/analyze');
      print('❓ [API] Question: $question');
      print('📊 [API] Expenses count: ${expenses.length}');

      final response = await _dio.post(
        '$baseUrl/analyze',
        data: {
          'question': question,
          'expenses': expenses.map((e) => e.toJson()).toList(),
        },
      );

      print('✅ [API] Response received: ${response.statusCode}');
      print('📦 [API] Response data: ${response.data}');

      if (response.statusCode == 200) {
        return AIResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to analyze expenses: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [API] DioException occurred');
      print('🔴 [API] Error type: ${e.type}');
      print('🔴 [API] Error message: ${e.message}');
      print('🔴 [API] Error response: ${e.response?.data}');
      print('🔴 [API] Error status: ${e.response?.statusCode}');
      
      String errorMessage = 'API Error: ${e.message}';
      
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout - Backend not responding';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Response timeout - Backend slow or not responding';
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = 'Network error - Check internet connection';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ [API] Unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // New method to add expense via AI
  Future<AIResponse> addExpenseWithAI({
    required String naturalLanguageInput,
    required List<ExpenseModel> recentExpenses,
    required List<String> availableCategories,
  }) async {
    try {
      print('🤖 [AI] Processing natural language expense input...');
      print('📝 [AI] Input: $naturalLanguageInput');
      print('📂 [AI] Available categories: ${availableCategories.length}');

      final response = await _dio.post(
        '$baseUrl/add-expense',
        data: {
          'input': naturalLanguageInput,
          'recentExpenses': recentExpenses.map((e) => e.toJson()).toList(),
          'availableCategories': availableCategories,
        },
      );

      print('✅ [AI] Expense parsed successfully');
      print('📦 [AI] Parsed data: ${response.data}');

      if (response.statusCode == 200) {
        return AIResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to parse expense: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [AI] Failed to parse expense');
      throw Exception('Failed to parse expense: ${e.message}');
    }
  }
}
