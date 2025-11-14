import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _isLoggedInKey = 'is_logged_in';

  SharedPreferences? _prefs;

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Ensure initialized
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // Save user session
  Future<void> saveSession({
    required int userId,
    required String email,
    required String name,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, name);
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Get saved user ID
  Future<int?> getUserId() async {
    final prefs = await _getPrefs();
    if (prefs.containsKey(_userIdKey)) {
      return prefs.getInt(_userIdKey);
    }
    return null;
  }

  // Get saved email
  Future<String?> getUserEmail() async {
    final prefs = await _getPrefs();
    if (prefs.containsKey(_userEmailKey)) {
      return prefs.getString(_userEmailKey);
    }
    return null;
  }

  // Get saved name
  Future<String?> getUserName() async {
    final prefs = await _getPrefs();
    if (prefs.containsKey(_userNameKey)) {
      return prefs.getString(_userNameKey);
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Clear session
  Future<void> clearSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_isLoggedInKey);
  }

  // Check if session exists
  Future<bool> hasSession() async {
    final prefs = await _getPrefs();
    return prefs.containsKey(_userIdKey) && prefs.containsKey(_userEmailKey);
  }
}
