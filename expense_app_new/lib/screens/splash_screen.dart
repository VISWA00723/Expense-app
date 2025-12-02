import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_app_new/services/bootstrap_service.dart';
import 'package:expense_app_new/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bootstrapServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch initialization state
    ref.listen(bootstrapStateProvider, (previous, next) {
      if (next == BootstrapState.complete) {
        // Navigate to appropriate screen based on auth state
        // The router redirect logic will handle the actual destination (login vs dashboard)
        // We just need to trigger a refresh or let the router know we are ready.
        // Since GoRouter listens to auth state, and auth state might depend on init,
        // we might need to refresh the router.
        // For now, let's just go to the root, and let the router redirect.
        context.go('/login'); 
      } else if (next == BootstrapState.error) {
        // Show error
        final error = ref.read(bootstrapErrorProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize: $error'),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                ref.read(bootstrapServiceProvider).init();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or App Name
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Expense Tracker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Getting things ready...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
