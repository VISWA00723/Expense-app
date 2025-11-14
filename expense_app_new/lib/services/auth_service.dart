import 'package:drift/drift.dart' as drift;
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/services/session_service.dart';
import 'package:intl/intl.dart';

class AuthService {
  final AppDatabase db;
  final SessionService? sessionService;
  User? _currentUser;

  AuthService({required this.db, this.sessionService});

  User? get currentUser => _currentUser;

  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String name,
    required String lifestyle,
    required double monthlySalary,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await db.getUserByEmail(email);
      if (existingUser != null) {
        return false;
      }

      final now = DateTime.now().toIso8601String();
      final user = UsersCompanion(
        email: drift.Value(email),
        password: drift.Value(password), // In production, hash this!
        name: drift.Value(name),
        lifestyle: drift.Value(lifestyle),
        monthlySalary: drift.Value(monthlySalary),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      );

      await db.createUser(user);
      
      // Auto-login after signup
      return await login(email: email, password: password);
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await db.getUserByEmail(email);
      if (user == null) {
        return false;
      }

      // In production, use proper password hashing (bcrypt)
      if (user.password != password) {
        return false;
      }

      _currentUser = user;
      
      // Save session for persistence
      if (sessionService != null) {
        try {
          await sessionService!.saveSession(
            userId: user.id,
            email: user.email,
            name: user.name,
          );
        } catch (e) {
          print('Error saving session: $e');
          // Continue even if session save fails
        }
      }
      
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    // Clear saved session
    if (sessionService != null) {
      try {
        await sessionService!.clearSession();
      } catch (e) {
        print('Error clearing session: $e');
      }
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String lifestyle,
    required double monthlySalary,
  }) async {
    if (_currentUser == null) return false;

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name,
        lifestyle: lifestyle,
        monthlySalary: monthlySalary,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await db.updateUser(updatedUser);
      _currentUser = updatedUser;
      return true;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }

  Future<bool> verifyPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await db.getUserByEmail(email);
      if (user == null) {
        return false;
      }

      // In production, use proper password hashing (bcrypt)
      return user.password == password;
    } catch (e) {
      print('Verify password error: $e');
      return false;
    }
  }

  Future<bool> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Verify current password
      final isValid = await verifyPassword(
        email: email,
        password: currentPassword,
      );

      if (!isValid) {
        return false;
      }

      // Get user and update password
      final user = await db.getUserByEmail(email);
      if (user == null) {
        return false;
      }

      final updatedUser = user.copyWith(
        password: newPassword,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await db.updateUser(updatedUser);
      _currentUser = updatedUser;
      return true;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }
}
