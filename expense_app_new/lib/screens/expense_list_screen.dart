import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/widgets/app_bottom_bar.dart';
import 'package:expense_app_new/services/auto_categorizer.dart';
import 'package:expense_app_new/widgets/expense_pie_chart.dart';
import 'package:expense_app_new/widgets/grouped_transaction_list.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  DateTime? _selectedDate;
  int? _selectedCategoryId;

  void _showEditDialog(BuildContext context, Expense expense, List<ExpenseCategory> categories) {
    final titleController = TextEditingController(text: expense.title);
    final amountController = TextEditingController(text: expense.amount.toString());
    final notesController = TextEditingController(text: expense.notes ?? '');
    int selectedCategoryId = expense.categoryId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Text('${cat.icon} ${cat.name}'),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategoryId = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final db = ref.read(databaseProvider);
                  
                  // Update the expense directly in database
                  await (db.update(db.expenses)
                        ..where((tbl) => tbl.id.equals(expense.id)))
                      .write(
                    ExpensesCompanion(
                      title: drift.Value(titleController.text),
                      amount: drift.Value(double.parse(amountController.text)),
                      categoryId: drift.Value(selectedCategoryId),
                      notes: drift.Value(
                        notesController.text.isEmpty ? null : notesController.text,
                      ),
                    ),
                  );
                  
                  // 🧠 Learn from correction if category changed
                  if (selectedCategoryId != expense.categoryId) {
                    final newCategory = categories.firstWhere((c) => c.id == selectedCategoryId);
                    await AutoCategorizer.initialize();
                    await AutoCategorizer.learnRule(titleController.text, newCategory.name);
                    print('🧠 Learned rule: "${titleController.text}" -> ${newCategory.name}');
                  }
                  
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final userExpenses = ref.watch(userExpensesProvider(userId));
    final categories = ref.watch(userCategoriesProvider(userId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/dashboard');
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('All Expenses'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Date Filter
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Filter by Date',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _selectedDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _selectedDate = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                            : 'Select Date',
                        style: _selectedDate != null
                            ? null
                            : TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Category Filter
                  categories.when(
                    data: (cats) {
                      return DropdownButtonFormField<int?>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: 'Filter by Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...cats.map((cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Text('${cat.icon} ${cat.name}'),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCategoryId = value);
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                ],
              ),
            ),
          ),

          // Pie Chart (Only show if no specific date filter is active, or always? 
          // User asked for "a pie chart... that shows Overall/Monthly/Weekly".
          // This implies it's a dashboard-like feature on the list screen.
          // I'll keep it always visible at the top.)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExpensePieChart(userId: userId, categoryId: _selectedCategoryId),
            ),
          ),

          // Expenses List
          userExpenses.when(
            data: (expenses) {
              // Filter expenses
              var filtered = expenses;
              
              if (_selectedDate != null) {
                final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
                filtered = filtered
                    .where((e) => e.date == dateStr)
                    .toList();
              }
              
              if (_selectedCategoryId != null) {
                filtered = filtered
                    .where((e) => e.categoryId == _selectedCategoryId)
                    .toList();
              }

              return GroupedTransactionList(
                expenses: filtered,
                onExpenseTap: (expense) {
                  final categoryList = categories.asData?.value ?? [];
                  _showEditDialog(context, expense, categoryList);
                },
                onDelete: (expense) async {
                  final db = ref.read(databaseProvider);
                  await db.deleteExpense(expense.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Expense deleted')),
                    );
                  }
                },
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $err')),
            ),
          ),
          
          // Bottom Padding
          SliverPadding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 80),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomBar(currentIndex: 2),
      ),
    );
  }
}
