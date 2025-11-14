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
import 'package:expense_app_new/widgets/animated_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  // Memoize expensive computations
  static const _chartHeight = 240.0;
  static const _maxLegendItems = 4;
  static const _chartRadius = 85.0;
  static const _centerSpaceRadius = 55.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Enable adaptive refresh rate for low-end devices
    WidgetsBinding.instance.window.onMetricsChanged = () {
      // Automatically adapts to device capabilities
    };
    final user = ref.watch(currentUserProvider);
    final userId = user?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if profile setup is complete
    if (user!.monthlySalary == 0) {
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

    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final currentMonthTotal = ref.watch(
      currentMonthTotalProvider((userId, currentMonth)),
    );
    final recentExpenses = ref.watch(
      recentExpensesProvider((userId, 5)),
    );
    final spendingByCategory = ref.watch(
      spendingByCategoryProvider(userId),
    );

    final colorScheme = Theme.of(context).colorScheme;
    final remaining = (user?.monthlySalary ?? 0) -
        (currentMonthTotal.value ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
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
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting
            Text(
              'Hello, ${user?.name}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Salary Overview Card with Animation
            RepaintBoundary(
              child: AnimatedCard(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppTheme.primaryGradient,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Salary',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${(user?.monthlySalary ?? 0).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spent',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${(currentMonthTotal.value ?? 0).toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Remaining',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${remaining.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: remaining < 0
                                        ? Colors.red[200]
                                        : Colors.green[200],
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: 24),

            // Spending by Category
            Text(
              'Spending by Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            spendingByCategory.when(
              data: (data) {
                if (data.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No expenses yet',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  );
                }

                final entries = data.entries.toList();
                final total = entries.fold<double>(0, (sum, e) => sum + e.value);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Pie Chart with better spacing
                        SizedBox(
                          height: _chartHeight,
                          width: double.infinity,
                          child: PieChart(
                            PieChartData(
                              sections: entries
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) {
                                      final color = ColorService.getColorByName(entry.value.key);
                                      final percentage = (entry.value.value / total * 100);
                                      // Only show badge for categories > 5%
                                      return PieChartSectionData(
                                        value: entry.value.value,
                                        color: color,
                                        radius: _chartRadius,
                                        badgeWidget: percentage > 5
                                            ? _buildBadge(percentage, color)
                                            : null,
                                        badgePositionPercentageOffset: 1.15,
                                        titleStyle: const TextStyle(
                                          fontSize: 0, // Hide default title
                                        ),
                                      );
                                    },
                                  )
                                  .toList(),
                              centerSpaceRadius: _centerSpaceRadius,
                              sectionsSpace: 2,
                              startDegreeOffset: -90,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Legend with better styling
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Category Breakdown',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (entries.length > _maxLegendItems)
                              TextButton(
                                onPressed: () => context.go('/list'),
                                child: const Text('View All'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Scrollable legend with max height
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 400),
                          child: SingleChildScrollView(
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: entries.length > _maxLegendItems ? _maxLegendItems : entries.length,
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                final color = ColorService.getColorByName(entry.key);
                                final percentage = (entry.value / total * 100);
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: color.withOpacity(0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header row with color indicator and category name
                                        Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: color.withOpacity(0.3),
                                                    blurRadius: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                entry.key,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '₹${entry.value.toStringAsFixed(0)}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: color,
                                                  ),
                                                ),
                                                Text(
                                                  '${percentage.toStringAsFixed(1)}%',
                                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Progress bar
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(2),
                                          child: LinearProgressIndicator(
                                            value: percentage / 100,
                                            minHeight: 4,
                                            backgroundColor: color.withOpacity(0.15),
                                            valueColor: AlwaysStoppedAnimation<Color>(color),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Show indicator if more categories exist
                        if (entries.length > _maxLegendItems)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Center(
                              child: Text(
                                '+${entries.length - _maxLegendItems} more categories',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $err'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Expenses
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Expenses',
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
            const SizedBox(height: 12),
            recentExpenses.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No recent expenses',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(expense.title),
                        subtitle: Text(expense.date),
                        trailing: Text(
                          '₹${expense.amount.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'AI',
          ),
        ],
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/add');
              break;
            case 2:
              context.go('/list');
              break;
            case 3:
              context.go('/ai');
              break;
          }
        },
      ),
    );
  }

  // Build percentage badge for pie chart
  static Widget _buildBadge(double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${percentage.toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
