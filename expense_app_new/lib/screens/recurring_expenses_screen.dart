import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/services/recurring_expense_service.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/services/color_service.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;

class RecurringExpensesScreen extends ConsumerStatefulWidget {
  const RecurringExpensesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RecurringExpensesScreen> createState() => _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends ConsumerState<RecurringExpensesScreen> {
  
  void _showAddEditDialog(BuildContext context, int userId, {RecurringExpense? expense}) {
    final nameController = TextEditingController(text: expense?.name);
    final amountController = TextEditingController(text: expense?.amount.toString());
    int? selectedCategoryId = expense?.categoryId;
    String frequency = expense?.frequency ?? 'monthly';
    DateTime nextDueDate = expense != null ? DateTime.parse(expense.nextDueDate) : DateTime.now();
    bool autoPay = expense?.autoPay ?? false;
    int? selectedLiabilityId = expense?.liabilityId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final categoriesAsync = ref.watch(categoriesStreamProvider(userId));
          final liabilitiesAsync = ref.watch(liabilitiesStreamProvider(userId));

          return AlertDialog(
            title: Text(expense == null ? 'Add Recurring Expense' : 'Edit Recurring Expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name (e.g., Netflix, Home Loan)'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category Dropdown
                  categoriesAsync.when(
                    data: (categories) => DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      items: categories.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            Text(c.icon),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      )).toList(),
                      onChanged: (val) => setState(() => selectedCategoryId = val),
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error loading categories'),
                  ),
                  const SizedBox(height: 16),

                  // Frequency Dropdown
                  DropdownButtonFormField<String>(
                    value: frequency,
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                    ],
                    onChanged: (val) => setState(() => frequency = val!),
                    decoration: const InputDecoration(labelText: 'Frequency'),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  ListTile(
                    title: const Text('Next Due Date'),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(nextDueDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: nextDueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) setState(() => nextDueDate = picked);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Liability Link Dropdown (For EMIs)
                  liabilitiesAsync.when(
                    data: (liabilities) {
                      if (liabilities.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Link to Loan (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: selectedLiabilityId,
                            items: [
                              const DropdownMenuItem<int>(value: null, child: Text('None')),
                              ...liabilities.map((l) => DropdownMenuItem(
                                value: l.id,
                                child: Text('${l.name} (Remaining: ₹${l.remainingAmount.toStringAsFixed(0)})'),
                              )),
                            ],
                            onChanged: (val) => setState(() => selectedLiabilityId = val),
                            decoration: const InputDecoration(
                              labelText: 'Select Liability',
                              helperText: 'EMI will automatically reduce this loan balance',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Auto Pay Toggle
                  SwitchListTile(
                    title: const Text('Auto-create Expense'),
                    subtitle: const Text('Automatically add to expenses on due date'),
                    value: autoPay,
                    onChanged: (val) => setState(() => autoPay = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final amount = double.tryParse(amountController.text.trim());

                  if (name.isEmpty || amount == null || selectedCategoryId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all required fields')),
                    );
                    return;
                  }

                  final service = ref.read(recurringExpenseServiceProvider);

                  if (expense == null) {
                    await service.addRecurringExpense(
                      userId: userId,
                      name: name,
                      amount: amount,
                      categoryId: selectedCategoryId!,
                      frequency: frequency,
                      nextDueDate: nextDueDate,
                      autoPay: autoPay,
                      liabilityId: selectedLiabilityId,
                    );
                  } else {
                    await service.updateRecurringExpense(expense.copyWith(
                      name: name,
                      amount: amount,
                      categoryId: selectedCategoryId!,
                      frequency: frequency,
                      nextDueDate: DateFormat('yyyy-MM-dd').format(nextDueDate),
                      autoPay: autoPay,
                      liabilityId: drift.Value(selectedLiabilityId),
                    ));
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final recurringService = ref.watch(recurringExpenseServiceProvider);
    final recurringExpensesAsync = ref.watch(userRecurringExpensesProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions & EMIs'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, user.id),
        label: const Text('Add Recurring'),
        icon: const Icon(Icons.add),
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
                  const Text('Add subscriptions or loan EMIs here'),
                ],
              ),
            );
          }

          // Calculate Total Monthly EMI
          double totalMonthlyEMI = 0;
          for (var e in expenses) {
            if (e.liabilityId != null) {
              // Normalize to monthly amount
              double monthlyAmount = e.amount;
              if (e.frequency == 'weekly') monthlyAmount *= 4;
              if (e.frequency == 'yearly') monthlyAmount /= 12;
              if (e.frequency == 'daily') monthlyAmount *= 30;
              totalMonthlyEMI += monthlyAmount;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (totalMonthlyEMI > 0)
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Monthly EMI',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              '₹${totalMonthlyEMI.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (totalMonthlyEMI > 0) const SizedBox(height: 16),

              ...expenses.map((expense) {
                final color = ColorService.getColorById(expense.categoryId);
                
                // Format date
                String formattedDate = expense.nextDueDate;
                try {
                  final date = DateTime.parse(expense.nextDueDate);
                  formattedDate = DateFormat('dd MMM yyyy').format(date);
                } catch (e) {
                  // Keep original string if parsing fails
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(
                        expense.liabilityId != null ? Icons.account_balance : Icons.receipt_long, 
                        color: color
                      ),
                    ),
                    title: Text(expense.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${expense.frequency.toUpperCase()} • Next: $formattedDate'),
                        if (expense.liabilityId != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Linked to Loan',
                              style: TextStyle(
                                fontSize: 10, 
                                color: Theme.of(context).colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        if (expense.autoPay)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 12, color: Colors.green),
                                const SizedBox(width: 4),
                                Text('Auto-pay enabled', style: TextStyle(fontSize: 12, color: Colors.green)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${expense.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showAddEditDialog(context, user.id, expense: expense);
                            } else if (value == 'delete') {
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
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// Providers needed for the dialog
final categoriesStreamProvider = StreamProvider.family<List<ExpenseCategory>, int>((ref, userId) {
  return ref.watch(databaseProvider).watchCategories(userId);
});

final liabilitiesStreamProvider = StreamProvider.family<List<Liability>, int>((ref, userId) {
  return ref.watch(databaseProvider).watchLiabilities(userId);
});
