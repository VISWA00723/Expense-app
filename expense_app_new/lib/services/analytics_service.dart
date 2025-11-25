import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static void _log(String event, [Map<String, dynamic>? params]) {
    if (kDebugMode) {
      print('📊 Analytics: $event ${params != null ? params.toString() : ""}');
    }
  }
  
  // Screen tracking
  static Future<void> logScreenView(String screenName) async {
    _log('Screen View', {'screen': screenName});
    await _analytics.logScreenView(screenName: screenName);
  }
  
  // Auth events
  static Future<void> logLogin(String method) async {
    _log('Login', {'method': method});
    await _analytics.logLogin(loginMethod: method);
  }
  
  static Future<void> logSignUp(String method) async {
    _log('Sign Up', {'method': method});
    await _analytics.logSignUp(signUpMethod: method);
  }
  
  // Expense events
  static Future<void> logExpenseAdded({
    required String category,
    required double amount,
  }) async {
    _log('Expense Added', {'category': category, 'amount': amount});
    await _analytics.logEvent(
      name: 'expense_added',
      parameters: {
        'category': category,
        'amount': amount,
      },
    );
  }
  
  static Future<void> logExpenseEdited({
    required String category,
    required double amount,
  }) async {
    _log('Expense Edited', {'category': category, 'amount': amount});
    await _analytics.logEvent(
      name: 'expense_edited',
      parameters: {
        'category': category,
        'amount': amount,
      },
    );
  }
  
  static Future<void> logExpenseDeleted() async {
    _log('Expense Deleted');
    await _analytics.logEvent(name: 'expense_deleted');
  }
  
  // Budget events
  static Future<void> logBudgetSet({
    required String category,
    required double amount,
  }) async {
    _log('Budget Set', {'category': category, 'amount': amount});
    await _analytics.logEvent(
      name: 'budget_set',
      parameters: {
        'category': category,
        'amount': amount,
      },
    );
  }
  
  // AI events
  static Future<void> logAIChat({
    required int queryLength,
    String? feature,
  }) async {
    _log('AI Chat', {'query_length': queryLength, 'feature': feature});
    await _analytics.logEvent(
      name: 'ai_chat',
      parameters: {
        'query_length': queryLength,
        if (feature != null) 'feature': feature,
      },
    );
  }
  
  static Future<void> logInvestmentPlanGenerated() async {
    _log('Investment Plan Generated');
    await _analytics.logEvent(name: 'investment_plan_generated');
  }
  
  // Report events
  static Future<void> logReportGenerated(String reportType) async {
    _log('Report Generated', {'type': reportType});
    await _analytics.logEvent(
      name: 'report_generated',
      parameters: {'report_type': reportType},
    );
  }
  
  // Theme events
  static Future<void> logThemeChanged({
    required String themeMode,
    required String darkStyle,
  }) async {
    _log('Theme Changed', {'mode': themeMode, 'style': darkStyle});
    await _analytics.logEvent(
      name: 'theme_changed',
      parameters: {
        'theme_mode': themeMode,
        'dark_style': darkStyle,
      },
    );
  }
}
