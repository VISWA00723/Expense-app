# Testing Guide

## Pre-Testing Checklist

- [ ] Backend running on `http://localhost:3000`
- [ ] OpenRouter API key configured in `.env`
- [ ] Flutter SDK installed
- [ ] Android emulator or iOS simulator running
- [ ] Database generated (`flutter pub run build_runner build`)

---

## Backend Testing

### 1. Health Check
```bash
curl http://localhost:3000/health
```
✅ Expected: `{"status":"OK"}`

### 2. API Endpoint Test
```bash
curl -X POST http://localhost:3000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How much did I spend?",
    "expenses": [
      {"title": "Coffee", "amount": 150, "category": "Food", "date": "2025-01-10"}
    ]
  }'
```
✅ Expected: Response with `answer` and `summary`

### 3. Check Logs
```bash
# Backend logs should show:
# - Request received
# - OpenRouter API call
# - Response sent
```

---

## Flutter App Testing

### 1. Initial Setup
```bash
cd expense_tracker
flutter pub get
flutter pub run build_runner build
```

### 2. Run on Emulator/Device
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device_id>
```

### 3. Test Dashboard Screen
- [ ] App launches without errors
- [ ] Dashboard shows "This Month's Total"
- [ ] Pie chart displays (initially empty)
- [ ] Recent expenses section shows "No expenses yet"
- [ ] FAB button is visible

### 4. Test Add Expense
- [ ] Click FAB button
- [ ] Navigate to Add Expense screen
- [ ] Fill in form:
  - Title: "Coffee"
  - Amount: "150"
  - Category: "Food"
  - Date: Today
  - Notes: "Morning coffee"
- [ ] Click "Save Expense"
- [ ] Verify success message
- [ ] Return to dashboard
- [ ] Verify expense appears in recent list

### 5. Test Multiple Expenses
Add 5-10 expenses with different categories:
```
1. Coffee - ₹150 - Food
2. Lunch - ₹450 - Food
3. Uber - ₹200 - Transport
4. Movie - ₹300 - Entertainment
5. Shirt - ₹1500 - Shopping
6. Electricity - ₹2000 - Bills
7. Doctor - ₹500 - Health
```

- [ ] Dashboard total updates correctly
- [ ] Pie chart shows category breakdown
- [ ] Recent expenses list updates

### 6. Test Expense List Screen
- [ ] Navigate to List tab
- [ ] All expenses display
- [ ] Filter by month works
- [ ] Filter by category works
- [ ] Delete expense works
- [ ] Confirm dialog appears before delete

### 7. Test AI Assistant
- [ ] Navigate to AI tab
- [ ] Chat interface loads
- [ ] Type question: "How much did I spend on food?"
- [ ] Click send button
- [ ] Loading indicator appears
- [ ] Response appears in chat
- [ ] Test multiple questions:
  - "What is my highest spending category?"
  - "Show my spending breakdown"
  - "How much did I spend this month?"

### 8. Test Navigation
- [ ] Bottom navigation works
- [ ] FAB navigates to Add Expense
- [ ] Back button works correctly
- [ ] State persists when switching tabs

### 9. Test Data Persistence
- [ ] Add expense
- [ ] Close app completely
- [ ] Reopen app
- [ ] Expense still exists
- [ ] Data is loaded from SQLite

### 10. Test Error Handling
- [ ] Try adding expense with empty title
- [ ] Try adding expense with invalid amount
- [ ] Disconnect backend and try AI query
- [ ] Verify error messages display

---

## Test Data Script

### Generate Test Expenses (Dart)

Add to `lib/main.dart` temporarily for testing:

```dart
Future<void> _generateTestData(AppDatabase db) async {
  final now = DateTime.now();
  final expenses = [
    ExpensesCompanion(
      title: const Value('Coffee'),
      amount: const Value(150),
      category: const Value('Food'),
      date: Value(DateFormat('yyyy-MM-dd').format(now)),
      createdAt: Value(DateFormat('yyyy-MM-dd HH:mm:ss').format(now)),
    ),
    ExpensesCompanion(
      title: const Value('Lunch'),
      amount: const Value(450),
      category: const Value('Food'),
      date: Value(DateFormat('yyyy-MM-dd').format(now)),
      createdAt: Value(DateFormat('yyyy-MM-dd HH:mm:ss').format(now)),
    ),
    ExpensesCompanion(
      title: const Value('Uber'),
      amount: const Value(200),
      category: const Value('Transport'),
      date: Value(DateFormat('yyyy-MM-dd').format(now)),
      createdAt: Value(DateFormat('yyyy-MM-dd HH:mm:ss').format(now)),
    ),
  ];

  for (final expense in expenses) {
    await db.insertExpense(expense);
  }
}
```

Call in `main()`:
```dart
void main() async {
  final db = AppDatabase();
  await _generateTestData(db);
  runApp(const ProviderScope(child: MyApp()));
}
```

---

## Performance Testing

### 1. Load Test Backend
```bash
# Using Apache Bench
ab -n 100 -c 10 http://localhost:3000/health

