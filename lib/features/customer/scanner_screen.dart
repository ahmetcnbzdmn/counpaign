import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/icons/takeaway_cup_icon.dart';
import '../../core/providers/language_provider.dart';
import '../../core/services/api_service.dart';

class CustomerScannerScreen extends StatefulWidget {
  final Map<String, dynamic>? extra; // To accept expectedBusinessId etc.
  const CustomerScannerScreen({super.key, this.extra});

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
  bool _isProcessing = false;

  // Expected Business Data & Stats
  String? _expectedBusinessId;
  String? _expectedBusinessName;
  Color? _expectedBusinessColor;
  int _currentStamps = 0;
  int _targetStamps = 6;
  int _currentGifts = 0;
  String _currentPoints = "0";

  @override
  void initState() {
    super.initState();
    print("🚀 CustomerScannerScreen INIT. Extra: ${widget.extra}");
    if (widget.extra != null) {
      _expectedBusinessId = widget.extra!['expectedBusinessId'];
      _expectedBusinessName = widget.extra!['expectedBusinessName'];
      
      _currentStamps = widget.extra!['currentStamps'] ?? 0;
      _targetStamps = widget.extra!['targetStamps'] ?? 6;
      _currentGifts = widget.extra!['currentGifts'] ?? 0;
      _currentPoints = (widget.extra!['currentPoints'] ?? "0").toString();

      _expectedBusinessColor = widget.extra!['expectedBusinessColor'] is Color 
          ? widget.extra!['expectedBusinessColor'] 
          : null;
       
       print("✅ Expected Business: $_expectedBusinessName (ID: $_expectedBusinessId)");

       // Parse color if string
       if (widget.extra!['expectedBusinessColor'] is String) {
          try {
             _expectedBusinessColor = Color(int.parse((widget.extra!['expectedBusinessColor'] as String).replaceAll('#', '0xFF')));
          } catch (_) {}
       }
    } else {
      print("❌ No Extras received in Scanner Screen!");
    }
  }

  void _handleScan(BuildContext context, String token) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    
    print("📸 Scanning Token: $token");

    try {
      final apiService = context.read<ApiService>();
      
      // Pass expected ID to backend for validation
      final result = await apiService.scanBusinessQR(token, expectedBusinessId: _expectedBusinessId);
      
      print("📩 Scan Result: $result");
      
      if (!mounted) return;

      // Logic check (Redundant if backend enforces it, but safe to keep)
      if (_expectedBusinessId != null && result['business']['id'].toString() != _expectedBusinessId.toString()) {
           print("⛔️ Logic Mismatch Detected (Should have been caught by backend)");
           throw Exception("FIRM_MISMATCH");
      }

      // Start Polling for Confirmation
      // Show waiting dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const SizedBox(height: 16),
                   const CircularProgressIndicator(color: Color(0xFFEE2C2C)),
                   const SizedBox(height: 24),
                   Text(
                     Provider.of<LanguageProvider>(context, listen: false).translate('waiting_approval'),
                     textAlign: TextAlign.center,
                     style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     Provider.of<LanguageProvider>(context, listen: false).translate('waiting_approval_msg'),
                     textAlign: TextAlign.center,
                     style: GoogleFonts.outfit(color: Colors.grey),
                   ),
                   const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      }

      // Check status loop
      bool isConfirmed = false;
      bool isCancelled = false;
      int attempts = 0;
      Map<String, dynamic>? finalResult;
      
      // Use pollToken from static QR response if available...
      final pollingToken = result['pollToken'] ?? token;
      
