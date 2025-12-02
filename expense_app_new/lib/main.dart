import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:expense_app_new/screens/dashboard_screen.dart';
import 'package:expense_app_new/screens/add_expense_screen.dart';
import 'package:expense_app_new/screens/expense_list_screen.dart';
import 'package:expense_app_new/screens/ai_assistant_screen.dart';
import 'package:expense_app_new/screens/profile_screen.dart';
import 'package:expense_app_new/screens/reports_screen.dart';
import 'package:expense_app_new/screens/budget_screen.dart';
import 'package:expense_app_new/screens/auth/login_screen.dart';
import 'package:expense_app_new/screens/auth/signup_screen.dart';
import 'package:expense_app_new/screens/auth/profile_setup_screen.dart';
import 'package:expense_app_new/screens/onboarding_screen.dart';
import 'package:expense_app_new/screens/achievements_screen.dart';
import 'package:expense_app_new/screens/recurring_expenses_screen.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/theme/app_theme.dart';
import 'package:expense_app_new/services/adaptive_refresh_rate.dart';
import 'package:expense_app_new/providers/theme_provider.dart';
import 'package:expense_app_new/services/notification_service.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:expense_app_new/screens/voice_overlay_screen.dart';
import 'package:expense_app_new/services/bootstrap_service.dart';
import 'package:expense_app_new/screens/splash_screen.dart';
import 'package:expense_app_new/screens/user_guide_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'package:expense_app_new/services/backup_service.dart';
import 'package:expense_app_new/screens/settings/backup_settings_screen.dart';
import 'package:expense_app_new/screens/add_category_screen.dart';
import 'package:expense_app_new/services/gamification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'autoBackup') {
      try {
        // Ensure Flutter bindings are initialized for path_provider
        WidgetsFlutterBinding.ensureInitialized();
        await BackupService.createBackup(isManual: false);
        return Future.value(true);
      } catch (e) {
        print('Auto backup failed: $e');
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // Check bootstrap state
      final bootstrapState = ref.watch(bootstrapStateProvider);
      
      // If not initialized, show splash
      if (bootstrapState != BootstrapState.complete) {
        return '/splash';
      }

      // Check if user is authenticated
      final isAuthenticated = ref.watch(isAuthenticatedProvider);
      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation == '/signup';
      final isSettingUp = state.matchedLocation == '/profile-setup';
      final isSplash = state.matchedLocation == '/splash';

      // If on splash and initialized, go to login (which will redirect to dashboard if auth)
      if (isSplash) {
        return isAuthenticated ? '/dashboard' : '/login';
      }

      // If not authenticated, redirect to login
      if (!isAuthenticated && !isLoggingIn && !isSigningUp && !isSettingUp) {
        return '/login';
      }

      // If authenticated and trying to access auth routes, redirect to dashboard
      if (isAuthenticated && (isLoggingIn || isSigningUp)) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      // Main Routes
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: '/list',
        builder: (context, state) => const ExpenseListScreen(),
      ),
      GoRoute(
        path: '/ai',
        builder: (context, state) {
          final initialMessage = state.extra as String?;
          return AIAssistantScreen(initialMessage: initialMessage);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/budget',
        builder: (context, state) => const BudgetScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/recurring-expenses',
        builder: (context, state) => const RecurringExpensesScreen(),
      ),
      GoRoute(
        path: '/voice',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const VoiceOverlayScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.5),
          barrierDismissible: true,
        ),
      ),
      GoRoute(
        path: '/user-guide',
        builder: (context, state) => const UserGuideScreen(),
      ),
      GoRoute(
        path: '/backup-settings',
        builder: (context, state) => const BackupSettingsScreen(),
      ),
      GoRoute(
        path: '/add-category',
        builder: (context, state) => const AddCategoryScreen(),
      ),
    ],
  );
});

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Workmanager for background tasks
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Firebase and Notification init moved to BootstrapService
  
  AdaptiveRefreshRate.enableAdaptiveRefreshRate();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupQuickActions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        print('🔄 [App] Resumed from background, updating streak...');
        ref.read(gamificationServiceProvider).updateStreak(user.id);
      }
    }
  }

  void _setupQuickActions() {
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((shortcutType) {
      if (shortcutType == 'voice_add') {
        // Navigate to voice screen
        // We need to wait for the app to be ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final router = ref.read(goRouterProvider);
          router.push('/voice');
        });
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'voice_add',
        localizedTitle: 'Voice Add',
        icon: 'mic', // Requires 'mic' icon in android/app/src/main/res/drawable
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeState = ref.watch(themeProvider);
    
    ThemeData lightTheme;
    if (themeState.lightStyle == 'pink') {
      lightTheme = AppTheme.lightThemePink;
    } else {
      lightTheme = AppTheme.lightTheme;
    }

    return MaterialApp.router(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: themeState.darkStyle == 'black' 
          ? AppTheme.darkThemeBlack 
          : AppTheme.darkThemePurple,
      themeMode: themeState.mode,
      routerConfig: router,
    );
  }
}
