import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

class ReceiptScanningService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<ReceiptData> scanReceipt(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    return _parseReceiptText(recognizedText.text);
  }

  // Public wrapper for testing
  ReceiptData parseReceiptTextForTesting(String text) {
    return _parseReceiptText(text);
  }

  ReceiptData _parseReceiptText(String text) {
    String? merchant;
    double? amount;
    DateTime? date;

    final lines = text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 1. Extract Merchant
    // Heuristic: Check top 5 lines. First line that isn't a date, phone, or common header is likely the merchant.
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      if (line.length < 3) continue;
      
      // Skip if it looks like a date or phone number
      if (_extractDate(line) != null || _isPhoneNumber(line)) continue;

      // Skip common header words
      final lower = line.toLowerCase();
      if (lower.contains('receipt') || 
          lower.contains('invoice') || 
          lower.contains('welcome') ||
          lower.contains('customer') ||
          lower.contains('copy') ||
          lower.contains('tax') ||
          lower.contains('bill')) {
        continue;
      }

      // If we found a candidate, use it
      merchant = line;
      break;
    }

    // 2. Extract Date
    // Try to find a date in any line.
    for (final line in lines) {
      final extractedDate = _extractDate(line);
      if (extractedDate != null) {
        date = extractedDate;
        break; // Assume first found date is the transaction date
      }
    }

    // 3. Extract Amount
    // Strategy: Look for "Total" lines first.
    // Then look for the largest number with 2 decimal places.
    
    double? maxAmount;
    double? totalLineAmount;

    // Regex to find currency-like numbers: 
    // Matches: 1,234.56 | 1234.56 | 1234
    // We look for numbers that might have a currency symbol before them
    // Supported: $, €, £, ₹, ¥, A$, C$, Rs, INR, USD, EUR, GBP, AUD, CAD, JPY, CNY
    final amountRegex = RegExp(r'(?:[\$€£₹¥]|Rs\.?|INR|USD|EUR|GBP|AUD|CAD|JPY|CNY|[A-Z]{1,3}\$)?\s*(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})');

    for (final line in lines) {
      final lower = line.toLowerCase();
      final isTotalLine = lower.contains('total') || 
                          lower.contains('amount due') || 
                          lower.contains('grand total') ||
                          lower.contains('balance');
      
      // Skip subtotal lines to avoid confusion
      if (lower.contains('subtotal') || lower.contains('sub total')) continue;

      final matches = amountRegex.allMatches(line);
      for (final match in matches) {
        // Group 1 is the number part
        String numStr = match.group(1) ?? '';
        double? val = _parseAmount(numStr);
        
        if (val == null) continue;

        if (isTotalLine) {
          // If multiple numbers on total line, usually the last one is the amount
          totalLineAmount = val; 
        }

        if (maxAmount == null || val > maxAmount) {
          maxAmount = val;
        }
      }
    }

    // Prefer the amount found on a "Total" line, otherwise use the largest amount found
    amount = totalLineAmount ?? maxAmount;

    return ReceiptData(
      merchant: merchant,
      amount: amount,
      date: date,
      rawText: text,
    );
  }

  // Helper to check for phone numbers (simple heuristic)
  bool _isPhoneNumber(String text) {
    final phoneRegex = RegExp(r'(\+\d{1,3}[- ]?)?\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}');
    return phoneRegex.hasMatch(text);
  }

  // Helper to parse amount string like "1,234.56" or "1.234,56"
  double? _parseAmount(String text) {
    try {
      // Remove any non-numeric characters except . and ,
      String clean = text.replaceAll(RegExp(r'[^0-9.,]'), '');
      
      // If it contains both . and ,
      if (clean.contains('.') && clean.contains(',')) {
        if (clean.lastIndexOf('.') > clean.lastIndexOf(',')) {
          // Format: 1,234.56 -> Remove ,
          clean = clean.replaceAll(',', '');
        } else {
          // Format: 1.234,56 -> Remove . and replace , with .
          clean = clean.replaceAll('.', '').replaceAll(',', '.');
        }
      } else if (clean.contains(',')) {
        // If only comma, check if it's likely a decimal separator (2 digits at end)
        // or just a thousands separator.
        if (clean.indexOf(',') == clean.length - 3) {
           clean = clean.replaceAll(',', '.');
        } else {
           clean = clean.replaceAll(',', '');
        }
      }
      
      return double.tryParse(clean);
    } catch (e) {
      return null;
    }
  }

  // Helper to extract date from a line
  DateTime? _extractDate(String text) {
    // Formats:
    // 1. DD/MM/YYYY or MM/DD/YYYY or YYYY/MM/DD (separators: / - .)
    // 2. DD MMM YYYY (12 Jan 2023)
    // 3. MMM DD, YYYY (Jan 12, 2023)
    
    final datePatterns = [
      // DD/MM/YYYY or MM/DD/YYYY or YYYY-MM-DD
      RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b'),
      RegExp(r'\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})\b'),
      
      // DD MMM YYYY (e.g., 12 Jan 2023)
      RegExp(r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{2,4})\b', caseSensitive: false),
      
      // MMM DD, YYYY (e.g., Jan 12, 2023)
      RegExp(r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}),?\s+(\d{2,4})\b', caseSensitive: false),
    ];

    for (final regex in datePatterns) {
      final match = regex.firstMatch(text);
      if (match != null) {
        try {
          // Logic to parse specific groups based on pattern would be complex here.
          // Instead, let's try to parse the matched string using DateFormat if possible,
          // or manually construct.
          
          // Simplified manual construction for robustness:
          String fullMatch = match.group(0)!;
          
          // Try textual formats first
          try {
            return DateFormat('d MMM y').parse(fullMatch);
          } catch (_) {}
          try {
            return DateFormat('MMM d, y').parse(fullMatch);
          } catch (_) {}

          // Fallback: Manual parsing for numeric dates
          if (match.groupCount == 3) {
             // Check if it's numeric
             if (RegExp(r'^\d+$').hasMatch(match.group(1)!)) {
               int p1 = int.parse(match.group(1)!);
               int p2 = int.parse(match.group(2)!);
               int p3 = int.parse(match.group(3)!);
               
               if (p3 > 1000) { // YYYY is last
                 // Check for obvious invalid months/days to help disambiguate
                 if (p2 > 12) {
                   // p2 MUST be Day, p1 is Month
                   return DateTime(p3, p1, p2);
                 }
                 if (p1 > 12) {
                   // p1 MUST be Day, p2 is Month
                   return DateTime(p3, p2, p1);
                 }
                 
                 // Both <= 12. Ambiguous.
                 // Default to DD/MM/YYYY (International/India)
                 return DateTime(p3, p2, p1);
               } else if (p1 > 1000) { // YYYY is first
                 return DateTime(p1, p2, p3);
               }
             }
          }
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  // Stage 1: Clean and normalize raw OCR text
  String cleanRawText(String rawText) {
    // Remove common UI noise and irrelevant words
    final noiseRegex = RegExp(
      r'\b(Home|Save|Search|Share|Visit|SampleTemplates|Notifications|Copyright|Learn More|Images may be subject|KB/S|Vo 5G)\b',
      caseSensitive: false,
    );
    
    final lines = rawText.split('\n');
    final cleanedLines = <String>[];
    
    for (var line in lines) {
      // Remove noise words
      var cleaned = line.replaceAll(noiseRegex, '').trim();
      
      // Skip empty or very short lines (unless they look like numbers)
      if (cleaned.isEmpty || (cleaned.length < 2 && !RegExp(r'\d').hasMatch(cleaned))) {
        continue;
      }
      
      // Normalize money (e.g., "3,000/day" -> "3000/day")
      // We keep the structure but clean up the formatting for the LLM
      cleaned = cleaned.replaceAll(RegExp(r'₹\s?'), 'Rs '); // Normalize currency symbol
      
      cleanedLines.add(cleaned);
    }
    
    return cleanedLines.join('\n');
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class ReceiptData {
  final String? merchant;
  final double? amount;
  final DateTime? date;
  final String rawText;

  ReceiptData({
    this.merchant,
    this.amount,
    this.date,
    required this.rawText,
  });

  @override
  String toString() {
    return 'Merchant: $merchant, Amount: $amount, Date: $date';
  }
}
