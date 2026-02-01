import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/icons/takeaway_cup_icon.dart';
import '../../core/providers/business_provider.dart';
import '../../core/providers/campaign_provider.dart';
import '../../core/widgets/campaign_slider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/models/campaign_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.93);
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    // Fetch data using the provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<BusinessProvider>().fetchMyFirms();
      // Fetch global data for counts
      context.read<BusinessProvider>().fetchExploreFirms();
      context.read<CampaignProvider>().fetchAllCampaigns();

      if (mounted) {
        final firms = context.read<BusinessProvider>().myFirms;
        for (var firm in firms) {
          context.read<CampaignProvider>().fetchCampaigns(firm['id']);
        }
      }
    });
  }
  
  // Helper to get firms from provider and map them
  List<Map<String, dynamic>> _getFirmBalances(BuildContext context, {bool listen = true}) {
    final provider = listen 
        ? context.watch<BusinessProvider>() 
        : context.read<BusinessProvider>();
    final data = provider.myFirms;

    if (provider.isLoading && data.isEmpty) {
      return []; // Or handle loading separately in UI
    }

    final mapped = data.map((e) => {
      'id': e['id'],
      'name': e['companyName'] ?? 'Bilinmeyen',
      'points': (e['points'] ?? 0).toString(),
      'stamps': e['stamps'] ?? 0,
      'stampsTarget': e['stampsTarget'] ?? 6,
      'giftsCount': e['giftsCount'] ?? 0,
      'value': e['value']?.toString() ?? '0.00',
      'color': _parseColor(e['cardColor']),
      'icon': _parseIcon(e['cardIcon']),
      'city': e['city'],
      'district': e['district'],
      'neighborhood': e['neighborhood'],
    }).toList();

    if (mapped.isEmpty) {
        // Need context to access provider for translation
        final lang = Provider.of<LanguageProvider>(context, listen: false);
       return [{
         'name': lang.translate('wallet_empty'),
         'points': '0',
         'value': '0.00',
         'color': Colors.grey,
         'icon': Icons.account_balance_wallet_rounded,
       }];
    }
    
    return mapped;
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

  IconData _parseCampaignIcon(String name) {
    switch (name) {
      case 'stars_rounded': return Icons.stars_rounded;
      case 'local_cafe_rounded': return Icons.local_cafe_rounded;
      case 'icecream': return Icons.icecream_rounded;
      case 'local_offer_rounded': return Icons.local_offer_rounded;
      default: return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Dynamic Colors
    final Color bgColor = theme.scaffoldBackgroundColor;
    final Color cardColor = theme.cardColor;
    final Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    const Color primaryBrand = Color(0xFFEE2C2C);
    
    // Watch providers for counts
    final campaignCount = context.watch<CampaignProvider>().allCampaigns.length;
    final businessProvider = context.watch<BusinessProvider>();
    final firmCount = businessProvider.exploreFirms.length;
    final myFirmsCount = businessProvider.myFirms.length;

    // [AUTO RE-SYNC] Force jump to 0 when first cafe is added to avoid offset mismatch
    if (myFirmsCount > 0 && _currentIndex != 0 && !_pageController.hasClients) {
       _currentIndex = 0;
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false, // Let content flow behind navbar
        child: RefreshIndicator(
          color: primaryBrand,
          onRefresh: () async {
             final biz = context.read<BusinessProvider>();
             final camp = context.read<CampaignProvider>();
             await Future.wait([
               biz.fetchMyFirms(),
               biz.fetchExploreFirms(),
               camp.fetchAllCampaigns(),
             ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Ensure it's always scrollable for refresh
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [1] CUSTOM HEADER
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: RepaintBoundary(
                    child: HomeHeader(), // Extracted const widget to prevent rebuilds
                  ),
                ),
                 
                const SizedBox(height: 24),
                 
                // [2] BALANCE / LOYALTY CARD CAROUSEL
                Consumer<BusinessProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.myFirms.isEmpty) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: primaryBrand)));
                    }
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        // Stop horizontal scroll notifications from bubbling up
                        // and potentially confusing RefreshIndicator or SingleChildScrollView
                        return true; 
                      },
                      child: _buildBalanceCarousel(context),
                    ); 
                  },
                ),

                const SizedBox(height: 20),

                // [3] EXTERNAL ACTIONS (Kafe Ekle & QR Tara - Unified Card)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer<BusinessProvider>(
                    builder: (context, provider, child) {
                      final firms = _getFirmBalances(context);
                      
                      // [SYNC FIX] If we went from 0 cafes to 1, or list changed, ensure we are synced
                      final String syncKey = firms.isEmpty ? 'empty' : '${firms.length}_${firms[0]['id']}';
                      
                      return AnimatedBuilder(
                        key: ValueKey('action_bar_$syncKey'),
                        animation: _pageController,
                        builder: (context, child) {
                          double page = 0.0;
                          if (_pageController.hasClients && _pageController.page != null) {
                            page = _pageController.page!;
                          } else {
                            page = _currentIndex.toDouble();
                          }
                          
                          int activeIndex = page.round();

                          // [FIX] Hide actions if we are on the "Add Cafe" card (extra card at the end)
                          if (activeIndex >= firms.length) {
                            return const SizedBox.shrink();
                          }

                          // [FIX] Hide actions if "Cüzdan Boş" (Empty Wallet placeholder)
                          final lang = context.read<LanguageProvider>();
                          if (firms[activeIndex]['name'] == lang.translate('wallet_empty')) {
                            return const SizedBox.shrink();
                          }

                          final currentColor = (firms.isNotEmpty && activeIndex < firms.length) 
                              ? firms[activeIndex]['color'] as Color 
                              : primaryBrand;
                              
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [currentColor, currentColor.withOpacity(0.9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: currentColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: Row(
                              children: [
                                // QR Tara (Dynamic based on visible card)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final firms = _getFirmBalances(context, listen: false);
                                      if (firms.isEmpty || firms[activeIndex]['name'] == 'Cüzdan Boş') {
                                        // Fallback to general scanner if wallet is empty
                                        context.push('/customer-scanner');
                                        return;
                                      }
                                      
                                      final firm = firms[activeIndex];
                                      await context.push('/customer-scanner', extra: {
                                        'expectedBusinessId': firm['id'],
                                        'expectedBusinessName': firm['name'],
                                        'expectedBusinessColor': firm['color'],
                                        'currentStamps': firm['stamps'] ?? 0,
                                        'targetStamps': firm['stampsTarget'] ?? 6,
                                        'currentGifts': firm['giftsCount'] ?? 0,
                                        'currentPoints': (firm['points'] ?? 0).toString(),
                                      });
                                      
                                      // Refresh data after return
                                      if (context.mounted) {
                                        context.read<BusinessProvider>().fetchMyFirms();
                                      }
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
                                        const SizedBox(height: 8),
                                        Text(
                                          Provider.of<LanguageProvider>(context).translate('scan_qr'), 
                                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Divider
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                
                                    // Fırsatlar (Deals) Button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      final firms = _getFirmBalances(context, listen: false);
                                      final lang = context.read<LanguageProvider>();
                                      if (firms.isEmpty || firms[activeIndex]['name'] == lang.translate('wallet_empty')) return;
                                      
                                      final firmId = firms[activeIndex]['id'];
                                      final firmName = firms[activeIndex]['name'];
                                      
                                      // Navigate to filtered campaigns page ("Ayrı bir sayfa olarak açsın")
                                      context.push('/business-campaigns', extra: {
                                        'firmId': firmId,
                                        'firmName': firmName,
                                      });
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.local_offer_rounded, color: Colors.white, size: 28),
                                        const SizedBox(height: 8),
                                        Text(
                                          Provider.of<LanguageProvider>(context).translate('deals'), 
                                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  ),
                ),

                const SizedBox(height: 32),

                // [4] "BENTO" GRID Area (Revised Layout)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                    Provider.of<LanguageProvider>(context).translate('explore'), 
                    style: GoogleFonts.outfit(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(height: 16),
                 
                // Row: Two Square Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 160,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildBentoCard(
                            context,
                            color: const Color(0xFF009688), // Teal (Matches Orange)
                            title: Provider.of<LanguageProvider>(context).translate('deals'),
                            subtitle: "$campaignCount ${Provider.of<LanguageProvider>(context).translate('active_campaigns')}",
                            icon: Icons.local_offer_rounded,
                            onTap: () => context.go('/campaigns'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildBentoCard(
                            context,
                            color: const Color(0xFFEE2C2C), // Red (Brand)
                            title: Provider.of<LanguageProvider>(context).translate('explore_cafes'),
                            subtitle: "$firmCount ${Provider.of<LanguageProvider>(context).translate('venues')}",
                            icon: Icons.explore_rounded,
                            onTap: () => context.push('/explore-cafes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                 
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ... (Header, Balance, QuickActions same)

  // Header, Balance, QuickActions code remains... need to ensure they are not deleted if I use replace_file correctly
  // Wait, I need to match the closing brace of build and class.
  // The replace_file_content tool works by replacing a block.
  // I should be careful. Let's just replace the Grid part.
  
  // Actually, I need to update _buildBentoCard signature to accept isHorizontal too.
  // Let's do it in two steps or a big chunk if I can match text.
  
  // Let's replace the whole Grid section in build() first.


  // Header replaced by standalone widget class below
  // Widget _buildHeader(BuildContext context) { ... } deleted

  Widget _buildBalanceCarousel(BuildContext context) {
    final firms = _getFirmBalances(context);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final cardHeight = cardWidth * (8 / 10); // 10:8 Ratio
            
            return SizedBox(
              height: cardHeight,
      child: PageView.builder(
                controller: _pageController,
                itemCount: firms.length + 1, // +1 for "Add Cafe" card
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  // Last Item: Add Cafe Card
                  if (index == firms.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: GestureDetector(
                        onTap: () async {
                          await context.push('/add-firm');
                          if (context.mounted) {
                            context.read<BusinessProvider>().fetchMyFirms();
                          }
                        },
                        child: _buildAddKafeCard(context, key: const ValueKey('add_cafe_card')),
                      ),
                    );
                  }

                  final firm = firms[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0), // Gap between cards
                    child: GestureDetector(
                      onTap: () async {
                        // Don't navigate if it's the "Empty Wallet" placeholder
                        final lang = context.read<LanguageProvider>();
                        if (firm['name'] == lang.translate('wallet_empty')) return;
                        
                        await context.push('/business-detail', extra: {
                          'id': firm['id'],
                          'name': firm['name'],
                          'points': firm['points'],
                          'stamps': firm['stamps'],
                          'stampsTarget': firm['stampsTarget'],
                          'giftsCount': firm['giftsCount'],
                          'value': firm['value'],
                          'color': firm['color'],
                          'icon': firm['icon'], 
                          'city': firm['city'],
                          'district': firm['district'],
                          'neighborhood': firm['neighborhood'],
                        });

                        // [SYNC FIX] Refresh data when returning from detail
                        if (context.mounted) {
                          context.read<BusinessProvider>().fetchMyFirms();
                        }
                      },
                      child: _buildSingleBusinessCard(
                        context,
                        key: ValueKey('firm_card_${firm['id']}'),
                        name: firm['name'],
                        points: firm['points'],
                        value: firm['value'],
                        color: firm['color'],
                        icon: firm['icon'],
                        stamps: firm['stamps'] ?? 0,
                        stampsTarget: firm['stampsTarget'] ?? 6,
                        giftsCount: firm['giftsCount'] ?? 0,
                        firmId: firm['id'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddKafeCard(BuildContext context, {Key? key}) {
    final lang = Provider.of<LanguageProvider>(context);
    return Container(
      key: key,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFEE2C2C), // Updated to Red
      ),
      child: Stack(
        children: [
          // Background Icon
          Positioned(
            right: -40,
            bottom: -40,
            child: Opacity(
              opacity: 0.1,
              child: const Icon(
                Icons.add_circle_outline_rounded,
                size: 200,
                color: Colors.white,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white, // White circle
                  ),
                  child: const Icon(Icons.add_rounded, color: Color(0xFFEE2C2C), size: 40), // Red Icon
                ),
                const SizedBox(height: 16),
                Text(
                  lang.translate('new_cafe_add'),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lang.translate('scan_or_enter_code'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBusinessCard(
    BuildContext context, {
    required String name,
    required String points,
    required String value,
    required Color color,
    required IconData icon,
    required int stamps,
    required int stampsTarget,
    required int giftsCount,
    required String? firmId,
    Key? key,
  }) {
    // Credit Card Design
    return Container(
      key: key,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.9), color], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.2, 0.9],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Texture: Category Background Icon
           Positioned(
            right: -60,
            bottom: -60,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                icon,
                size: 200,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0), // Symmetrical padding (Top/Bottom/Left/Right equal)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pushes Name to Top, Box to Bottom
              children: [
                // [TOP] Firm Name
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                
                // [MIDDLE] Stamps & Points Section
                SizedBox(
                  height: 130, // Fixed height to lock Top and Bottom alignment
                  width: double.infinity,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Top-locked
                    children: [
                      // Left Side: Text + Progress Bar + Puanlarım
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // [TOP ANCHOR] Puanlarım Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  // Localize "Puanlarım"
                                  Provider.of<LanguageProvider>(context).translate('my_points'),
                                  style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                                    const SizedBox(width: 8),
                                    Text(
                                      points,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w600,
                                        height: 1.0,
                                      ),
                                      textHeightBehavior: const TextHeightBehavior(
                                        applyHeightToFirstAscent: false,
                                        applyHeightToLastDescent: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            const Spacer(), // Pushes everything below to the very bottom of the 130px height

                            // [BOTTOM ANCHOR] Pul row + Progress Bar
                            Column(
                              children: [
                                // Header Row: Pul
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        // Localize "Pul"
                                        Provider.of<LanguageProvider>(context).translate('stamps'),
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "$stamps",
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          height: 1.0,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 3, left: 2),
                                        child: Text(
                                          "/$stampsTarget",
                                          style: GoogleFonts.outfit(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Progress Bar
                                Container(
                                  height: 24,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: (stamps / stampsTarget).clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Right Side: Cup Icon (Top aligned with Puanlarım, Bottom aligned with Bar)
                      Transform.translate(
                        offset: const Offset(8, 4), // Shifted down for actual text alignment
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TakeawayCupIcon(
                              color: Colors.white.withOpacity(0.35),
                              size: 130, // Matches container height exactly
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 18), 
                              child: Text(
                                "$giftsCount",
                                style: GoogleFonts.outfit(
                                  color: Colors.white, 
                                  fontSize: 48, // Restored to previous large size
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // [BOTTOM] Campaign Box (Dynamic Slider)
                Consumer<CampaignProvider>(
                  builder: (context, campProvider, child) {
                    final allCampaigns = (firmId != null) ? campProvider.getCampaignsForBusiness(firmId) : <CampaignModel>[];
                    final promotedCampaigns = allCampaigns.where((c) => c.isPromoted).toList();
                    
                    if (promotedCampaigns.isEmpty) {
                      return const SizedBox.shrink(); // Hide if no promoted campaigns
                    }

                    return CampaignSlider(campaigns: promotedCampaigns);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  



  Widget _buildActionItem(BuildContext context, IconData icon, String label, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cardColor, // Lighter dark
              shape: BoxShape.circle,
              border: Border.all(color: textColor.withOpacity(0.05)),
            ),
            child: Icon(icon, color: textColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBentoCard(BuildContext context, { 
    required Color color, 
    required String title, 
    required String subtitle, 
    required IconData icon, 
    bool isHorizontal = false,
    bool isSmall = false,
    VoidCallback? onTap,
  }) {
    // Premium Design: Gradient + Background Icon + Shadow
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(24),
           gradient: LinearGradient(
             colors: [color, color.withOpacity(0.8)],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
           ),
           boxShadow: [
             BoxShadow(
               color: color.withOpacity(0.35),
               blurRadius: 15,
               offset: const Offset(0, 8),
             )
           ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background Giant Icon
              Positioned(
                right: -20,
                bottom: -20,
                child: Transform.rotate(
                  angle: -0.2, // Slight tilt
                  child: Icon(
                    icon,
                    size: 100,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: isHorizontal 
                  ? Row( // HORIZONTAL LAYOUT
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              subtitle, 
                              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title, 
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                        // Icon Circle
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: Icon(icon, color: Colors.white, size: 28),
                        ),
                      ],
                    )
                  : Column( // VERTICAL LAYOUT
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Icon Circle
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2), // Frosted glass effect
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
    );
  }


  void _showDealsModal(BuildContext context, String firmId, String firmName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<dynamic>>(
              future: context.read<ApiService>().getCampaignsByBusiness(firmId),
              builder: (context, snapshot) {
                final campaigns = snapshot.data ?? [];
                
                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer_rounded, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$firmName Fırsatları',
                              style: GoogleFonts.outfit(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (snapshot.hasError)
                      Padding(
                         padding: const EdgeInsets.all(32),
                         child: Center(child: Text('Hata oluştu: ${snapshot.error}')),
                       )
                    else if (campaigns.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.campaign_outlined, size: 48, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz aktif kampanya yok.',
                              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: campaigns.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final campaign = campaigns[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      campaign['rewardType'] == 'stamp' ? Icons.coffee_rounded : Icons.star_rounded,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          campaign['title'] ?? '',
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          campaign['shortDescription'] ?? '',
                                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    const primaryBrand = Color(0xFFEE2C2C);
    
    // User Data from Provider
    // Watched here, so only this widget rebuilds on user change, NOT on parent setState
    final user = context.watch<AuthProvider>().currentUser;
    final name = user?.fullName ?? "Misafir";
    
    // Dynamic Greeting Logic
    final hour = DateTime.now().hour;
    final lang = context.watch<LanguageProvider>(); // Watch language for refresh
    String greetingKey;
    if (hour >= 6 && hour < 12) {
      greetingKey = 'good_morning';
    } else if (hour >= 12 && hour < 18) {
      greetingKey = 'good_afternoon';
    } else if (hour >= 18 && hour < 22) {
      greetingKey = 'good_evening';
    } else {
      greetingKey = 'good_night';
    }
    final greeting = lang.translate(greetingKey);

    // Prepare Profile Image
    ImageProvider? imageProvider;
    if (user?.profileImage != null) {
      try {
        imageProvider = MemoryImage(base64Decode(user!.profileImage!));
      } catch (e) {
        imageProvider = const AssetImage('assets/images/default_profile.png');
      }
    } else {
      imageProvider = const AssetImage('assets/images/default_profile.png');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14)),
              Text(name, 
                style: GoogleFonts.outfit(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/settings'),
          child: Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryBrand, width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: cardColor,
              backgroundImage: imageProvider,
            ),
          ),
        )
      ],
    );
  }
}
