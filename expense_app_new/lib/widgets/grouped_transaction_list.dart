import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/services/color_service.dart';
import 'package:expense_app_new/providers/database_provider.dart';

class GroupedTransactionList extends ConsumerWidget {
  final List<Expense> expenses;
  final Function(Expense) onExpenseTap;
  final Function(Expense) onDelete;

  const GroupedTransactionList({
    super.key,
    required this.expenses,
    required this.onExpenseTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenses.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No expenses found',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final grouped = _groupExpenses(expenses);
    final categoriesAsync = ref.watch(userCategoriesProvider(expenses.first.userId));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final group = grouped[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  group.title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Items
              ...group.expenses.map((expense) {
                return categoriesAsync.when(
                  data: (categories) {
                    final category = categories.firstWhere(
                      (c) => c.id == expense.categoryId,
                      orElse: () => categories.first,
                    );
                    final customColor = category.color != null ? Color(category.color!) : null;
                    final color = customColor ?? ColorService.getColorById(expense.categoryId);

                    return Dismissible(
                      key: ValueKey(expense.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Expense?'),
                            content: const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) => onDelete(expense),
                      child: ListTile(
                        onTap: () => onExpenseTap(expense),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: category.iconPath != null
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: FileImage(File(category.iconPath!)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : Text(category.icon, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                        title: Text(
                          expense.title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          DateFormat('MMM d, yyyy').format(DateTime.parse(expense.date)),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Text(
                          '₹${expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 72), // Placeholder height
                  error: (_, __) => const SizedBox.shrink(),
                );
              }).toList(),
            ],
          );
        },
        childCount: grouped.length,
      ),
    );
  }

  List<_ExpenseGroup> _groupExpenses(List<Expense> expenses) {
    final groups = <_ExpenseGroup>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    // Sort by date desc
    final sorted = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Grouping logic
    final todayExpenses = <Expense>[];
    final yesterdayExpenses = <Expense>[];
    final thisWeekExpenses = <Expense>[];
    final otherGroups = <String, List<Expense>>{};

    for (final expense in sorted) {
      final date = DateTime.parse(expense.date);
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (dateOnly == today) {
        todayExpenses.add(expense);
      } else if (dateOnly == yesterday) {
        yesterdayExpenses.add(expense);
      } else if (dateOnly.isAfter(weekStart)) {
        thisWeekExpenses.add(expense);
      } else {
        final monthKey = DateFormat('MMMM yyyy').format(date);
        otherGroups.putIfAbsent(monthKey, () => []).add(expense);
      }
    }

    if (todayExpenses.isNotEmpty) {
      groups.add(_ExpenseGroup('Today', todayExpenses));
    }
    if (yesterdayExpenses.isNotEmpty) {
      groups.add(_ExpenseGroup('Yesterday', yesterdayExpenses));
    }
    if (thisWeekExpenses.isNotEmpty) {
      groups.add(_ExpenseGroup('This Week', thisWeekExpenses));
    }
    
    otherGroups.forEach((key, list) {
      groups.add(_ExpenseGroup(key, list));
    });

    return groups;
  }
}

class _ExpenseGroup {
  final String title;
  final List<Expense> expenses;

  _ExpenseGroup(this.title, this.expenses);
}
