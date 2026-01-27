import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class CustomerScannerScreen extends StatefulWidget {
  const CustomerScannerScreen({super.key});

  @override
  State<CustomerScannerScreen> createState() => _CustomerScannerScreenState();
}

class _CustomerScannerScreenState extends State<CustomerScannerScreen> {
  // Configured controller
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _isFlashOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _scannerController,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Kamera Hatası: ${error.errorCode}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      error.errorDetails?.message ?? '',
                      style: const TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                debugPrint('Barcode found! ${barcode.rawValue}');
                // Handle scan logic
              }
            },
          ),
          
          // Custom Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(
              borderColor: Colors.white,
              borderRadius: 24,
              borderLength: 40,
              borderWidth: 6,
              cutoutSize: 280,
            ),
            child: Container(),
          ),

          // UI Layer
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Top Text
                Text(
                  "QR Tara",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)
                    ]
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Helper Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Kasiyerin gösterdiği QR kodu okutarak kampanyalardan faydalanabilirsin.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.5,
                      shadows: [
                      Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)
                    ]
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Bottom Button REMOVED
                
                const SizedBox(height: 40),
                
                // Camera Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     IconButton(
                       onPressed: () {
                         setState(() {
                           _isFlashOn = !_isFlashOn;
                           _scannerController.toggleTorch();
                         });
                       }, 
                       icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 32),
                       style: IconButton.styleFrom(backgroundColor: Colors.white24, padding: const EdgeInsets.all(16)),
                     ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Close Button (Top Right)
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black26, 
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutoutSize;

  _ScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutoutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double cutoutHalfSize = cutoutSize / 2;

    // 1. Draw Semi-Transparent Overlay
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.8) // Darker background
      ..style = PaintingStyle.fill;

    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(centerX, centerY), width: cutoutSize, height: cutoutSize),
          Radius.circular(borderRadius),
        ),
      );

    final Path overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(overlayPath, overlayPaint);

    // 2. Draw Corners
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    // Top Left
    final Path topLeft = Path();
    topLeft.moveTo(centerX - cutoutHalfSize, centerY - cutoutHalfSize + borderLength);
    topLeft.lineTo(centerX - cutoutHalfSize, centerY - cutoutHalfSize + borderRadius);
    topLeft.arcToPoint(
      Offset(centerX - cutoutHalfSize + borderRadius, centerY - cutoutHalfSize),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );
    topLeft.lineTo(centerX - cutoutHalfSize + borderLength, centerY - cutoutHalfSize);
    canvas.drawPath(topLeft, borderPaint);

    // Top Right
    final Path topRight = Path();
    topRight.moveTo(centerX + cutoutHalfSize - borderLength, centerY - cutoutHalfSize);
    topRight.lineTo(centerX + cutoutHalfSize - borderRadius, centerY - cutoutHalfSize);
    topRight.arcToPoint(
      Offset(centerX + cutoutHalfSize, centerY - cutoutHalfSize + borderRadius),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );
    topRight.lineTo(centerX + cutoutHalfSize, centerY - cutoutHalfSize + borderLength);
    canvas.drawPath(topRight, borderPaint);

    // Bottom Right
    final Path bottomRight = Path();
    bottomRight.moveTo(centerX + cutoutHalfSize, centerY + cutoutHalfSize - borderLength);
    bottomRight.lineTo(centerX + cutoutHalfSize, centerY + cutoutHalfSize - borderRadius);
    bottomRight.arcToPoint(
      Offset(centerX + cutoutHalfSize - borderRadius, centerY + cutoutHalfSize),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );
    bottomRight.lineTo(centerX + cutoutHalfSize - borderLength, centerY + cutoutHalfSize);
    canvas.drawPath(bottomRight, borderPaint);

    // Bottom Left
    final Path bottomLeft = Path();
    bottomLeft.moveTo(centerX - cutoutHalfSize + borderLength, centerY + cutoutHalfSize);
    bottomLeft.lineTo(centerX - cutoutHalfSize + borderRadius, centerY + cutoutHalfSize);
    bottomLeft.arcToPoint(
      Offset(centerX - cutoutHalfSize, centerY + cutoutHalfSize - borderRadius),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );
    bottomLeft.lineTo(centerX - cutoutHalfSize, centerY + cutoutHalfSize - borderLength);
    canvas.drawPath(bottomLeft, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
