import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/widgets/icons/takeaway_cup_icon.dart';

class WalletCard extends StatefulWidget {
  final Map<String, dynamic> firm;
  final String cardHolderName;
  final VoidCallback? onTap;

  const WalletCard({
    super.key,
    required this.firm,
    this.cardHolderName = 'MÜŞTERİ',
    this.onTap,
  });

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  String _generateCardNumber(dynamic id) {
    // [FIX] Handle null or missing ID safely
    final String safeId = (id ?? '0000000000000000').toString();
    // Generate a pseudo-random looking number based on ID hash
    final hash = safeId.hashCode.toString().padRight(16, '0');
    final s = hash.substring(0, 16);
    return '${s.substring(0, 4)}  ${s.substring(4, 8)}  ${s.substring(8, 12)}  ${s.substring(12, 16)}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * pi;
        final isUnder = angle > pi / 2;
        
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateY(angle);

        return GestureDetector(
          onTap: widget.onTap,
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isUnder 
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi), // Mirror back info so it's readable
                  child: _buildBack(),
                ) 
              : _buildFront(),
          ),
        );
      },
    );
  }

  Widget _buildFront() {
    final color = widget.firm['color'] is Color ? widget.firm['color'] as Color : Colors.grey;
    final stampCount = widget.firm['stamps'] ?? 0;
    final target = widget.firm['stampsTarget'] ?? 6;
    final firmName = (widget.firm['name'] ?? 'KAFE').toString();
    
    // Localization from Provider
    final langProvider = context.watch<LanguageProvider>();
    bool isTr = langProvider.locale.languageCode == 'tr';
    
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Decor
          Positioned(
            right: -20, bottom: -20,
            child: Icon(Icons.credit_card_rounded, size: 150, color: Colors.white.withOpacity(0.05)),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      firmName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Text(
                    'COUNPAIGN',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Card Number
               Row(
                children: [
                   const Icon(Icons.nfc_rounded, color: Colors.white70, size: 32),
                   const SizedBox(width: 16),
                   Expanded(
                     child: FittedBox(
                       fit: BoxFit.scaleDown,
                       alignment: Alignment.centerLeft,
                       child: Text(
                        _generateCardNumber(widget.firm['id']),
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.0,
                          shadows: [Shadow(color: Colors.black26, offset: Offset(0,1), blurRadius: 2)]
                        ),
                       ),
                     ),
                   ),
                ],
              ),
              
              const Spacer(),
              
              // Bottom Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTr ? 'KART SAHİBİ' : 'CARD HOLDER',
                        style: GoogleFonts.outfit(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.cardHolderName.toUpperCase(),
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isTr ? 'DAMGA' : 'STAMP',
                        style: GoogleFonts.outfit(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$stampCount/$target',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          
          // Flip Button
          Positioned(
            right: 0,
            top: 0, 
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _flipCard,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flip_camera_android_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBack() {
    final color = widget.firm['color'] is Color ? widget.firm['color'] as Color : Colors.grey;
    final gifts = widget.firm['giftsCount'] ?? 0;
    final target = widget.firm['stampsTarget'] ?? 6;
    final firmName = (widget.firm['name'] ?? 'KAFE').toString();
    
    // Localization from Provider
    final langProvider = context.watch<LanguageProvider>();
    bool isTr = langProvider.locale.languageCode == 'tr';
    
    String legalText = isTr 
      ? 'Bu kart, $firmName tarafından düzenlenmiştir.\nHer $target damgada 1 hediye kahve kazanırsınız.'
      : 'This card is issued by $firmName.\nCollect $target stamps to get 1 free coffee.';
      
    String subText = isTr 
      ? 'Mülkiyeti işletmeye aittir. Kurallara tabidir.'
      : 'Property of issuer. Subject to terms.';

    return Container(
      width: double.infinity,
      height: 220,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
             HSLColor.fromColor(color).withLightness(0.25).toColor(),
             HSLColor.fromColor(color).withLightness(0.35).toColor(),
          ],
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
           // 1. Magstripe (Top)
           Positioned(
             top: 25, left: 0, right: 0,
             child: Container(height: 45, color: const Color(0xFF151515)),
           ),
           
           // 2. White Strip (Signature Area)
           Positioned(
             top: 85, left: 0, right: 0,
             child: Container(
               height: 40,
               margin: const EdgeInsets.symmetric(horizontal: 24),
               decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.9),
                 borderRadius: BorderRadius.circular(4),
               ),
               child: Row(
                 children: [
                   // Signature Pattern Area (Programmatic)
                   Expanded(
                     child: ClipRRect(
                       borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                       child: CustomPaint(
                         painter: _SignaturePatternPainter(),
                         child: Container(),
                       ),
                     ),
                   ),
                   // CVV / Gift Count Area
                   Container(
                     width: 60,
                     alignment: Alignment.center,
                     color: Colors.white,
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Text(
                           '$gifts', 
                           style: GoogleFonts.outfit(
                             color: Colors.red[700], 
                             fontWeight: FontWeight.w900, 
                             fontSize: 18,
                             fontStyle: FontStyle.italic,
                           )
                         ),
                         const SizedBox(width: 2),
                         Icon(Icons.coffee_rounded, size: 14, color: Colors.brown[400]),
                       ],
                     ),
                   ),
                 ],
               ),
             ),
           ),
           
           // 3. Bottom Legal Text (Dynamic)
           Positioned(
             bottom: 25, left: 24, right: 60,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   legalText,
                   style: GoogleFonts.outfit(color: Colors.white60, fontSize: 9, height: 1.4),
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                 ),
                 const SizedBox(height: 4),
                 Text(
                   subText,
                   style: GoogleFonts.outfit(color: Colors.white38, fontSize: 8),
                 ),
               ],
             ),
           ),

          // Flip Button
          Positioned(
            right: 16,
            bottom: 16,
            child: GestureDetector(
              onTap: _flipCard,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flip_camera_android_rounded, color: Colors.white, size: 20),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _Rotating3DCup extends StatelessWidget {
  final double size;
  final Color color;
  final int stamps;
  final int target;

  const _Rotating3DCup({
    required this.size, 
    required this.color,
    required this.stamps,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) 
        ..rotateY(-0.4), 
      child: TakeawayCupIcon(
        size: size, 
        cupColor: color,
        fillLevel: 1.0, // Always full for gift view? Or maybe valid? Let's show full for aesthetics.
      ),
    );
  }
}

class _SignaturePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.0;
      
    // Draw diagonal lines
    for (double x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
