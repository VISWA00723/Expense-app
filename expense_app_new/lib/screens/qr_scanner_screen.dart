import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan UPI QR')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isProcessing) return;
          
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final rawValue = barcode.rawValue;
            if (rawValue == null) continue;

            setState(() => _isProcessing = true);

            if (rawValue.startsWith('upi://')) {
              try {
                final uri = Uri.parse(rawValue);
                final vpa = uri.queryParameters['pa'];
                
                if (vpa != null) {
                  Navigator.pop(context, vpa);
                  return;
                } else {
                  _showError('Invalid UPI QR: No Payee Address found');
                }
              } catch (e) {
                _showError('Malformed UPI QR code');
              }
            } else {
              _showError('Not a UPI QR code');
            }
            return;
          }
        },
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }
}
