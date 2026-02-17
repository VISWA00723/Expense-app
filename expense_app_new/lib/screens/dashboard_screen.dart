import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/services/color_service.dart';
import 'package:expense_app_new/theme/app_theme.dart';
import 'package:expense_app_new/services/analytics_service.dart';
import 'package:expense_app_new/widgets/notification_permission_dialog.dart';
import 'package:expense_app_new/services/gamification_service.dart';
import 'package:expense_app_new/services/financial_advisor_service.dart';
import 'package:expense_app_new/widgets/app_bottom_bar.dart';
import 'package:expense_app_new/services/recurring_expense_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import 'package:expense_app_new/widgets/expense_pie_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Track screen view
    AnalyticsService.logScreenView('dashboard');

    // Show notification permission dialog on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationPermissionDialog.showIfNeeded(context);
      
      // Check for due recurring expenses
      ref.read(recurringExpenseServiceProvider).checkAndCreateDueExpenses(user.id);
    });

    // Check if profile setup is complete
    if (user.monthlySalary == 0) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 64),
              const SizedBox(height: 16),
              const Text('Profile Setup Required'),
              const SizedBox(height: 8),
              const Text('Please complete your profile setup first'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/profile-setup'),
                child: const Text('Go to Profile Setup'),
              ),
            ],
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE').format(DateTime.now()).toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                DateFormat('d MMM').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () => context.push('/envelope-budget'),
            tooltip: 'Envelope Budget',
          ),
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () => context.push('/reports'),
            tooltip: 'Reports',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authServiceProvider).logout();
              ref.read(currentUserProvider.notifier).state = null;
              context.go('/login');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.0,
                          ),
                    ),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 1. Wellness & Net Worth (Top Stats)
            Row(
              children: [
                Expanded(child: _WellnessScoreCard(userId: user.id, isCompact: true)),
                const SizedBox(width: 12),
                Expanded(child: _NetWorthCard(userId: user.id, isCompact: true)),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Daily Insight (Contextual Tip)
            _DailyInsightCard(userId: user.id),
            const SizedBox(height: 16),
            const SizedBox(height: 24),

            // Salary Overview Card
            _SalaryOverviewCard(user: user),
            const SizedBox(height: 32),

            // Spending by Category
            Text(
              'Spending Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ExpensePieChart(userId: user.id),
            const SizedBox(height: 32),

            // Recent Expenses
            _RecentExpenses(userId: user.id),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomBar(currentIndex: 0),
    );
  }
}

class _SalaryOverviewCard extends ConsumerStatefulWidget {
  final User user;
  const _SalaryOverviewCard({required this.user});

  @override
  ConsumerState<_SalaryOverviewCard> createState() => _SalaryOverviewCardState();
}

class _SalaryOverviewCardState extends ConsumerState<_SalaryOverviewCard> {
  bool _isBudgetVisible = true;
  final LocalAuthentication auth = LocalAuthentication();

