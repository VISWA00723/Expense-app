import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'category_rules.dart';

class AutoCategorizer {
  static const String _userRulesKey = 'user_category_rules';
  static Map<String, String> _userRules = {};
  static bool _initialized = false;

  /// Initialize and load user-learned rules
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rulesJson = prefs.getString(_userRulesKey);
      
      if (rulesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(rulesJson);
        _userRules = decoded.map((key, value) => MapEntry(key, value.toString()));
      }
      _initialized = true;
    } catch (e) {
      print('Error loading user category rules: $e');
    }
  }

  /// Detect category from text (transaction note/title)
  static String detectCategory(String text) {
    final lower = text.toLowerCase();

    // 1. Check User Learned Rules first (Priority)
    for (final key in _userRules.keys) {
      if (lower.contains(key.toLowerCase())) {
        return _userRules[key]!;
      }
    }

    // 2. Check Static Rules
    for (final key in CategoryRules.keywordCategories.keys) {
      if (lower.contains(key)) {
        return CategoryRules.keywordCategories[key]!;
      }
    }

    return "Miscellaneous"; // Default fallback
  }

  /// Learn a new rule from user correction
  static Future<void> learnRule(String text, String correctCategory) async {
    // Extract a meaningful keyword? 
    // For simplicity, we'll map the exact text or the first significant word.
    // But mapping the whole text might be too specific.
    // Let's map the input text itself as a keyword if it's short, 
    // or just store it as is.
    
    // Better approach: If the user manually selects a category for a title "Zomato",
    // we map "zomato" -> "Food".
    
    final keyword = text.trim().toLowerCase();
    if (keyword.isEmpty) return;

    // Update memory
    _userRules[keyword] = correctCategory;

    // Persist
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRulesKey, jsonEncode(_userRules));
    } catch (e) {
      print('Error saving user category rule: $e');
    }
  }
}
