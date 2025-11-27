import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/services/recurring_expense_service.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/services/color_service.dart';
import 'package:intl/intl.dart';

class RecurringExpensesScreen extends ConsumerWidget {
  const RecurringExpensesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final recurringService = ref.watch(recurringExpenseServiceProvider);
    final recurringExpensesAsync = ref.watch(userRecurringExpensesProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions & Recurring'),
      ),
      body: recurringExpensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.autorenew, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('No recurring expenses yet'),
                  const SizedBox(height: 8),
                  const Text('Add one when creating a new expense'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final color = ColorService.getColorById(expense.categoryId);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(Icons.receipt_long, color: color),
                  ),
                  title: Text(expense.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${expense.frequency.toUpperCase()} • Next: ${expense.nextDueDate}'),
                      if (expense.autoPay)
                        Row(
                          children: [
                            Icon(Icons.check_circle, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('Auto-pay enabled', style: TextStyle(fontSize: 12, color: Colors.green)),
                          ],
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${expense.amount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Recurring Expense?'),
                              content: const Text('This will stop future auto-creation. Past expenses will remain.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          
                          if (confirm == true) {
                            await recurringService.deleteRecurringExpense(expense.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
