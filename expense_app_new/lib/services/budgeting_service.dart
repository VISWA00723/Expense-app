import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/providers/database_provider.dart';

class BudgetingService {
  final AppDatabase _db;

  BudgetingService(this._db);

  // Initialize envelopes for a new month based on categories
  Future<void> initializeEnvelopesForMonth(int userId, int month, int year) async {
    // Check if envelopes already exist
    final existing = await _db.watchEnvelopes(userId, month, year).first;
    if (existing.isNotEmpty) return;

    // Get all expense categories for this user
    final categories = await (_db.select(_db.expenseCategories)..where((c) => c.userId.equals(userId))).get();

    // Create an envelope for each category with 0 amount
    await _db.batch((batch) {
      for (final category in categories) {
        batch.insert(
          _db.envelopes,
          EnvelopesCompanion(
            userId: Value(userId),
            categoryId: Value(category.id),
            amount: const Value(0.0),
            month: Value(month),
            year: Value(year),
          ),
        );
      }
    });
  }

  // Allocate money to an envelope
  Future<void> allocateToEnvelope(int envelopeId, double amount) async {
    final envelope = await (_db.select(_db.envelopes)..where((t) => t.id.equals(envelopeId))).getSingle();
    
    await _db.updateEnvelope(envelope.copyWith(
      amount: envelope.amount + amount,
      updatedAt: DateTime.now().toIso8601String(),
    ));

    // Log transfer (from "To be Budgeted" which is null)
    await _db.addEnvelopeTransfer(EnvelopeTransfersCompanion(
      userId: Value(envelope.userId),
      toEnvelopeId: Value(envelopeId),
      amount: Value(amount),
      date: Value(DateTime.now().toIso8601String()),
    ));
  }

  // Move money between envelopes
  Future<void> transferBetweenEnvelopes(int fromEnvelopeId, int toEnvelopeId, double amount) async {
    if (amount <= 0) throw Exception('Transfer amount must be positive');

    await _db.transaction(() async {
      // Re-fetch envelopes inside transaction to ensure fresh data
      final fromEnvelope = await (_db.select(_db.envelopes)..where((t) => t.id.equals(fromEnvelopeId))).getSingle();
      final toEnvelope = await (_db.select(_db.envelopes)..where((t) => t.id.equals(toEnvelopeId))).getSingle();

      if (fromEnvelope.amount < amount) {
        throw Exception('Insufficient funds in source envelope');
      }

      // Deduct from source
      await _db.updateEnvelope(fromEnvelope.copyWith(
        amount: fromEnvelope.amount - amount,
        updatedAt: DateTime.now().toIso8601String(),
      ));

      // Add to destination
      await _db.updateEnvelope(toEnvelope.copyWith(
        amount: toEnvelope.amount + amount,
        updatedAt: DateTime.now().toIso8601String(),
      ));

      // Log transfer
      await _db.addEnvelopeTransfer(EnvelopeTransfersCompanion(
        userId: Value(fromEnvelope.userId),
        fromEnvelopeId: Value(fromEnvelopeId),
        toEnvelopeId: Value(toEnvelopeId),
        amount: Value(amount),
        date: Value(DateTime.now().toIso8601String()),
      ));
    });
  }

  // Get Envelope Balance (Allocated - Spent)
  Future<double> getEnvelopeBalance(int userId, int categoryId, int month, int year) async {
    final envelope = await (_db.select(_db.envelopes)
      ..where((t) => t.userId.equals(userId) & t.categoryId.equals(categoryId) & t.month.equals(month) & t.year.equals(year))
    ).getSingleOrNull();

    final allocated = envelope?.amount ?? 0.0;

    final expenses = await (_db.select(_db.expenses)
      ..where((t) => t.userId.equals(userId) & t.categoryId.equals(categoryId))
    ).get();

    final spent = expenses.where((e) {
      final date = DateTime.parse(e.date);
      return date.month == month && date.year == year;
    }).fold(0.0, (sum, item) => sum + item.amount);

    return allocated - spent;
  }
  // Watch Envelope Balance (Allocated - Spent)
  Stream<double> watchEnvelopeBalance(int userId, int categoryId, int month, int year) {
    final monthStr = month.toString().padLeft(2, '0');
    final datePattern = '$year-$monthStr%';
    
    return _db.customSelect(
      'SELECT '
      '(COALESCE((SELECT amount FROM envelopes WHERE user_id = ?1 AND category_id = ?2 AND month = ?3 AND year = ?4), 0.0) - '
      'COALESCE((SELECT SUM(amount) FROM expenses WHERE user_id = ?1 AND category_id = ?2 AND date LIKE ?5), 0.0)) as balance',
      variables: [
        Variable.withInt(userId),
        Variable.withInt(categoryId),
        Variable.withInt(month),
        Variable.withInt(year),
        Variable.withString(datePattern)
      ],
      readsFrom: {_db.envelopes, _db.expenses}
    ).watchSingle().map((row) => row.read<double>('balance'));
  }
}

final budgetingServiceProvider = Provider<BudgetingService>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetingService(db);
});

final envelopeBalanceProvider = StreamProvider.family<double, (int, int, int, int)>((ref, params) {
  final (userId, categoryId, month, year) = params;
  return ref.watch(budgetingServiceProvider).watchEnvelopeBalance(userId, categoryId, month, year);
});
