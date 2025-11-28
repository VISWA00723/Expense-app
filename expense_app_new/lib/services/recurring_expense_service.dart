import 'package:drift/drift.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:intl/intl.dart';

final recurringExpenseServiceProvider = Provider<RecurringExpenseService>((ref) {
  return RecurringExpenseService(ref.read(databaseProvider));
});

final userRecurringExpensesProvider = StreamProvider.family<List<RecurringExpense>, int>((ref, userId) {
  final service = ref.watch(recurringExpenseServiceProvider);
  return service.watchRecurringExpenses(userId);
});

class RecurringExpenseService {
  final AppDatabase db;

  RecurringExpenseService(this.db);

  // Check and create due expenses
  Future<void> checkAndCreateDueExpenses(int userId) async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    final dueRecurring = await (db.select(db.recurringExpenses)
      ..where((t) => t.userId.equals(userId) & t.isActive.equals(true) & t.autoPay.equals(true)))
      .get();

    for (final recurring in dueRecurring) {
      final dueDate = DateTime.parse(recurring.nextDueDate);
      
      // If due date is today or in the past
      if (dueDate.isBefore(now) || recurring.nextDueDate == todayStr) {
        // Wrap in transaction to ensure atomicity
        await db.transaction(() async {
          // Check if expense already exists for today to prevent duplicates
          final existing = await (db.select(db.expenses)
            ..where((t) => 
              t.userId.equals(userId) & 
              t.title.equals(recurring.name) & 
              t.amount.equals(recurring.amount) & 
              t.date.equals(recurring.nextDueDate)
            ))
            .getSingleOrNull();

          if (existing == null) {
            // Create expense
            await db.into(db.expenses).insert(ExpensesCompanion(
              userId: Value(userId),
              title: Value(recurring.name),
              amount: Value(recurring.amount),
              categoryId: Value(recurring.categoryId),
              date: Value(recurring.nextDueDate),
              notes: const Value('Auto-generated from recurring expense'),
              createdAt: Value(DateTime.now().toIso8601String()),
            ));

            // Update next due date
            final nextDate = _calculateNextDueDate(dueDate, recurring.frequency);
            await db.update(db.recurringExpenses).replace(recurring.copyWith(
              nextDueDate: DateFormat('yyyy-MM-dd').format(nextDate),
            ));
          }
        });
      }
    }
  }

  // Calculate next due date
  DateTime _calculateNextDueDate(DateTime current, String frequency) {
    switch (frequency) {
      case 'daily': return current.add(const Duration(days: 1));
      case 'weekly': return current.add(const Duration(days: 7));
      case 'monthly': 
        int year = current.year;
        int month = current.month + 1;
        if (month > 12) {
          year++;
          month = 1;
        }
        final lastDayOfMonth = DateTime(year, month + 1, 0).day;
        final day = current.day > lastDayOfMonth ? lastDayOfMonth : current.day;
        return DateTime(year, month, day);
      case 'yearly': 
        int year = current.year + 1;
        int month = current.month;
        int day = current.day;
        if (month == 2 && day == 29 && !((year % 4 == 0 && year % 100 != 0) || year % 400 == 0)) {
          day = 28;
        }
        return DateTime(year, month, day);
      default: return current.add(const Duration(days: 30));
    }
  }

  // Add a new recurring expense
  Future<void> addRecurringExpense({
    required int userId,
    required String name,
    required double amount,
    required int categoryId,
    required String frequency,
    required DateTime nextDueDate,
    bool autoPay = false,
  }) async {
    await db.into(db.recurringExpenses).insert(RecurringExpensesCompanion(
      userId: Value(userId),
      name: Value(name),
      amount: Value(amount),
      categoryId: Value(categoryId),
      frequency: Value(frequency),
      nextDueDate: Value(DateFormat('yyyy-MM-dd').format(nextDueDate)),
      autoPay: Value(autoPay),
      isActive: const Value(true),
    ));
  }
  
  Stream<List<RecurringExpense>> watchRecurringExpenses(int userId) {
    return (db.select(db.recurringExpenses)..where((t) => t.userId.equals(userId))).watch();
  }
  
  Future<void> deleteRecurringExpense(int id) async {
    await (db.delete(db.recurringExpenses)..where((t) => t.id.equals(id))).go();
  }
}
