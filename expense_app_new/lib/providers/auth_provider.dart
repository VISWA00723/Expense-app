import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/services/auth_service.dart';
import 'package:expense_app_new/services/session_service.dart';
import 'package:expense_app_new/providers/database_provider.dart';

import 'package:expense_app_new/services/gamification_service.dart';
import 'package:expense_app_new/services/recurring_expense_service.dart';

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final db = ref.watch(databaseProvider);
  final sessionService = ref.watch(sessionServiceProvider);
  final gamificationService = ref.watch(gamificationServiceProvider);
  return AuthService(
    db: db, 
    sessionService: sessionService,
    gamificationService: gamificationService,
  );
});

// Restore session on app startup
final restoreSessionProvider = FutureProvider<User?>((ref) async {
  final sessionService = ref.watch(sessionServiceProvider);
  final db = ref.watch(databaseProvider);
  
  try {
    final userId = await sessionService.getUserId();
    if (userId != null) {
      final user = await db.getUserById(userId);
      if (user != null) {
        // Update auth service with restored user
        final authService = ref.watch(authServiceProvider);
        authService.setCurrentUser(user);

        // Ensure gamification is initialized
        final gamificationService = ref.read(gamificationServiceProvider);
        await gamificationService.ensureInitialized(user.id);

        // Check for due recurring expenses
        final recurringService = ref.read(recurringExpenseServiceProvider);
        await recurringService.checkAndCreateDueExpenses(user.id);

        return user;
      }
    }
  } catch (e) {
    print('❌ [Session] Failed to restore session: $e');
  }
  return null;
});

final currentUserProvider = StateProvider<User?>((ref) {
  // Try to restore session first
  final restoredUser = ref.watch(restoreSessionProvider).value;
  if (restoredUser != null) {
    return restoredUser;
  }
  
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

final userIdProvider = Provider<int?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
});
