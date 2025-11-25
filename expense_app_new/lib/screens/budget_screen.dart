import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/services/color_service.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  DateTime _selectedDate = DateTime.now();

  String get _monthStr => DateFormat('yyyy-MM').format(_selectedDate);

  void _changeMonth(int months) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + months);
    });
  }

  void _showSetBudgetDialog(BuildContext context, ExpenseCategory category, Budget? currentBudget) {
    final controller = TextEditingController(
      text: currentBudget?.amount.toStringAsFixed(0) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Budget for ${category.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Monthly Limit',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null) {
                final db = ref.read(databaseProvider);
                final user = ref.read(currentUserProvider);
                
                await db.setBudget(BudgetsCompanion(
                  id: currentBudget != null ? drift.Value(currentBudget.id) : const drift.Value.absent(),
                  userId: drift.Value(user!.id),
                  categoryId: drift.Value(category.id),
                  amount: drift.Value(amount),
                  month: drift.Value(_monthStr),
                  createdAt: drift.Value(DateTime.now().toIso8601String()),
                ));
                
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final categoriesAsync = ref.watch(userCategoriesProvider(user.id));
    final budgetsAsync = ref.watch(budgetsProvider((user.id, _monthStr)));
    final spendingAsync = ref.watch(spendingByCategoryWithIdProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedDate),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return budgetsAsync.when(
            data: (budgets) {
              return spendingAsync.when(
                data: (spending) {
                  if (categories.isEmpty) {
                    return const Center(child: Text('No categories found'));
                  }

                  // Optimize lookups by converting lists to maps
                  final budgetMap = {for (var b in budgets) b.categoryId: b};
                  final spendingMap = {for (var s in spending) s.categoryId: s};

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final budget = budgetMap[category.id] ?? Budget(
                        id: -1,
                        userId: user.id,
                        categoryId: category.id,
                        amount: 0,
                        month: _monthStr,
                        createdAt: '',
                      );

                      final spent = spendingMap[category.id]?.totalAmount ?? 0.0;

                      final hasBudget = budget.amount > 0;
                      final progress = hasBudget ? (spent / budget.amount).clamp(0.0, 1.0) : 0.0;
                      final isOverBudget = hasBudget && spent > budget.amount;
                      
                      Color progressColor = Colors.green;
                      if (progress > 0.8) progressColor = Colors.orange;
                      if (isOverBudget) progressColor = Colors.red;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: ColorService.getColorById(category.id).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      category.icon,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (hasBudget)
                                          Text(
                                            '${(progress * 100).toStringAsFixed(0)}% used',
                                            style: TextStyle(
                                              color: progressColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${spent.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        hasBudget 
                                          ? 'of ₹${budget.amount.toStringAsFixed(0)}'
                                          : 'No limit',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (hasBudget) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[200],
                                    color: progressColor,
                                    minHeight: 8,
                                  ),
                                ),
                              ] else
                                OutlinedButton.icon(
                                  onPressed: () => _showSetBudgetDialog(context, category, null),
                                  icon: const Icon(Icons.add_circle_outline, size: 16),
                                  label: const Text('Set Budget'),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              
                              if (hasBudget) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _showSetBudgetDialog(context, category, budget),
                                    child: const Text('Edit Limit'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
