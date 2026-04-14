import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/smart_network_image.dart';
import '../../core/widgets/swipe_back_detector.dart';
import '../../core/widgets/auto_text.dart';

class MenuItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  final String businessName;
  final String? businessLogo;

  const MenuItemDetailScreen({
    super.key,
    required this.product,
    required this.businessName,
    this.businessLogo,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFEBEBEB);
    final Color textColor = isDark ? Colors.white : const Color(0xFF131313);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    const Color accentColor = Color(0xFFF9C06A);
    const Color deepBrown = Color(0xFF76410B);

    final price = (product['price'] as num?) ?? 0;
    final discount = (product['discount'] as num?) ?? 0;
    final effectivePrice = price - discount;
    final imageUrl = resolveImageUrl(product['imageUrl']);
    final name = product['name'] ?? '';
    final description = product['description'] ?? '';
    final rawCategory = product['category'] ?? '';
    final catKey = 'cat_${rawCategory.toLowerCase().replaceAll(' ', '_')}';
    final catTranslated = lang.translate(catKey);
    final category = catTranslated != catKey ? catTranslated : rawCategory;

    return SwipeBackDetector(
      child: Scaffold(
        backgroundColor: bgColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar with product image
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              stretch: true,
              backgroundColor: bgColor,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                ),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl != null
                        ? SmartNetworkImage(url: imageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: accentColor.withValues(alpha: 0.3)))
                        : Container(
                            color: accentColor.withValues(alpha: 0.3),
                            child: Icon(Icons.fastfood_rounded, size: 80, color: deepBrown.withValues(alpha: 0.3)),
                          ),
                    // Bottom gradient
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Price badge
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (discount > 0) ...[
                              tlText(
                                '${price.toInt()}',
                                GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: deepBrown.withValues(alpha: 0.6),
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.w500,
                                ),
                                suffix: true,
                              ),
                              const SizedBox(width: 6),
                            ],
                            tlText(
                              '${effectivePrice.toInt()}',
                              GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: deepBrown,
                              ),
                              suffix: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Container(
                color: bgColor,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business name badge
                    if (businessLogo != null || businessName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (businessLogo != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SmartNetworkImage(
                                  url: resolveImageUrl(businessLogo) ?? '',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(width: 20, height: 20),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              businessName,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Product name
                    AutoText(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Category chip
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: deepBrown,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Description card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: accentColor),
                              const SizedBox(width: 6),
                              Text(
                                lang.translate('product_description_title'),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          AutoText(
                            description.isNotEmpty
                                ? description
                                : lang.translate('no_product_description'),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: textColor.withValues(alpha: 0.7),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Price details card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.translate('price_label'),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor.withValues(alpha: 0.6),
                                ),
                              ),
                              tlText(
                                '${price.toInt()}',
                                GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: discount > 0 ? textColor.withValues(alpha: 0.4) : textColor,
                                  decoration: discount > 0 ? TextDecoration.lineThrough : null,
                                ),
                                suffix: true,
                              ),
                            ],
                          ),
                          if (discount > 0) ...[
                            const SizedBox(height: 10),
                            Container(height: 1, color: textColor.withValues(alpha: 0.06)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_offer_rounded, size: 14, color: accentColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      lang.translate('discount_label'),
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: deepBrown,
                                      ),
                                    ),
                                  ],
                                ),
                                tlText(
                                  '-${discount.toInt()}',
                                  GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                  suffix: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(height: 1, color: textColor.withValues(alpha: 0.06)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang.translate('final_price_label'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                tlText(
                                  '${effectivePrice.toInt()}',
                                  GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: deepBrown,
                                  ),
                                  suffix: true,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
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
}