      while (attempts < 30) {
         if (!mounted) break;
         
         await Future.delayed(const Duration(seconds: 2));
         try {
            final statusResult = await apiService.checkConfirmationStatus(pollingToken);
            
            if (statusResult['status'] == 'used') {
               isConfirmed = true;
               finalResult = statusResult;
               break;
            } else if (statusResult['status'] == 'cancelled') {
               isConfirmed = false;
               isCancelled = true;
               break;
            }
         } catch (e) {
            print("⚠️ Polling Error: $e");
         }
         attempts++;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // Close waiting dialog
         
      if (isConfirmed) {
         if (mounted) {
            final bId = _expectedBusinessId ?? result['business']?['id'] ?? '';
            final tId = finalResult?['transactionId'] ?? '';
            print("⭐ Triggering Rating for Transaction: $tId at Business: $bId");
            await _showRatingDialog(context, tId, bId);
         }
         if (mounted) context.pop(true);
      } else if (isCancelled) {
          // [NEW] Handle Cancellation
          if (mounted) {
            await showCustomPopup(
              context,
              message: Provider.of<LanguageProvider>(context, listen: false).translate('kod_iptal_edildi'),
              type: PopupType.error,
            );
          }
           // Stay on scanner (or pop depending on UX preference, usually stay to scan again)
      } else {
         if (mounted) {
            await showCustomPopup(
              context,
              message: Provider.of<LanguageProvider>(context, listen: false).translate('timeout_msg'),
              type: PopupType.error,
            );
         }
      }

    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = Provider.of<LanguageProvider>(context, listen: false).translate('scan_error_title');
      
      // Improved Error Handling
      if (e.toString().contains("FIRM_MISMATCH")) {
          errorMessage = "${Provider.of<LanguageProvider>(context, listen: false).translate('firm_mismatch_error')}$_expectedBusinessName";
      } else if (e.toString().contains("404") || e.toString().contains("Invalid or expired")) {
         errorMessage = Provider.of<LanguageProvider>(context, listen: false).translate('expired_qr_error');
      } else if (e.toString().contains("400")) { 
         errorMessage = Provider.of<LanguageProvider>(context, listen: false).translate('invalid_qr_error');
      } else if (e.toString().contains("401")) {
         errorMessage = Provider.of<LanguageProvider>(context, listen: false).translate('session_error');
      } else if (e.toString().contains("CANCELLED_BY_HOST")) {
         errorMessage = Provider.of<LanguageProvider>(context, listen: false).translate('kod_iptal_edildi');
      } else {
         errorMessage = "${Provider.of<LanguageProvider>(context, listen: false).translate('error')}: $e";
      }

      showCustomPopup(
        context,
        message: errorMessage,
        type: PopupType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
  Future<void> _showRatingDialog(BuildContext context, String transactionId, String businessId) async {
    int rating = 5;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              // Success Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                Provider.of<LanguageProvider>(context).translate('approved'),
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  Provider.of<LanguageProvider>(context).translate('rate_subtitle'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                ),
              ),
              const SizedBox(height: 30),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setModalState(() => rating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.coffee_rounded,
                        size: 40,
                        color: index < rating ? Colors.amber : Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              // Comment Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: Provider.of<LanguageProvider>(context).translate('rating_comment_hint'),
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          Provider.of<LanguageProvider>(context).translate('skip'),
                          style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEE2C2C),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: isSubmitting ? null : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            if (transactionId.isEmpty || businessId.isEmpty) {
                               throw Exception("Geçersiz işlem veya işletme ID.");
                            }

                            final api = context.read<ApiService>();
                            await api.submitReview(
                              transactionId,
                              businessId,
                              rating,
                              commentController.text,
                            );
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            print("❌ Review Error: $e");
                            setModalState(() => isSubmitting = false);
                            if (mounted) {
                               showCustomPopup(
                                 context, 
                                 message: e.toString(), 
                                 type: PopupType.error
                               );
                            }
                          }
                        },
                        child: isSubmitting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(Provider.of<LanguageProvider>(context).translate('submit_review'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no specific business is passed, show generic UI (or empty)
    final isGeneric = _expectedBusinessName == null;
    final brandColor = _expectedBusinessColor ?? const Color(0xFF4CAF50); // Default Green if null

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
                      '${Provider.of<LanguageProvider>(context).translate('camera_error')}: ${error.errorCode}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  _handleScan(context, barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          
          // Custom Overlay Frame
          CustomPaint(
            painter: _ScannerOverlayPainter(
              borderColor: Colors.white, // Frame always white as per design
              borderRadius: 30,
              borderLength: 50,
              borderWidth: 8,
              cutoutSize: 280,
            ),
            child: Container(),
          ),

          // TOP BAR
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close Button
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.black45, 
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                    
                    // Title
                    Text(
                      Provider.of<LanguageProvider>(context).translate('scan_qr_title'),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),

                    // Flash Button
                    GestureDetector(
                      onTap: () {
                         setState(() {
                           _isFlashOn = !_isFlashOn;
                           _scannerController.toggleTorch();
                         });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.black45, 
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // BOTTOM SHEET (Info Overlay)
          if (!isGeneric)
             Positioned(
               bottom: 0, left: 0, right: 0,
               child: Container(
                 padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                 decoration: const BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                 ),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     // HEADER: Icon, Name, Progress
                     Row(
                       children: [
                         // Brand Logo/Icon
                         Container(
                           width: 50, height: 50,
                           decoration: BoxDecoration(
                             color: brandColor,
                             shape: BoxShape.circle,
                           ),
                           child: const Icon(Icons.local_cafe, color: Colors.white, size: 24),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 _expectedBusinessName ?? Provider.of<LanguageProvider>(context).translate('unknown_business'), 
                                 style: GoogleFonts.outfit(
                                   color: Colors.black, 
                                   fontSize: 20, 
                                   fontWeight: FontWeight.bold
                                 )
                               ),
                               Text(
                                 Provider.of<LanguageProvider>(context).translate('earn_points_msg'),
                                 style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                               ),
                             ],
                           ),
                         ),
                         // Progress Pill
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                           decoration: BoxDecoration(
                             color: Colors.green[50], // Light green bg
                             borderRadius: BorderRadius.circular(20),
                           ),
                           child: Text(
                             "$_currentStamps/$_targetStamps",
                             style: GoogleFonts.outfit(
                               color: Colors.green[700],
                               fontWeight: FontWeight.bold,
                               fontSize: 16,
                             ),
                           ),
                         ),
                       ],
                     ),
                     
                     const SizedBox(height: 24),

                     // STATS ROW (Gifts & Points)
                     Row(
                       children: [
                         Expanded(
                           child: Container(
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(
                               color: Colors.grey[100],
                               borderRadius: BorderRadius.circular(16),
                             ),
                             child: Row(
                               children: [
                                 const Icon(Icons.card_giftcard, color: Colors.grey, size: 20),
                                 const SizedBox(width: 8),
                                 Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(Provider.of<LanguageProvider>(context).translate('gift'), style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 11)),
                                     Text("$_currentGifts", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                                   ],
                                 )
                               ],
                             ),
                           ),
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Container(
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(
                               color: Colors.grey[100],
                               borderRadius: BorderRadius.circular(16),
                             ),
                             child: Row(
                               children: [
                                 const Icon(Icons.sell_outlined, color: Colors.grey, size: 20),
                                 const SizedBox(width: 8),
                                 Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(Provider.of<LanguageProvider>(context).translate('total_points'), style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 11)),
                                     Text(_currentPoints, style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                                   ],
                                 )
                               ],
                             ),
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
      ..color = Colors.black.withOpacity(0.7)
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

    final double arcSize = borderRadius; 

    // Helper to draw corner
    void drawCorner(double x, double y, double startAngle) {
       final Path path = Path();
       // e.g. For Top Left: Start at (left, top+len) -> line to (left, top+rad) -> arc to (left+rad, top) -> line to (left+len, top)
       // Simplified approach: just draw arcs and lines manually
    }
    
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
