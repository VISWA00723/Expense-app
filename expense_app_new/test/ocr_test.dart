import 'package:flutter_test/flutter_test.dart';
import 'package:expense_app_new/services/receipt_scanning_service.dart';

void main() {
  late ReceiptScanningService service;

  setUp(() {
    service = ReceiptScanningService();
  });

  group('Receipt Parsing Logic', () {
    test('Extracts simple receipt correctly', () {
      const text = '''
      WALMART SUPERCENTER
      123 Main St
      Anytown, USA
      
      Date: 01/15/2023
      
      Item 1   \$10.00
      Item 2   \$20.00
      
      TOTAL    \$30.00
      ''';

      final data = service.parseReceiptTextForTesting(text);
      
      expect(data.merchant, equals('WALMART SUPERCENTER'));
      expect(data.amount, equals(30.00));
      expect(data.date, equals(DateTime(2023, 1, 15)));
    });

    test('Extracts amount with different currency symbols', () {
      const text = '''
      Cafe Paris
      
      Cappuccino €4.50
      Croissant  €3.00
      
      Total Due: €7.50
      ''';

      final data = service.parseReceiptTextForTesting(text);
      expect(data.amount, equals(7.50));
    });

    test('Extracts date with month name', () {
      const text = '''
      Fancy Restaurant
      
      12 Jan 2023
      
      Total: 100.00
      ''';

      final data = service.parseReceiptTextForTesting(text);
      expect(data.date, equals(DateTime(2023, 1, 12)));
    });

    test('Prioritizes TOTAL line over other numbers', () {
      const text = '''
      Hardware Store
      
      Item A   50.00
      Item B   150.00
      
      Subtotal 200.00
      Tax      20.00
      
      TOTAL    220.00
      
      Cash     300.00
      Change   80.00
      ''';

      final data = service.parseReceiptTextForTesting(text);
      expect(data.amount, equals(220.00));
    });

    test('Handles comma as decimal separator', () {
      const text = '''
      German Shop
      
      Total: 12,50
      ''';

      final data = service.parseReceiptTextForTesting(text);
      expect(data.amount, equals(12.50));
    });
    
    test('Ignores phone numbers as merchant', () {
      const text = '''
      123-456-7890
      MY AWESOME SHOP
      
      Total: 10.00
      ''';

      final data = service.parseReceiptTextForTesting(text);
      expect(data.merchant, equals('MY AWESOME SHOP'));
    });
  });
}
