import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/language_provider.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/auto_text.dart';
import 'scanner_screen.dart';

class GiftSelectionScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final double currentPoints;
  final int currentGifts;

  const GiftSelectionScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.currentPoints,
    required this.currentGifts,
  });

  @override
  State<GiftSelectionScreen> createState() => _GiftSelectionScreenState();
}

class _GiftSelectionScreenState extends State<GiftSelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoading = true;
  List<dynamic> _gifts = [];

  // State for redemption process
  String? _redeemingGiftId; 

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _fetchGifts();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchGifts() async {
    try {
      final api = context.read<ApiService>();
      final gifts = await api.getBusinessGifts(widget.businessId);
      setState(() {
        _gifts = gifts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching gifts: $e");
      setState(() => _isLoading = false);
    }
  }


  Future<void> _redeemGift(dynamic gift) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final api = context.read<ApiService>();
    
    // 1. Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.translate('confirm_redeem_title'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          "${lang.translate('confirm_redeem_msg')}${gift['title']}?\n(${gift['pointCost']} ${lang.translate('points')})",
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.translate('cancel'), style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEE2C2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.translate('confirm'), style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Prepare Redemption (creates token on backend)
    setState(() => _redeemingGiftId = gift['_id']);

    try {
      await api.prepareRedemption(widget.businessId, gift['_id']);
      
      // 3. Open QR Scanner to scan business's static QR
      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => CustomerScannerScreen(
              extra: {
                'expectedBusinessId': widget.businessId,
                'expectedBusinessName': widget.businessName,
              },
            ),
          ),
        );

        // If scanner returned true (success), go home
        if (result == true && mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = lang.translate('error');
        if (e.toString().contains('Yetersiz puan')) {
          errorMsg = lang.translate('insufficient_points');
        }
        showCustomPopup(
          context,
          message: errorMsg,
          type: PopupType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _redeemingGiftId = null);
    }
  }

  Future<void> _redeemGiftEntitlement() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final api = context.read<ApiService>();

    // 1. Confirm Entitlement Usage
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.translate('redeem_entitlement_title'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          lang.translate('gift_entitlement_confirm'),
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.translate('cancel'), style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEE2C2C)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.translate('confirm'), style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Prepare Redemption & Open Scanner
    try {
      await api.prepareRedemption(widget.businessId, "", type: 'GIFT_ENTITLEMENT');

      // 3. Open QR Scanner to scan business's static QR
      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => CustomerScannerScreen(
              extra: {
                'expectedBusinessId': widget.businessId,
                'expectedBusinessName': widget.businessName,
              },
            ),
          ),
        );

        // If scanner returned true (success), go home
        if (result == true && mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomPopup(
          context,
          message: lang.translate('gift_error_msg'),
          type: PopupType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final int giftsCount = widget.currentGifts;
    final bool isTr = lang.locale.languageCode == 'tr';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean off-white background
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          lang.translate('gift_selection_title'), 
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A), 
            fontWeight: FontWeight.bold,
            fontSize: 18,
          )
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0,2))
                ]
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A), size: 20),
            ),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      extendBodyBehindAppBar: true, 
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Creative Ticket Header
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation.value),
                  child: child,
                );
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                child: Stack(
                  children: [
                    // Shadow
                    Positioned.fill(
                      top: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    
                    // Ticket Shape
                    ClipPath(
                      clipper: _TicketClipper(),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 280, // Explicit height for ticket
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)], // Brand Red
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          
                          // Shimmer/Glow Overlay
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.0),
                                        Colors.white.withValues(alpha: 0.1),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                      stops: const [0.3, 0.5, 0.7],
                                      begin: Alignment(-2.0 + (_animation.value / 10 * 4), -1.0),
                                      end: Alignment(2.0 + (_animation.value / 10 * 4), 1.0),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          Column(
                            children: [
                              // Top Section
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Text(
                                      widget.businessName.toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isTr ? "KULLANIMA UYGUNDUR" : "VALID FOR REDEMPTION",
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Divider Line
                              SizedBox(
                                height: 1,
                                width: double.infinity,
                                child: CustomPaint(painter: _DashedLinePainter()),
                              ),
                              
                              // Bottom Section (Points)
                              Container(
                                padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          "${widget.currentPoints.toInt()}",
                                          style: GoogleFonts.shareTechMono( // Tech/Ticket Font
                                            fontSize: 64,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            height: 0.9,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      lang.translate('points').toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.8),
                                        letterSpacing: 4.0,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Barcode Visual
                                    SizedBox(
                                      height: 40,
                                      width: 200,
                                      child: CustomPaint(painter: _BarcodePainter()),
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    Text(
                                      lang.translate('spendable_amount'),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
  
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 2. Gift Entitlement Banner (Gold)
                      if (giftsCount > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFC107), Color(0xFFFF8F00)], 
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8F00).withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => _redeemGiftEntitlement(),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -10, bottom: -10,
                                    child: Icon(Icons.card_giftcard, size: 100, color: Colors.white.withValues(alpha: 0.15)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0,2)),
                                            ],
                                          ),
                                          child: const Icon(Icons.celebration_rounded, color: Color(0xFFFF8F00), size: 28),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lang.translate('gift_entitlement_title'),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2)],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "$giftsCount ${lang.translate('gift_entitlement_subtitle')}",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                      // Empty State
                      if (_gifts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.redeem_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
                                const SizedBox(height: 16),
                                Text(
                                  lang.translate('no_gifts_yet'),
                                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      if (_gifts.isNotEmpty)
                        Padding(
                           padding: const EdgeInsets.only(bottom: 16, left: 8),
                           child: Text(
                             lang.translate('available_gifts_header'),
                             style: GoogleFonts.outfit(
                               fontSize: 18,
                               fontWeight: FontWeight.bold,
                               color: const Color(0xFF1A1A1A),
                             ),
                           ),
                        ),
  
                      // 3. Modern Gift List
                      ..._gifts.map((gift) {
                        final cost = gift['pointCost'];
                        final canAfford = widget.currentPoints >= cost;
                        final isRedeeming = _redeemingGiftId == gift['_id'];
  
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04), // Softer shadow
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: (canAfford && !isRedeeming) ? () => _redeemGift(gift) : null,
                              borderRadius: BorderRadius.circular(24),
                              splashColor: const Color(0xFFD32F2F).withValues(alpha: 0.05),
                              highlightColor: const Color(0xFFD32F2F).withValues(alpha: 0.02),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    // Icon Wrapper (Box Style)
                                    Container(
                                      width: 60, height: 60,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: canAfford 
                                            ? const Color(0xFFFFEBEE) // Light Red
                                            : const Color(0xFFF5F5F5), // Light Grey
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.coffee_rounded, // Assuming coffee
                                          color: canAfford ? const Color(0xFFD32F2F) : Colors.grey,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AutoText(
                                            gift['title'],
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: canAfford ? const Color(0xFF1A1A1A) : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.stars_rounded, size: 16, color: canAfford ? const Color(0xFFFBC02D) : Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                "$cost ${lang.translate('points')}",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: canAfford ? const Color(0xFF1A1A1A) : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
  
                                    // Action Button
                                    if (isRedeeming)
                                      const SizedBox(
                                        width: 24, height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD32F2F)),
                                      )
                                    else if (canAfford)
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD32F2F),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: const Color(0xFFD32F2F).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                                          ]
                                        ),
                                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                      )
                                    else
                                      // Locked/Disabled State
                                      Icon(Icons.lock_rounded, color: Colors.grey.withValues(alpha: 0.3), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    
    // Perforation radius and count
    const double perfRadius = 4.0;
    const double sideCutoutRadius = 20.0;
    
    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);
    
    // Main Side Cutouts (where the separator is)
    final double cutoutY = size.height / 2.5;
    path.addOval(Rect.fromCircle(center: Offset(0.0, cutoutY), radius: sideCutoutRadius));
    path.addOval(Rect.fromCircle(center: Offset(size.width, cutoutY), radius: sideCutoutRadius));
    
    // Perforations on Left Edge
    for (double i = 0; i < size.height; i += sideCutoutRadius) {
      if ((i - cutoutY).abs() > sideCutoutRadius) {
         path.addOval(Rect.fromCircle(center: Offset(0.0, i), radius: perfRadius));
      }
    }
    
    // Perforations on Right Edge
    for (double i = 0; i < size.height; i += sideCutoutRadius) {
      if ((i - cutoutY).abs() > sideCutoutRadius) {
         path.addOval(Rect.fromCircle(center: Offset(size.width, i), radius: perfRadius));
      }
    }
    
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 9, dashSpace = 5, startX = 0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;
      
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    final random = Random(42); // Fixed seed for consistent look
    
    double x = 0;
    while (x < size.width) {
      final width = random.nextDouble() * 4 + 1;
      if (x + width > size.width) break;
      
      canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), paint);
      x += width + (random.nextDouble() * 3 + 2);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
