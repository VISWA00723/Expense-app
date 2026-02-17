import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:expense_app_new/services/notification_service.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/services/gamification_service.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/services/recurring_expense_service.dart';

// Provider to track the initialization state
final bootstrapStateProvider = StateProvider<BootstrapState>((ref) => BootstrapState.initial);

enum BootstrapState {
  initial,
  initializing,
  complete,
  error,
}

final bootstrapErrorProvider = StateProvider<String?>((ref) => null);

final bootstrapServiceProvider = Provider<BootstrapService>((ref) {
  return BootstrapService(ref);
});

class BootstrapService {
  final Ref ref;

  BootstrapService(this.ref);

  Future<void> init() async {
    final state = ref.read(bootstrapStateProvider);
    if (state == BootstrapState.initializing || state == BootstrapState.complete) {
      return;
    }

    ref.read(bootstrapStateProvider.notifier).state = BootstrapState.initializing;

    try {
      print('🚀 [Bootstrap] Starting initialization...');
      
      // 1. Initialize Firebase (Resilient)
      final firebaseFuture = Firebase.initializeApp().then((_) {
        print('✅ [Bootstrap] Firebase initialized');
      }).catchError((e) {
        print('⚠️ [Bootstrap] Firebase init failed: $e');
        // Don't rethrow, allow app to start
      });

      // 2. Initialize Notifications (Resilient)
      final notificationFuture = NotificationService.initialize().then((_) {
        print('✅ [Bootstrap] Notifications initialized');
      }).catchError((e) {
        print('⚠️ [Bootstrap] Notification init failed: $e');
        // Don't rethrow, allow app to start
      });

      // 3. Warm up Database (Critical)
      // Just accessing the provider creates the DB instance
      final db = ref.read(databaseProvider);
      final dbFuture = db.customSelect('SELECT 1').getSingle().then((_) {
        print('✅ [Bootstrap] Database warmed up');
      });

      // Wait for all (even if some failed, they completed with void)
      await Future.wait([
        firebaseFuture,
        notificationFuture,
        dbFuture,
      ]);

      // 4. Non-critical background tasks (Fire and Forget)
      _runBackgroundTasks();

      print('✨ [Bootstrap] Initialization complete');
      ref.read(bootstrapStateProvider.notifier).state = BootstrapState.complete;
    } catch (e, stack) {
      print('🔴 [Bootstrap] Initialization failed: $e');
      print(stack);
      ref.read(bootstrapErrorProvider.notifier).state = e.toString();
      ref.read(bootstrapStateProvider.notifier).state = BootstrapState.error;
    }
  }

  void _runBackgroundTasks() {
    // These can run after the UI is ready
    Future.delayed(const Duration(seconds: 1), () {
      try {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          print('🔄 [Bootstrap] Running background user tasks...');
          final gamification = ref.read(gamificationServiceProvider);
          gamification.ensureInitialized(user.id);
          gamification.updateStreak(user.id);
          
          // Pre-fetch commonly used data to warm up cache
          ref.read(databaseProvider).getExpenseCount(user.id);

          // Check for due recurring expenses
          final recurringService = ref.read(recurringExpenseServiceProvider);
          recurringService.checkAndCreateDueExpenses(user.id);
        }
      } catch (e) {
        print('⚠️ [Bootstrap] Background task error: $e');
      }
    });
  }
}
