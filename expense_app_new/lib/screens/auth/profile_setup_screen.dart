import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/data/categories_data.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _salaryController = TextEditingController();
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _setupCategories() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final db = ref.read(databaseProvider);
    final categories =
        PredefinedCategories.getCategoriesForLifestyle(user.lifestyle);

    for (final category in categories) {
      await db.addCategory(
        ExpenseCategoriesCompanion(
          userId: drift.Value(user.id),
          name: drift.Value(category.name),
          icon: drift.Value(category.icon),
          isCustom: drift.Value(false),
          createdAt: drift.Value(DateTime.now().toIso8601String()),
        ),
      );
    }
  }

  Future<void> _handleContinue() async {
    if (_currentStep == 0) {
      if (_salaryController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your monthly salary')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final salary = double.parse(_salaryController.text);
        final authService = ref.read(authServiceProvider);
        await authService.updateProfile(
          name: authService.currentUser!.name,
          lifestyle: authService.currentUser!.lifestyle,
          monthlySalary: salary,
        );

        ref.read(currentUserProvider.notifier).state =
            authService.currentUser;

        setState(() {
          _currentStep = 1;
          _isLoading = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid salary amount')),
        );
        setState(() => _isLoading = false);
      }
    } else {
      // Setup categories
      setState(() => _isLoading = true);
      try {
        await _setupCategories();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categories loaded successfully!')),
        );
        context.go('/onboarding');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting up categories: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentStep + 1) / 2,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 32),

              if (_currentStep == 0) ...[
                Text(
                  'Set Your Monthly Salary',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This helps us calculate your remaining balance',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Monthly Salary',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _salaryController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            hintText: '50,000',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Select Your Categories',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ve prepared ${_getCategoryCount(user?.lifestyle ?? 'bachelor')} categories for your lifestyle',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All set!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your expense categories are ready',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_currentStep == 0 ? 'Continue' : 'Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getCategoryCount(String lifestyle) {
    switch (lifestyle.toLowerCase()) {
      case 'bachelor':
        return PredefinedCategories.bachelorCategories.length;
      case 'married':
        return PredefinedCategories.marriedCategories.length;
      case 'family':
        return PredefinedCategories.familyCategories.length;
      default:
        return 0;
    }
  }
}
