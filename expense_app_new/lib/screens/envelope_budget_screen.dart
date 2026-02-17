import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/services/budgeting_service.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/services/color_service.dart';

class EnvelopeBudgetScreen extends ConsumerStatefulWidget {
  const EnvelopeBudgetScreen({super.key});

  @override
  ConsumerState<EnvelopeBudgetScreen> createState() => _EnvelopeBudgetScreenState();
}

class _EnvelopeBudgetScreenState extends ConsumerState<EnvelopeBudgetScreen> {
  DateTime _selectedDate = DateTime.now();
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(budgetingServiceProvider).initializeEnvelopesForMonth(
          user.id, 
          _selectedDate.month, 
          _selectedDate.year
        );
      }
    });
  }

  void _changeMonth(int months) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + months, 1);
    });
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(budgetingServiceProvider).initializeEnvelopesForMonth(
        user.id, 
        _selectedDate.month, 
        _selectedDate.year
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final month = _selectedDate.month;
    final year = _selectedDate.year;

    final toBeBudgetedAsync = ref.watch(toBeBudgetedProvider((user.id, month, year)));
    final envelopesAsync = ref.watch(envelopesProvider((user.id, month, year)));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Budget Planner'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildToBeBudgetedHeader(toBeBudgetedAsync),
          Expanded(
            child: envelopesAsync.when(
              data: (envelopes) {
                if (envelopes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        const Text('No envelopes yet.'),
                        TextButton(
                          onPressed: () {
                            // Trigger re-init
                            ref.read(budgetingServiceProvider).initializeEnvelopesForMonth(user.id, month, year);
                          },
                          child: const Text('Initialize Envelopes'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: envelopes.length,
                  itemBuilder: (context, index) {
                    final envelope = envelopes[index];
                    return _EnvelopeListItem(
                      envelope: envelope, 
                      userId: user.id,
                      month: month,
                      year: year,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
          Text(
            DateFormat('MMMM yyyy').format(_selectedDate),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }

  Widget _buildToBeBudgetedHeader(AsyncValue<double> toBeBudgetedAsync) {
    return toBeBudgetedAsync.when(
      data: (amount) {
        final isPositive = amount >= 0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isPositive ? Colors.green.shade200 : Colors.red.shade200),
          ),
          child: Column(
            children: [
              Text(
                'To be Budgeted',
                style: TextStyle(
                  color: isPositive ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currencyFormat.format(amount),
                style: TextStyle(
                  color: isPositive ? Colors.green.shade900 : Colors.red.shade900,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Budget'),
        content: const Text(
          '1. "To be Budgeted" is your Income minus what you\'ve assigned to envelopes.\n'
          '2. Tap on an envelope to set its budget.\n'
          '3. Aim to get "To be Budgeted" to zero!\n'
          '4. As you spend, the bars will fill up.'
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }
}

class _EnvelopeListItem extends ConsumerWidget {
  final Envelope envelope;
  final int userId;
  final int month;
  final int year;

  const _EnvelopeListItem({
    required this.envelope,
    required this.userId,
    required this.month,
    required this.year,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider(userId));
    final balanceAsync = ref.watch(envelopeBalanceProvider((userId, envelope.categoryId, month, year)));

    return categoriesAsync.when(
      data: (categories) {
        final category = categories.firstWhere(
          (c) => c.id == envelope.categoryId,
          orElse: () => const ExpenseCategory(id: -1, name: 'Unknown', icon: 'help', color: 0xFF9E9E9E, iconPath: null, isCustom: false, userId: -1, createdAt: ''),
        );
        
        final color = Color(category.color ?? 0xFF9E9E9E);

        return InkWell(
          onTap: () => _showAllocationDialog(context, ref, category.name),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Builder(
                    builder: (context) {
                      if (category.iconPath != null) {
                        return Image.file(
                          File(category.iconPath!),
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.category, color: color, size: 24),
                        );
                      }
                      
                      // Check if icon is an emoji (not a number)
                      final isNumeric = int.tryParse(category.icon) != null;
                      if (!isNumeric) {
                        return Text(category.icon, style: const TextStyle(fontSize: 24));
                      }
                      
                      // Fallback for legacy numeric icons (to avoid build error with dynamic IconData)
                      return Icon(Icons.category, color: color, size: 24);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Budget: ₹${envelope.amount.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Progress Bar
                      balanceAsync.when(
                        data: (balance) {
                           final spent = envelope.amount - balance;
                           final progress = envelope.amount > 0 ? (spent / envelope.amount).clamp(0.0, 1.0) : 0.0;
                           final isOverBudget = balance < 0;

                           return Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               ClipRRect(
                                 borderRadius: BorderRadius.circular(4),
                                 child: LinearProgressIndicator(
                                   value: progress,
                                   backgroundColor: color.withOpacity(0.1),
                                   color: isOverBudget ? Colors.red : color,
                                   minHeight: 8,
                                 ),
                               ),
                               const SizedBox(height: 4),
                               Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   Text(
                                     'Spent: ₹${spent.toStringAsFixed(0)}',
                                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                   ),
                                   Text(
                                     'Left: ₹${balance.toStringAsFixed(0)}',
                                     style: TextStyle(
                                       fontSize: 12, 
                                       fontWeight: FontWeight.bold,
                                       color: isOverBudget ? Colors.red : Colors.green[700],
                                     ),
                                   ),
                                 ],
                               ),
                             ],
                           );
                        },
                        loading: () => const LinearProgressIndicator(minHeight: 6),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showAllocationDialog(BuildContext context, WidgetRef ref, String categoryName) {
    final controller = TextEditingController(text: envelope.amount == 0 ? '' : envelope.amount.toStringAsFixed(0));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Budget for $categoryName', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final amount = double.tryParse(controller.text) ?? 0.0;
                        // Calculate difference to add/subtract
                        final diff = amount - envelope.amount;
                        await ref.read(budgetingServiceProvider).allocateToEnvelope(envelope.id, diff);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Save Budget'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
