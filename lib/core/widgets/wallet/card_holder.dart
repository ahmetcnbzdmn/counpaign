import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CardHolder extends StatelessWidget {
  final Widget child;
  final double height;
  final String title;

  const CardHolder({
    super.key,
    required this.child,
    this.height = 240,
    this.title = "CÜZDANIM", 
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Back Layer (Dark Leather interior)
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),

        // 2. The Content (Cards) positioned slightly down to look "inside"
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10), 
          child: SizedBox(
            height: height - 20, 
            child: child,
          ),
        ),

        // 3. Front "Lip" or Pocket edge (Visual only, at bottom)
        // This simulates the front part of a leather sleeve
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: IgnorePointer( // Allow clicks to pass through to cards
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2A2A2A).withOpacity(0.0), // Transparent top
                    const Color(0xFF1A1A1A).withOpacity(0.8), // Dark bottom
                    const Color(0xFF111111),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                ),
              ),
            ),
          ),
        ),

        // 4. "Stitching" Detail at top
        Positioned(
          top: 12,
          left: 20,
          right: 20,
          child: IgnorePointer(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                    style: BorderStyle.solid, 
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(20, (index) => Container(
                  width: 4, 
                  height: 1, 
                  color: Colors.black 
                )), // Dashed effect manual
              ),
            ),
          ),
        ),

        // 5. Header / Brand
        Positioned(
          top: 16,
          left: 24,
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.3),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      ],
    );
  }
}
