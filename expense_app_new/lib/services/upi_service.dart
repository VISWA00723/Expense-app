import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class UpiService {
  /// Launches a UPI payment intent.
  /// 
  /// [pa] Payee VPA (e.g., merchant@upi)
  /// [pn] Payee Name
  /// [am] Amount
  /// [tn] Transaction Note
  /// [cu] Currency (default INR)
  /// Creates a validated UPI URI.
  /// 
  /// Throws [ArgumentError] if inputs are invalid.
  static Uri createUpiUri({
    required String upiId,
    required String name,
    required double amount,
    String? note,
    String currency = 'INR',
  }) {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }
    if (upiId.isEmpty || !upiId.contains('@')) {
      throw ArgumentError('Invalid UPI ID format');
    }
    if (name.isEmpty) {
      throw ArgumentError('Payee name is required');
    }

    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': upiId,
        'pn': name,
        'am': amount.toStringAsFixed(2),
        if (note != null && note.isNotEmpty) 'tn': note,
        'cu': currency,
      },
    );
  }

  /// Launches a UPI payment intent.
  static Future<void> launchUpi({
    String? pa,
    String? pn,
    required double am,
    String? tn,
    String cu = 'INR',
  }) async {
    try {
      // Use the helper to create and validate the URI
      // We assume 'pa' and 'pn' are provided for a full transaction, 
      // but for generic launch we might be lenient. 
      // However, to match the goal, let's enforce them if possible, 
      // or fall back to a simpler construction if we just want to open the app.
      
      // For the specific user request "upi://pay?pa=...&pn=...&am=...&cu=...",
      // we need these fields.
      
      // If pa/pn are null, we can't build a valid specific payment URI.
      // But the previous implementation allowed nulls. 
      // Let's update to use the robust createUpiUri if data is present.
      
      if (pa != null && pn != null) {
        final uri = createUpiUri(
          upiId: pa,
          name: pn,
          amount: am,
          note: tn,
          currency: cu,
        );
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch UPI app';
        }
      } else {
        // Fallback for partial data (though less useful for payments)
        final uri = Uri(
          scheme: 'upi',
          host: 'pay',
          queryParameters: {
            if (pa != null) 'pa': pa,
            if (pn != null) 'pn': pn,
            'am': am.toStringAsFixed(2),
            if (tn != null) 'tn': tn,
            'cu': cu,
          },
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch UPI app';
        }
      }
    } catch (e) {
      debugPrint('Error launching UPI: $e');
      rethrow;
    }
  }
}