  Future<void> _toggleBudgetVisibility() async {
    if (_isBudgetVisible) {
      // Hide immediately
      setState(() => _isBudgetVisible = false);
    } else {
      // Authenticate to show
      try {
        final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
        final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

        if (!canAuthenticate) {
          // Fallback if no auth available
          setState(() => _isBudgetVisible = true);
          return;
        }

        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to view budget details',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (didAuthenticate) {
          setState(() => _isBudgetVisible = true);
        }
      } on PlatformException catch (e) {
        print('Auth Error: $e');
        // Optional: Show error snackbar
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);
    final prevMonthDate = DateTime(now.year, now.month - 1);
    final prevMonth = DateFormat('yyyy-MM').format(prevMonthDate);

    final currentMonthTotalAsync = ref.watch(currentMonthTotalProvider((widget.user.id, currentMonth)));
    final prevMonthTotalAsync = ref.watch(currentMonthTotalProvider((widget.user.id, prevMonth)));

    final currentSpent = currentMonthTotalAsync.value ?? 0.0;
    final prevSpent = prevMonthTotalAsync.value ?? 0.0;
    final remaining = (widget.user.monthlySalary) - currentSpent;
    
    final spendPercentage = (currentSpent / widget.user.monthlySalary).clamp(0.0, 1.0);
    
    // Threshold Colors
    Color statusColor;
    if (spendPercentage < 0.5) {
      statusColor = Colors.greenAccent;
    } else if (spendPercentage < 0.8) {
      statusColor = Colors.orangeAccent;
    } else {
      statusColor = Colors.redAccent;
    }

    // Trend Logic
    final isSpendingMore = currentSpent > prevSpent;
    final trendDiff = (currentSpent - prevSpent).abs();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                left: -20,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Remaining Budget',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isBudgetVisible 
                                  ? '₹${remaining.toStringAsFixed(2)}' 
                                  : '••••••',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _toggleBudgetVisibility,
                              icon: Icon(
                                _isBudgetVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              tooltip: _isBudgetVisible ? 'Hide Balance' : 'Show Balance',
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: prevSpent == 0 
                                  ? const Text(
                                      'New',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        Icon(
                                          isSpendingMore ? Icons.trending_up : Icons.trending_down,
                                          color: isSpendingMore ? Colors.redAccent : Colors.greenAccent,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${((trendDiff / prevSpent) * 100).abs().toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Progress Bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spent',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${(spendPercentage * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    begin: 0, 
                                    end: spendPercentage
                                  ),
                                  duration: const Duration(milliseconds: 1500),
                                  curve: Curves.easeOutExpo,
                                  builder: (context, value, _) {
                                    return Container(
                                      height: 8,
                                      width: constraints.maxWidth * value,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: statusColor.withOpacity(0.5),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isBudgetVisible 
                                  ? '₹${currentSpent.toStringAsFixed(2)}' 
                                  : '••••',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Monthly Budget',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  _isBudgetVisible 
                                      ? '₹${widget.user.monthlySalary.toStringAsFixed(2)}' 
                                      : '••••',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _RecentExpenses extends ConsumerWidget {
  final int userId;
  const _RecentExpenses({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch more items to allow for meaningful grouping
    final recentExpensesAsync = ref.watch(recentExpensesProvider((userId, 10)));
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              TextButton(
                onPressed: () => context.go('/list'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          recentExpensesAsync.when(
            data: (expenses) {
              if (expenses.isEmpty) {
                return Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No recent expenses',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                );
              }

              // Grouping Logic
              final grouped = <String, List<Expense>>{};
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final yesterday = today.subtract(const Duration(days: 1));

              for (final expense in expenses) {
                final date = DateTime.tryParse(expense.date);
                if (date == null) {
                  debugPrint('Error parsing date for expense ${expense.id}: ${expense.date}');
                  continue;
                }
                final dateOnly = DateTime(date.year, date.month, date.day);
                
                String key;
                if (dateOnly == today) {
                  key = 'Today';
                } else if (dateOnly == yesterday) {
                  key = 'Yesterday';
                } else {
                  key = DateFormat('MMM d').format(date);
                }
                
                grouped.putIfAbsent(key, () => []).add(expense);
              }

              return Column(
                children: grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...entry.value.map((expense) {
                        final color = ColorService.getColorById(expense.categoryId);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withOpacity(0.2),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded, // Consistent icon
                                color: color,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              expense.title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              DateFormat('d-MM-yyyy').format(DateTime.parse(expense.date)),
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                            trailing: Text(
                              '₹${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              // Optional: Navigate to details
                            },
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error: $err'),
          ),
        ],
      ),
    );
  }
}

class _WellnessScoreCard extends ConsumerWidget {
  final int userId;
  final bool isCompact;
  const _WellnessScoreCard({required this.userId, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsStreamProvider(userId));

    return GestureDetector(
      onTap: () => context.push('/achievements'),
      child: statsAsync.when(
        data: (stats) {
          if (stats == null) return const SizedBox.shrink();
          
          return Container(
            padding: const EdgeInsets.all(12),
            height: isCompact ? 110 : null,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.health_and_safety, color: Colors.white, size: 16),
                    ),
                    if (isCompact)
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, size: 10, color: Colors.orange),
                            const SizedBox(width: 2),
                            Text(
                              '${stats.currentStreak}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wellness',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '${stats.wellnessScore}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator())),
        error: (e, s) => const SizedBox.shrink(),
      ),
    );
  }
}

class _NetWorthCard extends ConsumerWidget {
  final int userId;
  final bool isCompact;
  const _NetWorthCard({required this.userId, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetsProvider(userId));
    final liabilitiesAsync = ref.watch(liabilitiesProvider(userId));

    return GestureDetector(
      onTap: () => context.push('/net-worth'),
      child: Container(
        padding: const EdgeInsets.all(12),
        height: isCompact ? 110 : null,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance, color: Colors.white, size: 16),
                ),
                // Removed arrow icon as requested for cleaner look
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Worth',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiaryContainer.withOpacity(0.8),
                  ),
                ),
                if (assetsAsync.isLoading || liabilitiesAsync.isLoading)
                  const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Builder(
                    builder: (context) {
                      final assets = assetsAsync.value ?? [];
                      final liabilities = liabilitiesAsync.value ?? [];
                      final totalAssets = assets.fold(0.0, (sum, item) => sum + item.value);
                      final totalLiabilities = liabilities.fold(0.0, (sum, item) => sum + item.remainingAmount);
                      final netWorth = totalAssets - totalLiabilities;
                      
                      return Text(
                        NumberFormat.compactCurrency(symbol: '₹', decimalDigits: 1).format(netWorth),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                      );
                    }
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyInsightCard extends ConsumerWidget {
  final int userId;
  const _DailyInsightCard({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: ref.read(financialAdvisorServiceProvider).getDailyInsight(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.6),
                Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.auto_awesome, size: 20, color: Theme.of(context).colorScheme.tertiary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  snapshot.data!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
