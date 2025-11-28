import 'dart:io';
import 'dart:convert';
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
    baseUrl = 'https://expense-tacker-backend.netlify.app';
    
    // Optimize for low-end devices - Increased timeouts for AI processing
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 45);
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
      print('❌ [API] DioException occurred: ${e.message}');
      throw Exception('API Error: ${e.message}');
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
      
      // Check if this is a receipt analysis request
      if (naturalLanguageInput.startsWith('Analyze Receipt:')) {
        print('🧾 [AI] Detected receipt analysis request');
        final cleanedText = naturalLanguageInput.replaceFirst('Analyze Receipt:', '').trim();
        
        // Stage 2: Extract structured data
        final structuredData = await extractReceiptData(cleanedText, availableCategories);
        
        // Stage 3: Calculate totals locally
        double calculatedTotal = 0;
        List<String> lineItems = [];
        
        if (structuredData['items'] is List) {
          for (var item in structuredData['items']) {
            // Verify item is a Map
            if (item is! Map) {
              print('⚠️ [AI] Skipping invalid item (not a Map): $item');
              continue;
            }

            final name = item['name']?.toString() ?? 'Item';
            
            // Helper to safely parse doubles from various types
            double safeDouble(dynamic value, [double defaultValue = 0.0]) {
              if (value == null) return defaultValue;
              if (value is num) return value.toDouble();
              if (value is String) {
                // Remove currency symbols and commas
                final clean = value.replaceAll(RegExp(r'[^\d.-]'), '');
                return double.tryParse(clean) ?? defaultValue;
              }
              return defaultValue;
            }

            final qty = safeDouble(item['quantity'], 1.0);
            final price = safeDouble(item['unit_price']);
            final explicitTotal = safeDouble(item['total_price']);
            
            // Use explicit total if available, otherwise calculate
            final total = explicitTotal > 0 ? explicitTotal : (qty * price);
            
            // Only add positive totals
            if (total > 0) {
              calculatedTotal += total;
              lineItems.add('$name: ${total.toStringAsFixed(2)}');
            }
          }
        }
        
        // Construct ExpenseData
        final expenseData = ExpenseData(
          title: structuredData['vendor'] ?? 'Scanned Receipt',
          amount: calculatedTotal,
          category: structuredData['category'] ?? 'Uncategorized',
          notes: lineItems.join('\n'),
          date: structuredData['date'] ?? DateTime.now().toIso8601String(),
        );
        
        return AIResponse(
          answer: 'Expense added successfully. Total calculated: ${calculatedTotal.toStringAsFixed(2)}',
          expenseData: expenseData,
        );
      }

      // Standard Natural Language Processing
      print('📝 [AI] Input: $naturalLanguageInput');

      final response = await _dio.post(
        '$baseUrl/add-expense',
        data: {
          'input': naturalLanguageInput,
          'recentExpenses': recentExpenses.map((e) => e.toJson()).toList(),
          'availableCategories': availableCategories,
          'currentDate': DateTime.now().toIso8601String(),
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

  // Stage 2: Extract structured data using LLM (No calculations)
  Future<Map<String, dynamic>> extractReceiptData(String cleanedText, List<String> availableCategories) async {
    try {
      print('🤖 [AI] Extracting structured data from receipt...');
      print('📄 [AI] Cleaned text length: ${cleanedText.length}');
      
      final prompt = '''
      Clean and normalize this OCR text from a receipt/bill.
      
      ---OCR START---
      $cleanedText
      ---OCR END---

      AVAILABLE CATEGORIES:
      ${availableCategories.join(', ')}

      OUTPUT INSTRUCTIONS:
      1. Output ONLY valid JSON. No markdown formatting, no explanations.
      2. Extract the Vendor Name (e.g., Hospital, Store).
      3. Extract the Date (YYYY-MM-DD).
      4. Extract line items with "name", "quantity" (default 1), "unit_price", and "total_price".
      5. DO NOT CALCULATE TOTALS. Just extract the numbers you see.
      6. If a line has "3000/day" and "4 days", extract unit_price: 3000, quantity: 4.
      7. If a line just has a final amount (e.g. "Surgery 50000"), put it in "total_price".
      8. Select the best matching CATEGORY from the available list. If unsure, use "Uncategorized" or the most generic one.
      
      JSON FORMAT:
      {
        "vendor": "String",
        "date": "YYYY-MM-DD",
        "category": "String",
        "items": [
          {
            "name": "String",
            "quantity": Number,
            "unit_price": Number,
            "total_price": Number
          }
        ]
      }
      ''';

      print('🚀 [AI] Sending request to backend...');
      // Use analyze endpoint as it allows free-form text response
      final response = await _dio.post(
        '$baseUrl/analyze',
        data: {
          'question': prompt,
          'expenses': [], // No context needed
        },
      );

      print('✅ [AI] Response received: ${response.statusCode}');
      print('📦 [AI] Raw response data: ${response.data}');

      if (response.statusCode == 200) {
        final aiResponse = AIResponse.fromJson(response.data);
        final jsonStr = aiResponse.answer;
        
        print('📝 [AI] AI Answer: $jsonStr');
        
        // Clean up JSON string if it contains markdown code blocks
        final cleanJson = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();
        
        print('🧹 [AI] Cleaned JSON string: $cleanJson');
        
        // Parse JSON locally
        try {
          final parsed = jsonDecode(cleanJson);
          print('🎉 [AI] JSON parsed successfully');
          return parsed;
        } catch (e) {
          print('❌ [AI] JSON parsing failed: $e');
          throw Exception('Failed to parse AI response as JSON: $e');
        }
      } else {
        throw Exception('Failed to extract data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AI] Extraction failed: $e');
      if (e is DioException) {
        print('🔴 [AI] Dio Error Type: ${e.type}');
        print('🔴 [AI] Dio Error Message: ${e.message}');
        print('🔴 [AI] Dio Response: ${e.response?.data}');
      }
      throw Exception('Failed to extract data: $e');
    }
  }
}
