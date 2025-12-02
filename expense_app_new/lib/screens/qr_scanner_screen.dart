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
            if (rawValue != null && rawValue.startsWith('upi://')) {
              _isProcessing = true;
              // Extract 'pa' parameter
              final uri = Uri.parse(rawValue);
              final vpa = uri.queryParameters['pa'];
              
              if (vpa != null) {
                Navigator.pop(context, vpa);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid UPI QR: No Payee Address found')),
                );
                _isProcessing = false;
              }
              return;
            }
          }
        },
      ),
    );
  }
}
