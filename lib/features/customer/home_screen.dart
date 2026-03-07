import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'gift_selection_screen.dart';
import '../../core/providers/auth_provider.dart' as app;
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/services/api_service.dart';
import '../../core/models/campaign_model.dart';
import '../../core/widgets/icons/takeaway_cup_icon.dart';
import '../../core/providers/business_provider.dart';
import '../../core/providers/campaign_provider.dart';
import '../../core/providers/language_provider.dart';


import '../../features/customer/widgets/wallet_card.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/auto_text.dart';
import '../../core/widgets/backgrounds/organic_wave_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.93);
  final PageController _campaignPageController = PageController(viewportFraction: 0.86);
  int _currentIndex = 0;
  int _currentCampaignIndex = 0;

  // Review state
  List<dynamic> _pendingReviews = [];
  int _selectedRating = 0;
  bool _isSubmittingReview = false;
  bool _pendingReviewsLoaded = false;
  
  @override
  void dispose() {
    _pageController.dispose();
    _campaignPageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    // Fetch data using the provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      // Load pending reviews immediately
      _loadPendingReviews();

      final bp = context.read<BusinessProvider>();
      final cp = context.read<CampaignProvider>();
      final auth = context.read<app.AuthProvider>();

      // If auth not initialized yet, wait for it shortly
      if (!auth.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) _loadPendingReviews(); // Try again if auth just loaded
      }

      try {
        await bp.fetchMyFirms();
        // Fetch global data for counts
        bp.fetchExploreFirms();
        cp.fetchAllCampaigns();

        if (mounted) {
          final firms = bp.myFirms;
          for (var firm in firms) {
            cp.fetchCampaigns(firm['id']);
          }
        }
      } catch (e) {
        debugPrint('Home data fetch error: $e');
      }
    });
  }

  Future<void> _loadPendingReviews() async {
    try {
      final api = context.read<ApiService>();
      final data = await api.getPendingReviews();
      if (mounted) {
        setState(() {
          _pendingReviews = data;
          _pendingReviewsLoaded = true;
          _selectedRating = 0;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pendingReviewsLoaded = true;
        });
      }
    }
  }

  Future<void> _submitReview(dynamic review, int rating, {String comment = ''}) async {
    if (_isSubmittingReview) return;
    setState(() {
      _isSubmittingReview = true;
      _selectedRating = rating;
    });

    try {
      final api = context.read<ApiService>();
      final transactionId = review['_id'];
      final businessId = review['business'] is Map
          ? review['business']['_id']
          : review['business'];
      await api.submitReview(transactionId, businessId, rating, comment);

      if (mounted) {
        setState(() {
          _pendingReviews.removeAt(0);
          _selectedRating = 0;
          _isSubmittingReview = false;
        });
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingReview = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değerlendirme gönderilemedi.')),
        );
      }
    }
  }

  void _showRatingDialog(dynamic review, int rating) {
    if (_isSubmittingReview) return;
    
    final TextEditingController noteController = TextEditingController();
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5F5F7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            lang.translate('rating'),
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star_rounded,
                    color: index < rating ? const Color(0xFFE68A01) : const Color(0xFF6D6D6D).withValues(alpha: 0.4),
                    size: 40,
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: lang.translate('optional_note_hint'),
                  hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDADADA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDADADA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77410C)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.outfit(fontSize: 14),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                lang.translate('cancel'),
                style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF77410C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _submitReview(review, rating, comment: noteController.text.trim());
              },
              child: Text(
                lang.translate('save'),
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    final lang = context.read<LanguageProvider>();
    final isTr = lang.locale.languageCode == "tr";
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checkmark Circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9C06A).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFFF9C06A),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                lang.translate('thank_you'),
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF131313),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isTr 
                  ? lang.translate('review_saved_toast') 
                  : 'Your rating has been saved\nsuccessfully.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              // OK Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF131313),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    lang.translate('ok'),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      'reviewScore': e['reviewScore'],
      'reviewCount': e['reviewCount'],
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


  Widget _buildAddKafeCard(BuildContext context, {Key? key}) {
    final lang = Provider.of<LanguageProvider>(context);
    return Container(
      key: key,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF9C06A), // Match Premium Theme
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
                  child: const Icon(Icons.add_rounded, color: Color(0xFF76410B), size: 40), // Premium Brown Icon
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

  @override
  Widget build(BuildContext context) {
    // Watch providers for counts
    final businessProvider = context.watch<BusinessProvider>();
    final myFirmsCount = businessProvider.myFirms.length;

    // [AUTO RE-SYNC] Force jump to 0 when first cafe is added to avoid offset mismatch
    if (myFirmsCount > 0 && _currentIndex != 0 && !_pageController.hasClients) {
       _currentIndex = 0;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: null, 
      body: OrganicWaveBackground(
        child: SafeArea(
          bottom: false, 
          child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
             final biz = context.read<BusinessProvider>();
             final camp = context.read<CampaignProvider>();
             await Future.wait([
               biz.fetchMyFirms(),
               biz.fetchExploreFirms(),
               camp.fetchAllCampaigns(),
               _loadPendingReviews(),
             ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 10, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [1] CUSTOM HEADER
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: RepaintBoundary(
                    child: HomeHeader(),
                  ),
                ),
                 
                const SizedBox(height: 24),
                 
                // [2] BALANCE / LOYALTY CARD CAROUSEL
                Consumer<BusinessProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.myFirms.isEmpty) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.primaryColor)));
                    }
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) => true,
                      child: _buildBalanceCarousel(context),
                    ); 
                  },
                ),

                const SizedBox(height: 16),
                
                // [3] ORDERS / FEEDBACK BANNER
                _buildSiparislerimBanner(context),

                // [4] ACTIVE CAMPAIGNS CAROUSEL
                _buildActiveCampaignsCarousel(context),

                const SizedBox(height: 24),

                // [5] DISCOVER GRID
                _buildDiscoverGrid(context),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSiparislerimBanner(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isTr = lang.locale.languageCode == 'tr';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header (Figma: "Siparişlerim" #434343 w600 14px)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.translate('siparislerim'),
                style: GoogleFonts.outfit(
                  color: AppTheme.sectionTitle,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/order-history'),
                child: Text(
                  lang.translate('view_all'),
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18), // Figma gap=18
          
          // Banner Card — pending reviews from state
          Consumer<BusinessProvider>(
            builder: (context, bp, _) {
              if (!_pendingReviewsLoaded) {
                return Container(
                  height: 154,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                );
              }

              if (_pendingReviews.isEmpty) {
                // Determine if they are a completely new user or just finished reviews
                if (bp.myFirms.isEmpty) {
                   return _buildBannerState1(context, isTr);
                }
                return _buildBannerNoReviews(context, isTr);
              }

              final review = _pendingReviews.first;
              return _buildBannerState2(context, review, isTr);
            },
          ),
          const SizedBox(height: 24), // Figma gap=24
        ],
      ),
    );
  }


  /// State 1: New user — "İlk kahveni birlikte seçelim!" (Figma 1.png)
  Widget _buildBannerState1(BuildContext context, bool isTr) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return GestureDetector(
      onTap: () => context.push('/explore-cafes'),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          height: 145,
          padding: const EdgeInsets.only(left: 16, right: 23),
          decoration: ShapeDecoration(
            color: const Color(0xFFF9C06A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Stack(
            children: [
              // Background Watermark Logo Pattern
              Positioned(
                left: 140,
                right: 5,
                top: 0,
                bottom: 0,
                child: SvgPicture.asset(
                  'assets/images/union.svg',
                  height: 115, // Slightly shrunk
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                ),
              ),
              // Right side coffee splashing image
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Image.asset(
                  'assets/images/siparis_banner_coffee.png',
                  width: 220,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                ),
              ),
              // Left text column
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.translate('no_orders_yet'),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF7F6041),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 0.75,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 130, // Adjusted for Turkish text wrap
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: lang.translate('let_pick_1'),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF111111),
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                height: 1.27,
                              ),
                            ),
                            TextSpan(
                              text: lang.translate('let_pick_2'),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFC06000),
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                height: 1.27,
                              ),
                            ),
                            TextSpan(
                              text: lang.translate('let_pick_3'),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF111111),
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                height: 1.27,
                              ),
                            ),
                          ],
                        ),
                      ),
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


  Widget _buildBannerNoReviews(BuildContext context, bool isTr) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Container(
      width: MediaQuery.of(context).size.width * 0.92,
      constraints: const BoxConstraints(minHeight: 164),
      decoration: ShapeDecoration(
        color: const Color(0xFFF9C06A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: const [
          BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4), spreadRadius: 0)
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Coffee Image
          Positioned(
            right: -40,
            top: -15,
            child: Container(
              width: 224,
              height: 180,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/pngwing_coffee.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 18, right: 174, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang.translate('no_pending_1'),
                  style: GoogleFonts.outfit(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700, height: 1.1), // Increased font weight
                ),
                Text(
                  lang.translate('no_pending_2'),
                  style: GoogleFonts.outfit(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700, height: 1.1), // Increased font weight
                ),
                const SizedBox(height: 8),
                Text(
                  lang.translate('see_you_again'),
                  style: GoogleFonts.outfit(color: const Color(0xFF7F6041), fontSize: 14, fontWeight: FontWeight.w500, height: 1.1), // Increased font size
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day.$month.$year | $hour:$min';
    } catch (_) {
      return '';
    }
  }

  /// State 2: After purchase — "Ziyaretin nasıldı?" (Figma 2.png)
  Widget _buildBannerState2(BuildContext context, dynamic review, bool isTr) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final business = review['business'] is Map ? review['business'] : {};
    final firmName = business['companyName'] ?? (review['businessName'] ?? '');
    final dateTimeStr = _formatDateTime(review['createdAt']);
    final dateParts = dateTimeStr.split(' | ');
    final date = dateParts.isNotEmpty ? dateParts[0] : '';
    final time = dateParts.length > 1 ? dateParts[1] : '';
    
    final String? logoUrl = resolveImageUrl(business['logo'] ?? business['image'] ?? business['logoUrl']);

    return GestureDetector(
      onTap: () => context.push('/my-reviews'),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        constraints: const BoxConstraints(minHeight: 164),
        decoration: ShapeDecoration(
          color: const Color(0xFFF9C06A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadows: const [
            BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4), spreadRadius: 0)
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Coffee Image (Relative Positioned to match screenshot)
            Positioned(
              right: -40,
              top: -15,
              child: Container(
                width: 224,
                height: 180,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/pngwing_coffee.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 18, right: 174, bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titles
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.translate('how_was_visit'),
                        style: GoogleFonts.outfit(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500, height: 1.1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lang.translate('rate_experience_title'),
                        style: GoogleFonts.outfit(color: const Color(0xFF7F6041), fontSize: 12, fontWeight: FontWeight.w500, height: 1.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Rating Section
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          final starIndex = i + 1;
                          final isFilled = (_isSubmittingReview && _selectedRating >= starIndex);
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => _showRatingDialog(review, starIndex),
                              child: Icon(
                                Icons.star_rounded,
                                color: isFilled ? const Color(0xFFE68A01) : const Color(0xFF6D6D6D).withValues(alpha: 0.4),
                                size: 22.83,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      // Date & Time
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            date,
                            style: GoogleFonts.outfit(color: const Color(0xFF3D3D3D), fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 4),
                          Container(width: 1, height: 10, color: const Color(0xFF3D3D3D)),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: GoogleFonts.outfit(color: const Color(0xFF3D3D3D), fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Business Row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (logoUrl != null && logoUrl.isNotEmpty)
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover),
                              ),
                            )
                          else
                            Image.asset('assets/images/splash_logo.png', width: 16, height: 16, errorBuilder: (_, __, ___) => const SizedBox(width: 16, height: 16)),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 113,
                            child: Text(
                              firmName,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(color: const Color(0xFF131313), fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_isSubmittingReview)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }




  Widget _buildActiveCampaignsCarousel(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final campaigns = context.watch<CampaignProvider>().allCampaigns;
    final isTr = lang.locale.languageCode == 'tr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24), // Push down to avoid overlap with coffee splash
        // Section Header (Figma: #434343 w600 14px)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.translate('active_campaigns_header'), 
                style: GoogleFonts.outfit(
                  color: AppTheme.sectionTitle, // #434343
                  fontSize: 14, // Figma: 14px
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/campaigns'),
                child: Text(
                  isTr ? 'Tümünü gör' : 'View All', 
                  style: GoogleFonts.outfit(
                    color: Colors.black, // Figma: #000000
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12), // Figma gap=12
        SizedBox(
          height: 184, // Increased height to prevent bottom shadow clipping
          child: campaigns.isEmpty 
            ? Center(child: Text(lang.translate('no_notifications'), style: GoogleFonts.outfit(color: AppTheme.bodyText)))
            : PageView.builder(
                controller: _campaignPageController,
                itemCount: campaigns.length,
                onPageChanged: (index) => setState(() => _currentCampaignIndex = index),
                itemBuilder: (context, index) {
                  final c = campaigns[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: _buildCampaignCard(c, isTr),
                  );
                },
              ),
        ),
        // Dots (Dynamic generation based on campaigns count)
        if (campaigns.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                campaigns.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentCampaignIndex == i ? 19 : 11,
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: _currentCampaignIndex == i ? AppTheme.activeDot : AppTheme.inactiveDot,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Single Campaign Card (Figma: white bg, r=16, image left 164x164, text right)
  Widget _buildCampaignCard(CampaignModel campaign, bool isTr) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final imageUrl = resolveImageUrl(campaign.headerImage);
    final logoUrl = resolveImageUrl(campaign.businessLogo);
    final businessName = campaign.businessName.isNotEmpty ? campaign.businessName : "Counpaign";

    return GestureDetector(
      onTap: () => context.push('/campaign-detail', extra: campaign),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.zero, // Padding handled by PageView itemBuilder
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Left: Image Container
            Container(
              width: 164,
              height: 164,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
            ),
            const SizedBox(width: 6),
            // Right: Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      // Business Name Row
                      Row(
                        children: [
                          if (logoUrl != null)
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: NetworkImage(logoUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF131313)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              businessName,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF131313),
                                fontSize: 14,
                                fontWeight: FontWeight.w700, // Made bold as requested
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    // Title
                    AutoText(
                      campaign.title,
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Description
                    AutoText(
                      campaign.shortDescription,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF4F4A4A),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9C06A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF76410B).withValues(alpha: 0.05), width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3F000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          lang.translate('view_details'),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF76410B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
    );
  }

  Widget _buildDiscoverGrid(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isTr = lang.locale.languageCode == 'tr';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Figma: "Keşfet" #434343 w600 14px
          Text(
            lang.translate('discover'), 
            style: GoogleFonts.outfit(
              color: AppTheme.sectionTitle, 
              fontSize: 14, 
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18), // Figma gap=18
          Row(
            children: [
              // Tile 1: "Bölgendeki Kafeler" (Figma: 172x172 r=16 gradient #FFFDF7→#F9E6CC, border #76410B/0.5)
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/explore-cafes'),
                  child: Container(
                    height: 172,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFFDF7),
                          Color(0xFFF9E6CC),
                        ],
                      ),
                      border: Border.all(color: AppTheme.deepBrown, width: 0.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Background coffee shop image with gradient overlay
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/coffee_shop_bg.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                        // Dark gradient overlay on the image (Figma: 166.7deg, rgba(0,0,0,0.706) → transparent)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.black.withValues(alpha: 0.706),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.73],
                              ),
                            ),
                          ),
                        ),
                        // Accent bar (Figma: 63x10, left=16, top=55, #E2A13E/0.87)
                        Positioned(
                          left: 16, top: 55,
                          child: Container(
                            width: 63, height: 10,
                            color: const Color(0xDDE2A13E), // rgba(226,161,62,0.87)
                          ),
                        ),
                        // Title text (Figma: left=20, top=16, "Bölgendeki" Regular + "Kafeler" SemiBold #F3F3F3 20px)
                        Positioned(
                          left: 20, top: 16,
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text: lang.translate('in_your_area'),
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFF3F3F3),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  height: 1.3,
                                ),
                              ),
                              TextSpan(
                                text: isTr ? 'Kafeler' : 'Cafes',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFF3F3F3),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Tile 2: "Diğer Kampanyalar" (Figma: 173x172 r=16 #FFE5BE, border #76410B/0.5)
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/campaigns'),
                  child: Container(
                    height: 172,
                    decoration: BoxDecoration(
                      color: const Color(0xA0FFE5BE), // rgba(255,229,190,0.63)
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.deepBrown, width: 0.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Background watermark "Kampanyalar" text (Figma: 4 lines, Bold 22px, positioned from top=56)
                        ...List.generate(4, (i) => Positioned(
                          left: 18, top: 56.0 + (i * 24),
                          child: Text(
                            'Kampanyalar',
                            style: GoogleFonts.outfit(
                              color: AppTheme.deepBrown.withValues(alpha: 0.15),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )),
                        // Accent bar (Figma: 131x10, left=12, top=46, #F9C06A)
                        Positioned(
                          left: 12, top: 46,
                          child: Container(
                            width: 131, height: 10,
                            color: const Color(0xFFF9C06A),
                          ),
                        ),
                        // Title (Figma: "Diğer" Regular 16px + "Kampanyalar" Bold 22px, color #77410C)
                        Positioned(
                          left: 18, top: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTr ? 'Diğer' : 'Other',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF77410C),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                isTr ? 'Kampanyalar' : 'Campaigns',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF1E1D1D),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Hand holding coffee (Figma: left=57, top=60, 112x112)
                        Positioned(
                          left: 57, top: 60,
                          child: Image.asset(
                            'assets/images/hand_coffee.png',
                            width: 112, height: 112,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildBalanceCarousel(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final firms = _getFirmBalances(context);

    // [BUG FIX] If no cafes are added, skip the empty wallet "coffee cup" rotation completely 
    // and just show the "Add Cafe" card flatly.
    final isEmptyWallet = firms.isEmpty || firms.first['name'] == lang.translate('wallet_empty');

    if (isEmptyWallet) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: GestureDetector(
          onTap: () async {
            await context.push('/add-firm');
            if (context.mounted) {
              context.read<BusinessProvider>().fetchMyFirms();
            }
          },
          child: SizedBox(
            height: 180, // Reasonable height for a static "Add Cafe" card
            child: _buildAddKafeCard(context, key: const ValueKey('add_cafe_card')),
          ),
        ),
      );
    }

    final totalItems = firms.length + 1;

    return Column(
      children: [
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalItems,
            padEnds: true,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              context.read<BusinessProvider>().setHomeSelectedFirmIndex(index);
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
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: _currentIndex == i ? 19 : 11,
              height: 9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _currentIndex == i ? AppTheme.activeDot : AppTheme.inactiveDot,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(BuildContext context, int index, List<Map<String, dynamic>> firms) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
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

    return WalletCard(
      firm: firm,
      onScanTap: () async {
        if (firm['name'] == lang.translate('wallet_empty')) return;
        final firmId = firm['id'];
        final allCampaigns = context.read<CampaignProvider>().allCampaigns;
        final firmCampaigns = allCampaigns.where((c) => c.businessId == firmId).toList();

        if (firmCampaigns.isEmpty) {
          showNoCampaignsDialog(context, firm['name'] ?? 'İşletme');
          return;
        }
        
        context.push('/customer-scanner', extra: {
          'expectedBusinessId': firmId,
          'expectedBusinessName': firm['name'],
          'expectedBusinessColor': firm['color'],
          'expectedBusinessLogo': firm['logo'] ?? firm['image'] ?? firm['logoUrl'],
          'currentStamps': firm['stamps'] ?? 0,
          'targetStamps': firm['stampsTarget'] ?? 8,
          'currentGifts': firm['giftsCount'] ?? 0,
          'currentPoints': firm['points'] ?? '0',
        });
      },
      onSpendTap: () {
        final double points = double.tryParse((firm['points'] ?? '0').toString()) ?? 0.0;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GiftSelectionScreen(
              businessId: firm['id'] ?? '',
              businessName: firm['name'] ?? '',
              currentPoints: points,
              currentGifts: firm['giftsCount'] ?? 0,
              logoUrl: firm['logo'] ?? firm['image'] ?? firm['logoUrl'],
              reviewScore: (firm['reviewScore'] ?? 0.0).toDouble(),
              reviewCount: firm['reviewCount'] ?? 0,
            ),
          ),
        );
      },
    );
  }
}


class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    // User Data from Provider
    final user = context.watch<app.AuthProvider>().currentUser;
    final name = user?.fullName ?? "Misafir";
    
    // Dynamic Greeting Logic
    final hour = DateTime.now().hour; 
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
    if (user?.profileImage != null && user!.profileImage!.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(user.profileImage!));
      } catch (e) {
        imageProvider = const AssetImage('assets/images/default_profile.png');
      }
    } else {
      imageProvider = const AssetImage('assets/images/default_profile.png');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Greeting: "Günaydın, Ceyda"
        Expanded(
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$greeting ', // Removed extra comma, greeting has it
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                  TextSpan(
                    text: name,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFEA9514),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12), // Added gap to prevent name from hitting buttons
        
        // Actions: Notifications & Profile
        Row(
          children: [
            // Notifications Button
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Container(
                width: 32,
                height: 32,
                decoration: ShapeDecoration(
                  color: Colors.white.withValues(alpha: 0.40),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 1,
                      color: Color(0xFFDADADA),
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
                child: const Icon(
                  Icons.notifications_none_rounded, 
                  color: AppTheme.deepBrown,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Profile Button
            GestureDetector(
              onTap: () => context.push('/settings'),
              child: Container(
                width: 42,
                height: 42,
                decoration: ShapeDecoration(
                  color: Colors.white.withValues(alpha: 0.40),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 1.31,
                      color: Color(0xFFDADADA),
                    ),
                    borderRadius: BorderRadius.circular(57.75),
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x3F7F7F7F),
                      blurRadius: 5.25,
                      offset: Offset(0, 5.25),
                      spreadRadius: 0,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(57.75),
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    backgroundImage: imageProvider,
                  ),
                ),
              ),
            ),
          ],
        ),
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
