// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _mobileScannerController =
      MobileScannerController();
  bool _scanning = true;

  void _onBarcodeDetect(BarcodeCapture barcodeCapture) {
    if (_scanning && barcodeCapture.barcodes.isNotEmpty) {
      final barcode = barcodeCapture.barcodes.first.rawValue;

      if (barcode != null && barcode.isNotEmpty) {
        setState(() {
          _scanning = false;
        });
        _mobileScannerController.stop();
        Navigator.pop(context, barcode);
      }
    }
  }

  @override
  void dispose() {
    _mobileScannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        centerTitle: true,
      ),
      body: Center(
        child: _scanning
            ? MobileScanner(
                controller: _mobileScannerController,
                onDetect: _onBarcodeDetect,
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
