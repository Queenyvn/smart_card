import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String? lastScanned; // To prevent duplicate scans
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Scanner"),
        backgroundColor: Colors.red,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (isProcessing) return; 
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;
            if (code != null && code != lastScanned) {
              setState(() {
                lastScanned = code;
                isProcessing = true;
              });
              debugPrint('Barcode found: $code');

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Scanned QR Code"),
                  content: Text(code),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          isProcessing = false; 
                        });
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            }
          }
        },
      ),
    );
  }
}
