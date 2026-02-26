import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Loyalty points card matching the Figma "menü" frame layout.
///
/// Text content is injected from the caller (backend / localization),
/// so this widget only owns the visual structure and styling.
class CustomerPointsCard extends StatelessWidget {
  final String title;
  final String pointsText;
  final String noteText;

  const CustomerPointsCard({
    super.key,
    required this.title,
    required this.pointsText,
    required this.noteText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF77410C), // bg-[#77410c]
        borderRadius: BorderRadius.circular(16), // rounded-[16px]
      ),
      padding: const EdgeInsets.only(
        left: 24,
        top: 16,
        bottom: 24,
        right: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: text column - Using Expanded to prevent overflow
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + points stack
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Title text
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Points text
                      Text(
                        pointsText,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                ),
                const SizedBox(height: 16), // gap-[16px]
                // Note text (text-[14px], text-[#b48556])
                Text(
                  noteText,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFB48556),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8), // gap-[8px] between text and images
          // RightSection: Overlapping stars
          SizedBox(
            width: 140, 
            height: 130,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background coin (back) - Shifted significantly left and up
                Positioned(
                  right: 45,
                  top: -5,
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: Center(
                      child: Transform.rotate(
                        angle: 21.19 * math.pi / 180,
                        child: Container(
                          width: 105.766,
                          height: 103.563,
                          padding: const EdgeInsets.all(24),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFF9C06A),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 3.5,
                                color: Color(0xFF76410B),
                              ),
                              borderRadius: BorderRadius.circular(52),
                            ),
                          ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/vector2.svg',
                            width: 48,
                            height: 48,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
                // Foreground coin (front) - Positioned to stay inside
                Positioned(
                  right: -25, // Use right alignment for better containment
                  bottom: -15,
                  child: Container(
                    width: 99.766,
                    height: 97.688,
                    padding: const EdgeInsets.all(22),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF9C06A),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 3.5,
                          color: Color(0xFF76410B),
                        ),
                        borderRadius: BorderRadius.circular(49),
                      ),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/vector2.svg',
                        width: 40, // Absolute size for perfect fit
                        height: 40,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

