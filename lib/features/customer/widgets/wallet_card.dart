
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_utils.dart';


class WalletCard extends StatelessWidget {
  final Map<String, dynamic> firm;
  final VoidCallback? onScanTap;
  final VoidCallback? onSpendTap;

  const WalletCard({
    super.key,
    required this.firm,
    this.onScanTap,
    this.onSpendTap,
  });

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();

    final int stampCount = firm['stamps'] ?? 0;
    final int target = firm['stampsTarget'] ?? 8;
    final String points = firm['points']?.toString() ?? '0';
    final String firmName = firm['name'] ?? 'KAFE';
    final int giftsCount = firm['giftsCount'] ?? 0;
    final double reviewScore = (firm['reviewScore'] ?? 0.0).toDouble();
    final int reviewCount = firm['reviewCount'] ?? 0;

    final double fillProgress = (target > 0) ? (stampCount / target).clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground, // #FFFDF7
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor, width: 0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TOP SECTION: Cup (left) + Stats (right)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Coffee Cup + Gift Text
                        GestureDetector(
                          onTap: () => context.push('/business-detail', extra: firm),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: 110,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Coffee cup: empty PNG + fill overlay
                                SizedBox(
                                  height: 120,
                                  width: 90,
                                  child: Stack(
                                    children: [
                                      // Empty cup image (bottom layer)
                                      Positioned.fill(
                                        child: Image.asset(
                                          'assets/images/coffee_cup_empty.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      // Coffee fill: uses cup PNG as shape mask
                                      if (fillProgress > 0)
                                        Positioned.fill(
                                          child: ClipRect(
                                            clipper: _CoffeeLevelClipper(fillProgress),
                                            child: ShaderMask(
                                              shaderCallback: (bounds) => const LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [Color(0xFF4A2810), Color(0xFF6B3A14)],
                                              ).createShader(bounds),
                                              blendMode: BlendMode.srcIn,
                                              child: Image.asset(
                                                'assets/images/coffee_cup_empty.png',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$giftsCount ${langProvider.translate('hediye_icecek')}',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.bodyText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right: Stats (Firm Tag moved to Positioned)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/business-detail', extra: firm),
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 64), // Space moved down from _buildFirmTag to align badhes with coffee text
                                // Stats: Damga + Puan
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildDamgaCircle(stampCount, target, langProvider),
                                    _buildPuanCircle(points, langProvider),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

              const SizedBox(height: 10),

              // BOTTOM: Action Buttons (Figma: 51px h)
              SizedBox(
                height: 51,
                child: Row(
                  children: [
                    // QR Okut (gradient)
                    Expanded(
                      child: GestureDetector(
                        onTap: onScanTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF5BE6B), Color(0xFFFD9400)],
                              stops: [0.2137, 0.8665],
                            ),
                            borderRadius: BorderRadius.circular(44),
                            boxShadow: const [
                              BoxShadow(color: Color(0x407F7F7F), blurRadius: 4, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -2),
                                child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFFFBFBFB), size: 39),
                              ),
                              const SizedBox(width: 4),
                               Flexible(
                                 child: FittedBox(
                                   fit: BoxFit.scaleDown,
                                   child: Text(
                                     langProvider.translate('qr_okut'),
                                     style: GoogleFonts.outfit(
                                       color: const Color(0xFFFBFBFB),
                                       fontWeight: FontWeight.w600,
                                       fontSize: 16,
                                     ),
                                   ),
                                 ),
                               ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: onSpendTap,
                        child: Container(
                          height: 51,
                          padding: const EdgeInsets.all(10),
                          decoration: ShapeDecoration(
                            color: const Color(0x7AFACF93), // Exact match #FACF937A
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 1,
                                color: Color(0xFFF99D13), // Exact match #F99D13
                              ),
                              borderRadius: BorderRadius.circular(44),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x3F7F7F7F),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                                spreadRadius: 0,
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 31,
                                height: 31,
                                padding: const EdgeInsets.all(5.42),
                                clipBehavior: Clip.antiAlias,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(23.83),
                                  ),
                                  shadows: const [
                                    BoxShadow(
                                      color: Color(0x7AFACF93),
                                      blurRadius: 2.17,
                                      offset: Offset(0, 2.17),
                                      spreadRadius: 0,
                                    )
                                  ],
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/vector.svg',
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFFF99D13), 
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    langProvider.translate('puan_harca'),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFF99D13),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.65),
                child: _buildFirmTag(context, firmName, reviewScore, reviewCount, langProvider),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Firm header tag
  Widget _buildFirmTag(BuildContext context, String name, double score, int count, LanguageProvider langProvider) {
    // --- Build firm logo from backend ---
    Widget logoWidget;
    final rawLogo = firm['logo'] ?? firm['image'] ?? firm['logoUrl'];
    final String? resolved = (rawLogo != null && rawLogo.toString().isNotEmpty)
        ? resolveImageUrl(rawLogo.toString())
        : null;

    if (resolved != null) {
      logoWidget = ClipOval(
        child: Image.network(resolved, width: 24, height: 24, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.store_rounded, color: AppTheme.deepBrown, size: 20)),
      );
    } else {
      logoWidget = const Icon(Icons.store_rounded, color: AppTheme.deepBrown, size: 18);
    }

    return GestureDetector(
      onTap: () => context.push('/business-detail', extra: firm),
      child: AspectRatio(
        aspectRatio: 219 / 78,
        child: Stack(
          children: [
            // SVG background shape
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/images/firm_tag_bg.svg',
                fit: BoxFit.fill,
              ),
            ),
            // Content overlay
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(left: 28, right: 12, top: 8, bottom: 8),
                child: Row(
                  children: [
                    logoWidget,
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              name,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                height: 1.1,
                                color: const Color(0xFF131313),
                              ),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFF7C35F), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  score.toStringAsFixed(1).replaceAll('.', ','),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4A4A4A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "($count ${langProvider.translate('reviews_count')})",
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF4A4A4A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Navigation Arrow (visual only, whole tag is tappable)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7C35F),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x20000000), blurRadius: 2, offset: Offset(0, 1)),
                        ],
                      ),
                      child: const Icon(Icons.chevron_right_rounded, color: Colors.black, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Damga stat circle with progress indicator
  Widget _buildDamgaCircle(int stamps, int target, LanguageProvider langProvider) {
    final double progress = (target > 0) ? (stamps / target).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            children: [
              // Outer progress arc
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: const Color(0xCEFFE7C0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF9C06A)),
                ),
              ),
              // Inner content
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xCEFFE7C0),
                  ),
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        text: '$stamps',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF6A623), // Matching photo orange
                        ),
                        children: [
                          TextSpan(
                            text: '/$target',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF131313),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.coffee_rounded, color: AppTheme.puanHarcaText, size: 13),
            const SizedBox(width: 3),
            Text(
              langProvider.translate('stamp_label'),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.bodyText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Puan stat circle
  Widget _buildPuanCircle(String points, LanguageProvider langProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFCD82),
            border: Border.all(color: const Color(0xFFFFAE34), width: 1.0),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  points,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF8F00),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppTheme.puanHarcaText, size: 13),
            const SizedBox(width: 3),
            Text(
              langProvider.translate('point_label'),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.bodyText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}



class _CoffeeLevelClipper extends CustomClipper<Rect> {
  final double fillProgress;
  _CoffeeLevelClipper(this.fillProgress);

  @override
  Rect getClip(Size size) {
    // Cup body: lid bottom ~24%, cup bottom ~97%
    final bodyTop = size.height * 0.24;
    final bodyBottom = size.height * 0.97;
    final bodyHeight = bodyBottom - bodyTop;

    // Coffee rises from bottom
    final coffeeTop = bodyBottom - (bodyHeight * fillProgress.clamp(0.0, 1.0));
    return Rect.fromLTRB(0, coffeeTop, size.width, size.height);
  }

  @override
  bool shouldReclip(_CoffeeLevelClipper oldClipper) =>
      oldClipper.fillProgress != fillProgress;
}
