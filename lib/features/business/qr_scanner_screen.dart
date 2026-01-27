import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/providers/terminal_provider.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Tarayıcı (Terminal)')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleBarcode(barcode.rawValue!);
                  break; // Process only one
                }
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _handleBarcode(String customerId) async {
    setState(() => _isProcessing = true);
    // Pause scanner
    // _controller.stop(); // Optional, but usually good to prevent multiple scans

    try {
      // Mock Amount for now, or ask user? 
      // Plan said "QR Scanning Endpoint (Mock)". 
      // Let's assume a fixed amount or ask user.
      // For simplicity, let's process 100 TL transaction automatically.
      
      final result = await context.read<TerminalProvider>().processTransaction(customerId, 100.0);
      
      if (!mounted) return;
      
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('İşlem Başarılı'),
          content: Text('Puan Eklendi: ${result['pointsAdded']}\nToplam Puan: ${result['totalPoints']}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Tamam')
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        // _controller.start();
      }
    }
  }
}

