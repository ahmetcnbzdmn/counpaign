import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/icons/takeaway_cup_icon.dart';
import '../../core/providers/business_provider.dart';
import '../../core/providers/campaign_provider.dart';
import '../../core/providers/language_provider.dart';


import '../../features/customer/widgets/wallet_card.dart';

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
      if (!mounted) return;
      final bp = context.read<BusinessProvider>();
      final cp = context.read<CampaignProvider>();
      final api = context.read<ApiService>();

      await bp.fetchMyFirms();
      // Fetch global data for counts
      bp.fetchExploreFirms();
      cp.fetchAllCampaigns();

      if (mounted) {
        final firms = bp.myFirms;
        for (var firm in firms) {
          cp.fetchCampaigns(firm['id']);
        }
        // Fetch reviews to check for pending ones
        api.getReviews();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      'logo': e['logo'],
      'image': e['image'],
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
          const Positioned(
            right: -40,
            bottom: -40,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
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
                  decoration: const BoxDecoration(
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
                    color: Colors.white.withValues(alpha: 0.8),
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

  Widget _buildPendingReviewRow(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: context.read<ApiService>().getPendingReviews(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        // [LOGIC] Check if there's a recent transaction (last 24h) WITHOUT a review
        // For simplicity in this UI demo, we show the card if the user has transactions but few reviews
        // A more robust logic would involve matching transactionIds.
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _buildBentoCard(
            context,
            color: const Color(0xFFFF9800), // Warning Orange
            title: Provider.of<LanguageProvider>(context).translate('pending_review_title'),
            subtitle: Provider.of<LanguageProvider>(context).translate('pending_review_subtitle'),
            icon: Icons.rate_review_rounded,
            isHorizontal: true,
            onTap: () => context.push('/my-reviews'),
          ),
        );
      },
    );
  }

  void _showEmptyCampaignDialog(BuildContext context, String firmName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEE2C2C).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.domain_disabled_rounded, color: Color(0xFFEE2C2C), size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Aktif Kampanya Bulunamadı',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$firmName işletmesinin henüz aktif bir kampanyası bulunmamaktadır. Tarama yapamazsınız.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEE2C2C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(
                    'Tamam',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildAnimatedScanButton(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Button (Gradient Circle)
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4444), Color(0xFFEE2C2C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEE2C2C).withValues(alpha: 0.5),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              // Inner highlight for 3D feel
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(-4, -4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 8),
        // Floating Label Text (Clean)
        Text(
          Provider.of<LanguageProvider>(context).translate('scan_qr'),
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 4,
              )
            ]
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Dynamic Colors
    final Color bgColor = theme.scaffoldBackgroundColor;
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
      floatingActionButtonLocation: const CustomBottomFabLocation(offsetY: 10),
      floatingActionButton: GestureDetector(
        onTap: () {
          final firms = _getFirmBalances(context, listen: false);
          // If current index is within firm range, pass firm context
          if (_currentIndex < firms.length && firms[_currentIndex]['id'] != null) {
            final firm = firms[_currentIndex];
            final firmId = firm['id'];
            
            final allCampaigns = context.read<CampaignProvider>().allCampaigns;
            
            // 1. Get campaigns for this business
            final firmCampaigns = allCampaigns.where((c) => c.businessId == firmId).toList();

            // Check: If firm has 0 campaigns -> Show Empty Dialog
            if (firmCampaigns.isEmpty) {
              _showEmptyCampaignDialog(context, firm['name'] ?? 'İşletme');
              return;
            }
            
            context.push('/customer-scanner', extra: {
              'expectedBusinessId': firmId,
              'expectedBusinessName': firm['name'],
              'expectedBusinessColor': firm['color'],
              'currentStamps': firm['stamps'] ?? 0,
              'targetStamps': firm['stampsTarget'] ?? 6,
              'currentGifts': firm['giftsCount'] ?? 0,
              'currentPoints': firm['points'] ?? '0',
            });
          } else {
            // No firm selected (on "Add" card or empty wallet) — generic scan
            context.push('/customer-scanner');
          }
        },
        child: _buildAnimatedScanButton(context),
      ),
      bottomNavigationBar: null, // Removed as requested for a cleaner UI
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
            padding: const EdgeInsets.only(top: 10, bottom: 100), // Increased bottom padding for floating button
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
                          
                          final int activeIndex = page.round();

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
                                colors: [currentColor, currentColor.withValues(alpha: 0.9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: currentColor.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: Row(
                              children: [
                                // Menu Button (Placeholder)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      // Navigate to MenuScreen
                                      final firm = firms[activeIndex];
                                      context.push(
                                        '/menu', 
                                        extra: {
                                          'businessId': firm['id'], 
                                          'businessName': firm['name'],
                                          'businessColor': firm['color'],
                                          'businessImage': firm['image'] ?? firm['logo']
                                        }
                                      ).then((_) {
                                          // Refresh data if needed (Menu doesn't change wallet state usually)
                                      });
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.grid_view_rounded, color: Colors.white, size: 30),
                                        const SizedBox(height: 6),
                                        Text(
                                          Provider.of<LanguageProvider>(context).translate('menu'), 
                                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Divider
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white.withValues(alpha: 0.2),
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
                
                // [NEW] PENDING REVIEW CARD
                _buildPendingReviewRow(context),

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
                 
                const SizedBox(height: 180), // Bottom padding (clears FAB + BottomAppBar)
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
    final totalItems = firms.length + 1;

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalItems,
            padEnds: true,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 0;
                  if (_pageController.position.haveDimensions) {
                    value = index - (_pageController.page ?? 0);
                    value = (value * 0.04).clamp(-1, 1);
                  }
                  
                  // 3D rotation + scale based on scroll position
                  double pageOffset = 0;
                  if (_pageController.position.haveDimensions) {
                    pageOffset = (index - (_pageController.page ?? 0)).clamp(-1.0, 1.0).toDouble();
                  }
                  final scale = 1.0 - (pageOffset.abs() * 0.1);
                  final rotateY = pageOffset * 0.03;
                  final translateY = pageOffset.abs() * 12;

                  return Transform.translate(
                    offset: Offset(0, translateY),
                    child: Transform.scale(
                      scale: scale,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // perspective
                          ..rotateY(rotateY),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: _buildCardItem(context, index, firms),
                ),
              );
            },
          ),
        ),
        // Page indicator
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            totalItems,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentIndex == i ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentIndex == i
                    ? (i < firms.length 
                        ? (firms[i]['color'] as Color)
                        : Colors.grey)
                    : Colors.grey.withValues(alpha: 0.25),
                boxShadow: _currentIndex == i ? [
                  BoxShadow(
                    color: (i < firms.length 
                        ? (firms[i]['color'] as Color)
                        : Colors.grey).withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ] : [],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(BuildContext context, int index, List<Map<String, dynamic>> firms) {
    if (index == firms.length) {
      return GestureDetector(
        onTap: () async {
          await context.push('/add-firm');
          if (context.mounted) {
            context.read<BusinessProvider>().fetchMyFirms();
          }
        },
        child: _buildAddKafeCard(context, key: const ValueKey('add_cafe_card')),
      );
    }

    final firm = firms[index];

    final user = context.read<AuthProvider>().currentUser;
    final cardHolder = user?.name ?? 'MÜŞTERİ';

    return WalletCard(
      firm: firm,
      cardHolderName: cardHolder,
      onTap: () async {
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
          'logo': firm['logo'],
          'image': firm['image'],
        });
        
        if (context.mounted) {
          context.read<BusinessProvider>().fetchMyFirms();
        }
      },
    );
  }




  





  Widget _buildBentoCard(BuildContext context, { 
    required Color color, 
    required String title, 
    required String subtitle, 
    required IconData icon, 
    bool isHorizontal = false,
    VoidCallback? onTap,
  }) {
    // Premium Design: Gradient + Background Icon + Shadow
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(24),
           gradient: LinearGradient(
             colors: [color, color.withValues(alpha: 0.8)],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
           ),
           boxShadow: [
             BoxShadow(
               color: color.withValues(alpha: 0.35),
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
                    color: Colors.white.withValues(alpha: 0.15),
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
                              style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)
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
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
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
                            color: Colors.white.withValues(alpha: 0.2), // Frosted glass effect
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
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
                                color: Colors.white.withValues(alpha: 0.85),
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
              Text(greeting, style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 14)),
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

class _Rotating3DCup extends StatefulWidget {
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
  State<_Rotating3DCup> createState() => _Rotating3DCupState();
}

class _Rotating3DCupState extends State<_Rotating3DCup> {
  // AnimationController removed for static cup
  
  @override
  Widget build(BuildContext context) {
    // Calculate Fill Level
    double fillLevel = 0.0;
    if (widget.target > 0) {
      fillLevel = (widget.stamps / widget.target).clamp(0.0, 1.0);
    }

    // Static 3D Cup (No Rotation)
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: fillLevel),
      duration: const Duration(seconds: 2), // Fill up slowly
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform(
          // Keep Perspective Static
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) 
            ..rotateY(-0.5), // Fixed Angle (approx 30 deg) for best 3D view
          child: TakeawayCupIcon(
            size: widget.size, 
            cupColor: widget.color,
            fillLevel: value,
          ),
        );
      },
    );
  }
}


// Custom Docked Location for FAB (Low Profile)
class CustomBottomFabLocation extends FloatingActionButtonLocation {
  final double offsetY;
  const CustomBottomFabLocation({this.offsetY = 30}); // 30px from bottom edge (clear of safe area)

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Center Horizontally
    final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2.0;
    
    // Bottom with fixed offset. 
    // We target the max height minus FAB height minus offset.
    // Note: scaffoldGeometry.scaffoldSize includes Safe Area. 
    final double fabY = scaffoldGeometry.scaffoldSize.height 
        - scaffoldGeometry.floatingActionButtonSize.height 
        - offsetY;

    return Offset(fabX, fabY);
  }
}