# Using wrk
wrk -t4 -c100 -d30s http://localhost:3000/health
```

### 2. Database Performance
- Add 300 expenses
- Measure query time for:
  - Get all expenses
  - Get by month
  - Get by category
  - Calculate totals

### 3. UI Performance
- [ ] Dashboard renders smoothly
- [ ] Pie chart animation is smooth
- [ ] List scrolling is smooth
- [ ] No jank or stuttering

---

## Automated Testing

### Unit Tests

Create `test/database_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_app_new/database/database.dart';

void main() {
  group('Database Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase();
    });

    test('Insert expense', () async {
      final expense = ExpensesCompanion(
        title: const Value('Test'),
        amount: const Value(100),
        category: const Value('Food'),
        date: const Value('2025-01-10'),
        createdAt: const Value('2025-01-10 10:00:00'),
      );

      final id = await db.insertExpense(expense);
      expect(id, greaterThan(0));
    });

    test('Get all expenses', () async {
      final expenses = await db.getAllExpenses();
      expect(expenses, isA<List<Expense>>());
    });

    test('Delete expense', () async {
      final expense = ExpensesCompanion(
        title: const Value('Test'),
        amount: const Value(100),
        category: const Value('Food'),
        date: const Value('2025-01-10'),
        createdAt: const Value('2025-01-10 10:00:00'),
      );

      final id = await db.insertExpense(expense);
      final deleted = await db.deleteExpense(id);
      expect(deleted, greaterThan(0));
    });
  });
}
```

Run tests:
```bash
flutter test
```

---

## Integration Testing

Create `integration_test/app_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:expense_app_new/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Expense Tracker Integration Tests', () {
    testWidgets('Add expense and verify on dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(find.byType(TextField).first, 'Coffee');
      await tester.enterText(find.byType(TextField).at(1), '150');
      
      // Save
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify
      expect(find.text('Coffee'), findsWidgets);
    });
  });
}
```

Run integration tests:
```bash
flutter test integration_test/app_test.dart
```

---

## Manual Testing Scenarios

### Scenario 1: First Time User
1. Install app
2. See empty dashboard
3. Add first expense
4. See dashboard update
5. Ask AI a question

### Scenario 2: Power User
1. Add 50+ expenses
2. Filter by various months
3. Filter by categories
4. Ask complex questions to AI
5. Verify performance

### Scenario 3: Offline Scenario
1. Add expenses online
2. Disconnect network
3. Add more expenses (should work locally)
4. Reconnect network
5. Verify all expenses persist

### Scenario 4: Error Handling
1. Start app without backend running
2. Try to use AI assistant
3. Verify error message
4. Start backend
5. Retry - should work

---

## Test Results Template

```markdown
# Test Results - [Date]

## Backend
- [ ] Health check: PASS/FAIL
- [ ] Analyze endpoint: PASS/FAIL
- [ ] Error handling: PASS/FAIL

## Flutter App
- [ ] Dashboard: PASS/FAIL
- [ ] Add Expense: PASS/FAIL
- [ ] Expense List: PASS/FAIL
- [ ] AI Assistant: PASS/FAIL
- [ ] Navigation: PASS/FAIL
- [ ] Data Persistence: PASS/FAIL

## Performance
- [ ] Dashboard load time: ___ ms
- [ ] List scroll: SMOOTH/JANK
- [ ] AI response time: ___ ms

## Issues Found
1. ...
2. ...

## Notes
...
```

---

## Debugging Tips

### Flutter Debugging
```bash
# Verbose logs
flutter run -v

# Debug specific widget
flutter run --verbose

# Hot reload
Press 'r' during flutter run

# Hot restart
Press 'R' during flutter run

# Detach
Press 'd' during flutter run
```

### Backend Debugging
```bash
# Verbose logging
NODE_DEBUG=* npm start

# Check port usage
lsof -i :3000

# Kill process on port
kill -9 $(lsof -t -i:3000)
```

### Database Debugging
```dart
// Print all expenses
final expenses = await db.getAllExpenses();
for (final expense in expenses) {
  print('${expense.title}: ₹${expense.amount}');
}
```

---

## Continuous Integration

### GitHub Actions Example

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

---

## Sign-Off

- **Tested By:** ___________
- **Date:** ___________
- **Status:** ✅ READY FOR RELEASE / ❌ NEEDS FIXES

---

## Next Steps

- [ ] All tests passing
- [ ] No critical bugs
- [ ] Performance acceptable
- [ ] Ready for deployment
