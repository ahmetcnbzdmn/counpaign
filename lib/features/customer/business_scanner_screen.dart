import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

class BusinessScannerScreen extends StatefulWidget {
  final Map<String, dynamic> businessData;

  const BusinessScannerScreen({super.key, required this.businessData});

  @override
  State<BusinessScannerScreen> createState() => _BusinessScannerScreenState();
}

class _BusinessScannerScreenState extends State<BusinessScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  
  // Real Local state to allow refreshing UI on sim
  late int _stamps;
  late int _stampsTarget;
  late int _giftsCount;
  late String _points;
  late String _businessId;
  late Color _brandColor;

  @override
  void initState() {
    super.initState();
    final data = widget.businessData;
    _stamps = data['stamps'] ?? 0;
    _stampsTarget = data['stampsTarget'] ?? 6;
    _giftsCount = data['giftsCount'] ?? 0;
    _points = data['points'] ?? '0';
    _businessId = data['id'] ?? '';
    _brandColor = data['color'] ?? const Color(0xFFEE2C2C);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processScan() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    try {
      final api = context.read<ApiService>();
      final result = await api.simulateProcessTransaction(user.id, _businessId);
      
      if (mounted) {
        setState(() {
          _stamps = result['stamps'];
          _stampsTarget = result['stampsTarget'];
          _giftsCount = result['giftsCount'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("İşlem Başarılı! 🎉"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _addPoints() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    try {
      final api = context.read<ApiService>();
      final result = await api.simulateAddPoints(user.id, _businessId, 10);
      
      if (mounted) {
        setState(() {
          _points = result['points'].toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("10 Puan Eklendi! ⭐️"),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. CAMERA PREVIEW
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              // Real scanning logic would go here
              // For now we just show it works
              _processScan();
            },
          ),

          // 2. SCAN OVERLAY (Darkened around cutout)
          Positioned.fill(
             child: CustomPaint(
               painter: _ScannerOverlayPainter(
                 cutoutSize: 250,
               ),
             ),
          ),

          // 3. TOP MENU
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context, {
                    'stamps': _stamps,
                    'stampsTarget': _stampsTarget,
                    'giftsCount': _giftsCount,
                    'points': _points,
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                ),
                Text(
                  "QR TARA",
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => _scannerController.toggleTorch(),
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black26),
                ),
              ],
            ),
          ),

          // 4. BOTTOM INFO SHEET (The Cafe Info & Simulation Button)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cafe Logo & Name
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: _brandColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_cafe, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.businessData['name'] ?? "Kafe", 
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                            Text("QR kodu tarayarak puan kazanın", 
                              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                      // Stats Mini
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _brandColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text("$_stamps/$_stampsTarget", 
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: _brandColor)),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Info Cards Row
                  Row(
                    children: [
                      _buildInfoSmallCard("Hediye", "$_giftsCount", Icons.card_giftcard),
                      const SizedBox(width: 12),
                      _buildInfoSmallCard("Toplam Puan", _points, Icons.loyalty),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // [SIMULATION BUTTONS]
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: _processScan,
                          child: Text("Stamp (+1)", 
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: _addPoints,
                          child: Text("Puan (+10)", 
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSmallCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double cutoutSize;

  _ScannerOverlayPainter({required this.cutoutSize});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2.5; // Better centered vertically
    final rect = Rect.fromCenter(center: Offset(centerX, centerY), width: cutoutSize, height: cutoutSize);

    // Overlay
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)));
    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(overlayPath, paint);

    // Corner Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final double length = 30;
    final double radius = 24;

    // TL
    canvas.drawPath(Path()
      ..moveTo(rect.left, rect.top + length)
      ..lineTo(rect.left, rect.top + radius)
      ..arcToPoint(Offset(rect.left + radius, rect.top), radius: Radius.circular(radius))
      ..lineTo(rect.left + length, rect.top), borderPaint);

    // TR
    canvas.drawPath(Path()
      ..moveTo(rect.right - length, rect.top)
      ..lineTo(rect.right - radius, rect.top)
      ..arcToPoint(Offset(rect.right, rect.top + radius), radius: Radius.circular(radius))
      ..lineTo(rect.right, rect.top + length), borderPaint);

    // BR
    canvas.drawPath(Path()
      ..moveTo(rect.right, rect.bottom - length)
      ..lineTo(rect.right, rect.bottom - radius)
      ..arcToPoint(Offset(rect.right - radius, rect.bottom), radius: Radius.circular(radius))
      ..lineTo(rect.right - length, rect.bottom), borderPaint);

    // BL
    canvas.drawPath(Path()
      ..moveTo(rect.left + length, rect.bottom)
      ..lineTo(rect.left + radius, rect.bottom)
      ..arcToPoint(Offset(rect.left, rect.bottom - radius), radius: Radius.circular(radius))
      ..lineTo(rect.left, rect.bottom - length), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
