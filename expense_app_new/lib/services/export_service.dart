import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:expense_app_new/database/database.dart';

class ExportService {
  Future<void> exportToCsv(List<Expense> expenses) async {
    final List<List<dynamic>> rows = [];
    
    // Header
    rows.add([
      'Date',
      'Title',
      'Amount',
      'Category',
      'Description',
      'Payment Method',
    ]);

    // Data
    for (final expense in expenses) {
      rows.add([
        expense.date,
        expense.title,
        expense.amount,
        expense.categoryId, // Ideally map to name, but ID is simpler for now
        expense.notes ?? '',
        'Cash', // Default to Cash as paymentMethod is not in DB
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/expenses_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(path)], text: 'My Expenses CSV Export');
  }

  Future<void> exportToPdf(List<Expense> expenses, User user) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();

    final totalAmount = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        ),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Expense Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Generated for ${user.name} on ${DateFormat.yMMMd().format(DateTime.now())}'),
            pw.Divider(),
            pw.SizedBox(height: 16),
          ],
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Expenses:', style: pw.TextStyle(fontSize: 16)),
              pw.Text(
                NumberFormat.currency(symbol: '₹').format(totalAmount),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Table.fromTextArray(
            headers: ['Date', 'Title', 'Category', 'Amount'],
            data: expenses.map((e) => [
              e.date,
              e.title,
              e.categoryId.toString(), // TODO: Map to category name
              NumberFormat.currency(symbol: '₹').format(e.amount),
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
            },
          ),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'expenses_report.pdf');
  }
}
