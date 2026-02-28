import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/business_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/language_provider.dart';
import '../../core/widgets/auto_text.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/theme/app_theme.dart';

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
      context.read<BusinessProvider>().fetchExploreFirms();
    });
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFEE2C2C);
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFEE2C2C);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    const Color primaryBrand = Color(0xFFEE2C2C);
    
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          lang.translate('explore_cafes'),
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Consumer<BusinessProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.exploreFirms.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: primaryBrand));
          }

          if (provider.exploreFirms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 80, color: textColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    lang.translate('no_cafes_yet'),
                    style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.5), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Filter out firms that are already in wallet
          final filteredFirms = provider.exploreFirms.where((firm) {
            final id = firm['_id'] ?? firm['id'];
            return !provider.isFirmInWallet(id);
          }).toList();

          // Sort Alphabetically
          final sortedFirms = List.from(filteredFirms)
            ..sort((a, b) => (a['companyName'] ?? '').toLowerCase().compareTo((b['companyName'] ?? '').toLowerCase()));
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Newest Slider (SliverToBoxAdapter)
              SliverToBoxAdapter(
                child: FutureBuilder<List<dynamic>>(
                  future: context.read<ApiService>().getNewestBusinesses(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                    final newest = snapshot.data!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Text(
                            lang.translate('newly_added'),
                            style: GoogleFonts.outfit(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: newest.length,
                            itemBuilder: (context, index) {
                               final firm = newest[index];
                               return _buildNewestCard(context, firm);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "${lang.translate('all_businesses')} (${sortedFirms.length})",
                            style: GoogleFonts.outfit(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ),

              // 2. All Firms List (SliverList)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final business = sortedFirms[index];
                      final color = _parseColor(business['cardColor']);
                      final icon = _parseIcon(business['cardIcon']);

                      return _buildExploreCard(
                        context,
                        business: business,
                        color: color,
                        icon: icon,
                        textColor: textColor,
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
    );
  }

  Widget _buildExploreCard(
    BuildContext context, {
    required dynamic business,
    required Color color,
    required IconData icon,
    required Color textColor,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final lang = context.read<LanguageProvider>();
 

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      // ... existing card styling
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: textColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final provider = context.read<BusinessProvider>();
            final id = business['_id'] ?? business['id'];
            
            // Check if already in wallet to pass real customer data
            final isInWallet = provider.isFirmInWallet(id);
            dynamic walletData;
            if (isInWallet) {
               walletData = provider.myFirms.firstWhere((f) => (f['_id'] ?? f['id']) == id);
            }

            final detailData = {
              'id': id,
              'name': business['companyName'],
              'points': isInWallet ? (walletData['points'] ?? '0') : '0',
              'stamps': isInWallet ? (walletData['stamps'] ?? 0) : 0,
              'stampsTarget': isInWallet ? (walletData['stampsTarget'] ?? 6) : (business['stampsTarget'] ?? 6),
              'giftsCount': isInWallet ? (walletData['giftsCount'] ?? 0) : 0,
              'value': isInWallet ? (walletData['value'] ?? '0.00') : '0.00',
              'reviewScore': business['rating'] ?? business['reviewScore'] ?? 0.0,
              'reviewCount': business['reviewCount'] ?? 0,
              'color': color,
              'icon': icon,
              'city': business['city'],
              'district': business['district'],
              'neighborhood': business['neighborhood'],
              'logo': business['logo'], // Pass logo
              'image': business['image'], // Pass fallback image
              'isNew': !isInWallet, 
            };
            
            context.push('/business-detail', extra: detailData);
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Brand Logo Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: resolveImageUrl(business['logo'] ?? business['image']) != null
                      ? Image.network(
                          resolveImageUrl(business['logo'] ?? business['image'])!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: AppTheme.deepBrown, size: 30),
                        )
                      : const Icon(Icons.storefront_rounded, color: AppTheme.deepBrown, size: 30),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business['companyName'] ?? lang.translate('unknown_business'),
                        style: GoogleFonts.outfit(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAddress(business),
                        style: GoogleFonts.outfit(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Add Icon / Button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded, color: color, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewestCard(BuildContext context, dynamic firm) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final lang = context.read<LanguageProvider>();
    
    final color = _parseColor(firm['cardColor']);
    final icon = _parseIcon(firm['cardIcon']);
    
    // Check if in wallet
    final provider = context.read<BusinessProvider>();
    final id = firm['_id'] ?? firm['id'];
    final isInWallet = provider.isFirmInWallet(id);
    
    dynamic walletData;
    if (isInWallet) {
       walletData = provider.myFirms.firstWhere((f) => (f['_id'] ?? f['id']) == id);
    }
    
    // Only show 'isNew' if NOT in wallet
    final isNew = !isInWallet;
    
    return GestureDetector(
      onTap: () {
         final detailData = {
            'id': id,
            'name': firm['companyName'],
            'points': isInWallet ? (walletData['points'] ?? '0') : '0',
            'stamps': isInWallet ? (walletData['stamps'] ?? 0) : 0,
            'stampsTarget': isInWallet ? (walletData['stampsTarget'] ?? 6) : (firm['stampsTarget'] ?? 6), 
            'giftsCount': isInWallet ? (walletData['giftsCount'] ?? 0) : 0,
            'value': isInWallet ? (walletData['value'] ?? '0.00') : '0.00',
            'reviewScore': firm['rating'] ?? firm['reviewScore'] ?? 0.0,
            'reviewCount': firm['reviewCount'] ?? 0,
            'color': color,
            'icon': icon,
            'city': firm['city'],
            'district': firm['district'],
            'neighborhood': firm['neighborhood'],
            'isNew': isNew, 
         };
         context.push('/business-detail', extra: detailData);
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textColor.withValues(alpha: 0.05)),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3)
            )
          ]
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Circle Brand Logo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: resolveImageUrl(firm['logo'] ?? firm['image']) != null
                    ? Image.network(
                        resolveImageUrl(firm['logo'] ?? firm['image'])!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: AppTheme.deepBrown, size: 20),
                      )
                    : const Icon(Icons.storefront_rounded, color: AppTheme.deepBrown, size: 20),
            ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firm['companyName'] ?? '',
                    style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  AutoText(
                    firm['category'] ?? lang.translate('general'),
                    style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.5), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
