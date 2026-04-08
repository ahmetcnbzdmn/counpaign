import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/business_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/guest_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/language_provider.dart';
import '../../core/widgets/auto_text.dart';
import '../../core/utils/ui_utils.dart';

class ExploreCafesScreen extends StatefulWidget {
  const ExploreCafesScreen({super.key});

  @override
  State<ExploreCafesScreen> createState() => _ExploreCafesScreenState();
}

class _ExploreCafesScreenState extends State<ExploreCafesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.read<AuthProvider>().isAuthenticated) return;
      context.read<BusinessProvider>().fetchExploreFirms();
    });
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFF9C06A);
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFF9C06A);
    }
  }

  IconData _parseIcon(String? name) {
    switch (name) {
      case 'coffee_rounded': return Icons.coffee_rounded;
      case 'lunch_dining_rounded': return Icons.lunch_dining_rounded;
      case 'checkroom_rounded': return Icons.checkroom_rounded;
      case 'restaurant_rounded': return Icons.restaurant_rounded;
      case 'local_bar_rounded': return Icons.local_bar_rounded;
      case 'shopping_bag_rounded': return Icons.shopping_bag_rounded;
      case 'fitness_center_rounded': return Icons.fitness_center_rounded;
      case 'content_cut_rounded': return Icons.content_cut_rounded;
      default: return Icons.local_cafe_rounded;
    }
  }

  String _translateCategory(String category, LanguageProvider lang) {
    final key = 'cat_${category.toLowerCase()}';
    final translated = lang.translate(key);
    return translated == key ? category : translated;
  }

  String _formatAddress(dynamic business) {
    final city = business['city'] ?? '';
    final district = business['district'] ?? '';
    final neighborhood = business['neighborhood'] ?? '';

    final List<String> parts = [];
    if (neighborhood.isNotEmpty) parts.add(neighborhood);
    if (district.isNotEmpty) parts.add(district);
    if (city.isNotEmpty) parts.add(city);

    if (parts.isEmpty) {
      return context.read<LanguageProvider>().translate('no_address');
    }

    return parts.join(', ');
  }

  /// Builds a logo container where the image fills the background (blurred)
  /// and a sharper centered version sits on top.
  Widget _buildLogoBox({
    required String? imageUrl,
    required IconData fallbackIcon,
    required double size,
    double borderRadius = 18,
  }) {
    final resolvedUrl = resolveImageUrl(imageUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF9C06A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: resolvedUrl.isNotEmpty
          ? Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: const Color(0xFF76410B), size: size * 0.45),
            )
          : Icon(fallbackIcon, color: const Color(0xFF76410B), size: size * 0.45),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFEBEBEB);
    const textColor = Color(0xFF131313);
    const cardColor = Colors.white;
    const yellow = Color(0xFFF9C06A);
    const deepBrown = Color(0xFF76410B);

    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── Fixed Header ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Back button - left
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: textColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                // Title + subtitle - centered
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang.translate('explore_cafes'),
                      style: GoogleFonts.outfit(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: yellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lang.translate('discover_new_places'),
                          style: GoogleFonts.outfit(
                            color: textColor.withValues(alpha: 0.38),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Scrollable Content ────────────────────────────────────
          Expanded(
            child: Consumer<BusinessProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.exploreFirms.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: yellow,
                      strokeWidth: 3,
                    ),
                  );
                }

                if (provider.exploreFirms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: yellow.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_off_rounded, size: 48, color: yellow),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          lang.translate('no_cafes_yet'),
                          style: GoogleFonts.outfit(
                            color: textColor.withValues(alpha: 0.45),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final filteredFirms = provider.exploreFirms.where((firm) {
                  final id = firm['_id'] ?? firm['id'];
                  return !provider.isFirmInWallet(id);
                }).toList();

                final sortedFirms = List.from(filteredFirms)
                  ..sort((a, b) => (a['companyName'] ?? '').toLowerCase().compareTo((b['companyName'] ?? '').toLowerCase()));

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Newest Slider ─────────────────────────────
                    SliverToBoxAdapter(
                      child: FutureBuilder<List<dynamic>>(
                        future: context.read<AuthProvider>().isAuthenticated
                            ? context.read<ApiService>().getNewestBusinesses()
                            : Future.value([]),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                          final newest = snapshot.data!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: yellow,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      lang.translate('newly_added'),
                                      style: GoogleFonts.outfit(
                                        color: textColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(38, 2, 24, 16),
                                child: Text(
                                  lang.translate('newly_added_subtitle'),
                                  style: GoogleFonts.outfit(
                                    color: textColor.withValues(alpha: 0.38),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 155,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: newest.length,
                                  itemBuilder: (context, index) => _buildNewestCard(
                                    context,
                                    newest[index],
                                    textColor: textColor,
                                    yellow: yellow,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: yellow,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      lang.translate('all_businesses'),
                                      style: GoogleFonts.outfit(
                                        color: textColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: yellow.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${sortedFirms.length}',
                                        style: GoogleFonts.outfit(
                                          color: deepBrown,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          );
                        },
                      ),
                    ),

                    // ── All Firms List ────────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final business = sortedFirms[index];
                            final icon = _parseIcon(business['cardIcon']);
                            return _buildExploreCard(
                              context,
                              business: business,
                              icon: icon,
                              textColor: textColor,
                              cardColor: cardColor,
                              yellow: yellow,
                              deepBrown: deepBrown,
                            );
                          },
                          childCount: sortedFirms.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard(
    BuildContext context, {
    required dynamic business,
    required IconData icon,
    required Color textColor,
    required Color cardColor,
    required Color yellow,
    required Color deepBrown,
  }) {
    final lang = context.read<LanguageProvider>();
    final rating = parseRating(business['rating'] ?? business['reviewScore'] ?? business['avgRating'] ?? business['averageRating']);
    final reviewCount = parseReviewCount(business['reviewCount'] ?? business['ratingCount'] ?? business['reviewsCount']);
    final rawCategory = business['category'] ?? '';
    final category = rawCategory.isNotEmpty ? _translateCategory(rawCategory, lang) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: yellow, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: yellow.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final provider = context.read<BusinessProvider>();
            final guestProvider = context.read<GuestProvider>();
            final id = business['_id'] ?? business['id'];
            
            bool isInWallet = provider.isFirmInWallet(id);
            if (!isInWallet && guestProvider.isGuest) {
              isInWallet = guestProvider.wallet.any((f) => (f['_id'] ?? f['id']) == id);
            }

            dynamic walletData;
            if (isInWallet) {
              if (provider.isFirmInWallet(id)) {
                walletData = provider.myFirms.firstWhere((f) => (f['_id'] ?? f['id']) == id);
              } else if (guestProvider.isGuest) {
                walletData = guestProvider.wallet.firstWhere((f) => (f['_id'] ?? f['id']) == id);
              }
            }

            context.push('/business-detail', extra: {
              'id': id,
              'name': business['companyName'],
              'points': isInWallet ? (walletData['points'] ?? '0') : '0',
              'stamps': isInWallet ? (walletData['stamps'] ?? 0) : 0,
              'stampsTarget': isInWallet ? (walletData['stampsTarget'] ?? 6) : (business['stampsTarget'] ?? 6),
              'giftsCount': isInWallet ? (walletData['giftsCount'] ?? 0) : 0,
              'value': isInWallet ? (walletData['value'] ?? '0.00') : '0.00',
              'reviewScore': rating,
              'reviewCount': reviewCount,
              'color': _parseColor(business['cardColor']),
              'icon': icon,
              'city': business['city'],
              'district': business['district'],
              'neighborhood': business['neighborhood'],
              'logo': business['logo'],
              'image': business['image'],
              'isNew': !isInWallet,
            });
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Logo with blur-bg effect
                _buildLogoBox(
                  imageUrl: business['logo'] ?? business['image'],
                  fallbackIcon: icon,
                  size: 66,
                  borderRadius: 18,
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business['companyName'] ?? lang.translate('unknown_business'),
                        style: GoogleFonts.outfit(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (category.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: yellow.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: AutoText(
                                category,
                                style: GoogleFonts.outfit(
                                  color: deepBrown,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (rating > 0) ...[
                            const Icon(Icons.star_rounded, size: 13, color: Color(0xFFE68A00)),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                color: textColor.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (reviewCount > 0)
                              Text(
                                ' ($reviewCount)',
                                style: GoogleFonts.outfit(
                                  color: textColor.withValues(alpha: 0.35),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 12, color: textColor.withValues(alpha: 0.3)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              _formatAddress(business),
                              style: GoogleFonts.outfit(
                                color: textColor.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Arrow button
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: yellow,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: yellow.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewestCard(
    BuildContext context,
    dynamic firm, {
    required Color textColor,
    required Color yellow,
  }) {
    final lang = context.read<LanguageProvider>();
    final icon = _parseIcon(firm['cardIcon']);

    final provider = context.read<BusinessProvider>();
    final guestProvider = context.read<GuestProvider>();
    final id = firm['_id'] ?? firm['id'];
    
    bool isInWallet = provider.isFirmInWallet(id);
    if (!isInWallet && guestProvider.isGuest) {
      isInWallet = guestProvider.wallet.any((f) => (f['_id'] ?? f['id']) == id);
    }

    dynamic walletData;
    if (isInWallet) {
      if (provider.isFirmInWallet(id)) {
        walletData = provider.myFirms.firstWhere((f) => (f['_id'] ?? f['id']) == id);
      } else if (guestProvider.isGuest) {
        walletData = guestProvider.wallet.firstWhere((f) => (f['_id'] ?? f['id']) == id);
      }
    }

    final isNew = !isInWallet;

    return GestureDetector(
      onTap: () {
        context.push('/business-detail', extra: {
          'id': id,
          'name': firm['companyName'],
          'points': isInWallet ? (walletData['points'] ?? '0') : '0',
          'stamps': isInWallet ? (walletData['stamps'] ?? 0) : 0,
          'stampsTarget': isInWallet ? (walletData['stampsTarget'] ?? 6) : (firm['stampsTarget'] ?? 6),
          'giftsCount': isInWallet ? (walletData['giftsCount'] ?? 0) : 0,
          'value': isInWallet ? (walletData['value'] ?? '0.00') : '0.00',
          'reviewScore': parseRating(firm['rating'] ?? firm['reviewScore'] ?? firm['avgRating'] ?? firm['averageRating']),
          'reviewCount': parseReviewCount(firm['reviewCount'] ?? firm['ratingCount'] ?? firm['reviewsCount']),
          'color': _parseColor(firm['cardColor']),
          'icon': icon,
          'city': firm['city'],
          'district': firm['district'],
          'neighborhood': firm['neighborhood'],
          'logo': firm['logo'],
          'image': firm['image'],
          'isNew': isNew,
        });
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: yellow, width: 2),
          boxShadow: [
            BoxShadow(
              color: yellow.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo with blur-bg
                  _buildLogoBox(
                    imageUrl: firm['logo'] ?? firm['image'],
                    fallbackIcon: icon,
                    size: 56,
                    borderRadius: 14,
                  ),
                  const Spacer(),
                  Text(
                    firm['companyName'] ?? '',
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  AutoText(
                    firm['category'] != null && (firm['category'] as String).isNotEmpty
                        ? _translateCategory(firm['category'] as String, lang)
                        : lang.translate('general'),
                    style: GoogleFonts.outfit(
                      color: textColor.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // "YENİ" badge
            if (isNew)
              Positioned(
                top: 13,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: yellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lang.translate('new_badge'),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
