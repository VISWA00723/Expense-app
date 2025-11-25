import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart';
import 'package:expense_app_new/database/database.dart';

class PdfService {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');
  
  // Generate weekly report (7 days)
  static Future<void> generateWeeklyReport({
    required AppDatabase db,
    required int userId,
    required DateTime weekStartDate,
    required String userName,
  }) async {
    final weekEndDate = weekStartDate.add(const Duration(days: 6));
    final startDateStr = DateFormat('yyyy-MM-dd').format(weekStartDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(weekEndDate);
    
    // Fetch expenses for the week
    final expenses = await db.customSelect(
      '''SELECT e.*, ec.name as category_name FROM expenses e 
         JOIN expense_categories ec ON e.category_id = ec.id 
         WHERE e.user_id = ? AND e.date >= ? AND e.date <= ?
         ORDER BY e.date DESC''',
      variables: [
        Variable.withInt(userId),
        Variable.withString(startDateStr),
        Variable.withString(endDateStr),
      ],
      readsFrom: {db.expenses, db.expenseCategories},
    ).get();
    
    final total = expenses.fold<double>(
      0.0,
      (sum, row) => sum + row.read<double>('amount'),
    );
    
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              'Weekly Expense Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            '${_dateFormat.format(weekStartDate)} - ${_dateFormat.format(weekEndDate)}',
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
          pw.Text(
            'Generated for: $userName',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
          pw.Divider(),
          pw.SizedBox(height: 20),
          
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Expenses:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('Rs.${total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Expenses Table
          pw.Text('Expense Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table(
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue700),
                children: ['Date', 'Category', 'Description', 'Amount (₹)'].map((header) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(header, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  );
                }).toList(),
              ),
              // Data rows
              ...expenses.map((row) {
                return pw.TableRow(
                  children: [
                    _dateFormat.format(DateTime.parse(row.read<String>('date'))),
                    row.read<String>('category_name'),
                    row.read<String>('title'),
                    row.read<double>('amount').toStringAsFixed(2),
                  ].map((cell) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(cell),
                    );
                  }).toList(),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
  
  // Generate monthly report
  static Future<void> generateMonthlyReport({
    required AppDatabase db,
    required int userId,
    required String month, // Format: 'yyyy-MM'
    required String userName,
  }) async {
    // Fetch expenses for the month
    final expenses = await db.getExpensesByMonth(userId, month);
    
    // Fetch category totals
    final categoryTotals = await db.customSelect(
      '''SELECT ec.name, SUM(e.amount) as total FROM expenses e 
         JOIN expense_categories ec ON e.category_id = ec.id 
         WHERE e.user_id = ? AND e.date LIKE ?
         GROUP BY ec.name
         ORDER BY total DESC''',
      variables: [
        Variable.withInt(userId),
        Variable.withString('$month%'),
      ],
      readsFrom: {db.expenses, db.expenseCategories},
    ).get();
    
    final total = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final monthDate = DateTime.parse('$month-01');
    
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              'Monthly Expense Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            _monthFormat.format(monthDate),
            style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
          ),
          pw.Text(
            'Generated for: $userName',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
          pw.Divider(),
          pw.SizedBox(height: 20),
          
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Expenses:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('₹${total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text('Number of Transactions: ${expenses.length}', style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Category Breakdown
          pw.Text('Spending by Category', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(8),
            headers: ['Category', 'Amount (₹)', 'Percentage'],
            data: categoryTotals.map((row) {
              final amount = row.read<double>('total');
              final percentage = (amount / total * 100).toStringAsFixed(1);
              return [
                row.read<String>('name'),
                amount.toStringAsFixed(2),
                '$percentage%',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          
          // All Expenses
          pw.Text('All Transactions', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          ...expenses.map((expense) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(expense.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(_dateFormat.format(DateTime.parse(expense.date)), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
                pw.Text('₹${expense.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
  
  // Generate yearly report
  static Future<void> generateYearlyReport({
    required AppDatabase db,
    required int userId,
    required int year,
    required String userName,
  }) async {
    // Fetch all expenses for the year
    final expenses = await db.customSelect(
      '''SELECT e.*, ec.name as category_name FROM expenses e 
         JOIN expense_categories ec ON e.category_id = ec.id 
         WHERE e.user_id = ? AND e.date LIKE ?
         ORDER BY e.date DESC''',
      variables: [
        Variable.withInt(userId),
        Variable.withString('$year%'),
      ],
      readsFrom: {db.expenses, db.expenseCategories},
    ).get();
    
    // Calculate monthly totals
    final monthlyTotals = <String, double>{};
    for (final row in expenses) {
      final date = row.read<String>('date');
      final month = date.substring(0, 7); // Extract 'yyyy-MM'
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + row.read<double>('amount');
    }
    
    // Category totals for the year
    final categoryTotals = await db.customSelect(
      '''SELECT ec.name, SUM(e.amount) as total FROM expenses e 
         JOIN expense_categories ec ON e.category_id = ec.id 
         WHERE e.user_id = ? AND e.date LIKE ?
         GROUP BY ec.name
         ORDER BY total DESC''',
      variables: [
        Variable.withInt(userId),
        Variable.withString('$year%'),
      ],
      readsFrom: {db.expenses, db.expenseCategories},
    ).get();
    
    final total = expenses.fold<double>(
      0.0,
      (sum, row) => sum + row.read<double>('amount'),
    );
    
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              'Yearly Expense Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Year: $year',
            style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
          ),
          pw.Text(
            'Generated for: $userName',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
          pw.Divider(),
          pw.SizedBox(height: 20),
          
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Expenses:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('₹${total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text('Number of Transactions: ${expenses.length}', style: const pw.TextStyle(fontSize: 12)),
                pw.Text('Average Monthly Expense: ₹${(total / 12).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Monthly Breakdown
          pw.Text('Monthly Breakdown', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(8),
            headers: ['Month', 'Amount (₹)'],
            data: List.generate(12, (i) {
              final month = '$year-${(i + 1).toString().padLeft(2, '0')}';
              final amount = monthlyTotals[month] ?? 0.0;
              final monthDate = DateTime.parse('$month-01');
              return [
                _monthFormat.format(monthDate),
                amount.toStringAsFixed(2),
              ];
            }),
          ),
          pw.SizedBox(height: 20),
          
          // Category Breakdown
          pw.Text('Spending by Category', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(8),
            headers: ['Category', 'Amount (₹)', 'Percentage'],
            data: categoryTotals.map((row) {
              final amount = row.read<double>('total');
              final percentage = (amount / total * 100).toStringAsFixed(1);
              return [
                row.read<String>('name'),
                amount.toStringAsFixed(2),
                '$percentage%',
              ];
            }).toList(),
          ),
        ],
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}

