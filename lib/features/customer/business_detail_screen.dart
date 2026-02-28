import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/campaign_provider.dart';
import '../../core/models/campaign_model.dart';
import '../../core/providers/business_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/auto_text.dart';
import 'gift_selection_screen.dart';
import 'menu_screen.dart';

class BusinessDetailScreen extends StatefulWidget {
  final Map<String, dynamic> businessData;

  const BusinessDetailScreen({super.key, required this.businessData});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  // Real Local state to allow refreshing UI on sim
  late int _stamps;
  late int _stampsTarget;
  late int _giftsCount;
  late String _points;
  late String _businessId;
  bool _isNew = false;
  bool _isAddingLoading = false;

  // Business menu preview (Figma "Menü" section)
  List<dynamic> _products = [];
  bool _isProductsLoading = true;

  @override
  void initState() {
    super.initState();
    final data = widget.businessData;
    _stamps = data['stamps'] ?? 0;
    _stampsTarget = data['stampsTarget'] ?? 6;
    _giftsCount = data['giftsCount'] ?? 0;
    _points = (data['points'] ?? '0').toString();
    _businessId = data['id'] ?? '';

    // Fetch campaigns and menu products for this business
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().fetchCampaigns(_businessId);
      context.read<BusinessProvider>().setContextFirm(_businessId, widget.businessData['name'] ?? 'İşletme', {
        'expectedBusinessId': _businessId,
        'expectedBusinessName': widget.businessData['name'] ?? '',
        'expectedBusinessColor': widget.businessData['color'],
        'expectedBusinessLogo': widget.businessData['logo'] ?? widget.businessData['image'] ?? widget.businessData['logoUrl'],
        'currentStamps': _stamps,
        'targetStamps': _stampsTarget,
        'currentGifts': _giftsCount,
        'currentPoints': _points,
      });
      _fetchProducts();
    });
  }

  @override
  void dispose() {
    // Clear context when leaving the detail screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BusinessProvider>().clearContextFirm();
      }
    });
    super.dispose();
  }

  Widget _buildActionButtonsRow(LanguageProvider lang, Color brandColor) {

    Widget buildCircleButton({
      required VoidCallback onTap,
      required Widget iconWidget,
      required String label,
      Gradient? gradient,
      Color? background,
      Color? borderColor,
    }) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: gradient,
                color: gradient == null ? (background ?? Colors.white) : null,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: borderColor ?? Colors.transparent,
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3F7F7F7F),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: iconWidget,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF4A4A4A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
          // QR Okut
          buildCircleButton(
            onTap: () {
              final allCampaigns = context.read<CampaignProvider>().allCampaigns;
              final firmCampaigns = allCampaigns.where((c) => c.businessId == _businessId).toList();
              
              if (firmCampaigns.isEmpty) {
                showNoCampaignsDialog(context, widget.businessData['name'] ?? 'İşletme');
                return;
              }

              context.push('/customer-scanner', extra: {
                'expectedBusinessId': _businessId,
                'expectedBusinessName': widget.businessData['name'] ?? '',
                'expectedBusinessColor': widget.businessData['color'],
                'expectedBusinessLogo': widget.businessData['logo'] ?? widget.businessData['image'] ?? widget.businessData['logoUrl'],
                'currentStamps': _stamps,
                'targetStamps': _stampsTarget,
                'currentGifts': _giftsCount,
                'currentPoints': _points,
              });
            },
            iconWidget: Image.asset('assets/images/qr.png', fit: BoxFit.contain),
            label: lang.translate('qr_okut'),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFA96307), Color(0xFF371E04)],
            ),
            borderColor: const Color(0xFF9E560F),
          ),
          // Puan Harca
          buildCircleButton(
            onTap: _navigateToGiftSelection,
            iconWidget: SvgPicture.asset(
              'assets/images/vector_puan.svg', 
              width: 30, // Increased size
              height: 30, // Increased size
              fit: BoxFit.contain, 
              colorFilter: const ColorFilter.mode(Color(0xFFFBFBFB), BlendMode.srcIn)
            ),
            label: lang.translate('puan_harca'),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFA96307), Color(0xFF371E04)],
            ),
            borderColor: const Color(0xFF9E560F),
          ),
          // Siparişlerim
          buildCircleButton(
            onTap: _showHistoryBottomSheet,
            iconWidget: SvgPicture.asset('assets/images/meteor-icons_coffee.svg', fit: BoxFit.contain, colorFilter: const ColorFilter.mode(Color(0xFFFBFBFB), BlendMode.srcIn)),
            label: lang.translate('siparislerim'),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFA96307), Color(0xFF371E04)],
            ),
            borderColor: const Color(0xFF9E560F),
          ),
      ],
    );
  }

  Widget _buildStatisticsSection(LanguageProvider lang, Color brandColor, String businessName) {
    
    // Coffee cup fill progress
    final double fillProgress = (_stampsTarget > 0) ? (_stamps / _stampsTarget).clamp(0.0, 1.0) : 0.0;
    
    // Review score & count (fallback to defaults if undefined)
    final double reviewScore = (widget.businessData['reviewScore'] ?? 0.0).toDouble();
    final int reviewCount = widget.businessData['reviewCount'] ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end, // Align elements to bottom to balance the cup and the badges on the same line
      children: [
        // Left Column: Coffee Cup
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 145, // Increased size to match Figma better and push it further down naturally
              width: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/coffee_cup_empty.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (fillProgress > 0)
                    Positioned.fill(
                      child: ClipRect(
                        clipper: _CoffeeLevelClipper(fillProgress),
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF77410C), Color(0xFF4A2810)],
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
            const SizedBox(height: 12),
            Text(
              "$_giftsCount ${lang.translate('hediye_icecek')}",
              style: GoogleFonts.outfit(
                color: const Color(0xFF4A4A4A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 15),
        // Right Column: Cafe header card + Badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Firm Info Box Using vector5
              SizedBox(
                height: 64,
                width: 185, // Increased from 160 to give text more breathing room so FittedBox doesn't shrink it to unreadable sizes
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Background SVG with shadow
                    SvgPicture.asset(
                      'assets/images/vector5.svg',
                      width: 185,
                      height: 74,
                      fit: BoxFit.fill, // Allows the image to stretch horizontally 
                    ),
                    // Content
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 30, right: 10), // Reduced left padding to push logo further left
                        child: Transform.translate(
                          offset: const Offset(0, -3), // Moving the whole row slightly up
                          child: Row(
                            children: [
                              Container(
                                width: 20, // Reduced logo size slightly more
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      () {
                                        final raw = widget.businessData['logo'] ?? widget.businessData['image'];
                                        return resolveImageUrl(raw) ?? 'https://placehold.co/100.png';
                                      }()
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Visual vertical alignment adjustment removed for better centering
                                  SizedBox(
                                    width: 110, // Max space left in the box
                                    child: Text(
                                      businessName,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF131313),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        height: 1.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF9C06A)), // Reverted slightly bigger star 
                                        const SizedBox(width: 2),
                                        Text(
                                          reviewScore.toStringAsFixed(1).replaceAll('.', ','),
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF4A4A4A),
                                            fontSize: 13, // Down from 14
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                          Text(
                                            "($reviewCount ${lang.translate('reviews_count')})",
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF4A4A4A),
                                            fontSize: 10, // Down from 12
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
              const SizedBox(height: 35),
              // Damga & Puan Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Damga
                  Column(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: const ShapeDecoration(
                                color: Color(0x4C77410C),
                                shape: OvalBorder(),
                                shadows: [
                                  BoxShadow(color: Color(0x3F7F7F7F), blurRadius: 4, offset: Offset(0, 4))
                                ],
                              ),
                            ),
                            CircularProgressIndicator(
                              value: (_stampsTarget > 0) ? (_stamps / _stampsTarget) : 0,
                              strokeWidth: 2,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF77410C)),
                            ),
                            Center(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$_stamps',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF77410C),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '/$_stampsTarget',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF77410C),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.coffee, size: 12, color: Color(0xFF4A4A4A)),
                          const SizedBox(width: 4),
                          Text(
                            lang.translate('stamp_label'),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF4A4A4A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Puan
                  Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const ShapeDecoration(
                          color: Color(0x4C77410C),
                          shape: OvalBorder(
                            side: BorderSide(width: 1, color: Color(0xA377410C)),
                          ),
                          shadows: [
                            BoxShadow(color: Color(0x3F7F7F7F), blurRadius: 4, offset: Offset(0, 4))
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _points,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF77410C),
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFF4A4A4A)),
                          const SizedBox(width: 4),
                          Text(
                            lang.translate('point_label'),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF4A4A4A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildMenuSection(BuildContext context, LanguageProvider lang, Color brandColor, String businessName) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lang.translate('menu_header'),
              style: GoogleFonts.outfit(
                color: const Color(0xFF434343),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuScreen(
                      businessId: _businessId,
                      businessName: businessName,
                      businessColor: brandColor,
                      businessImage: widget.businessData['image'],
                      businessLogo: widget.businessData['logo'] ?? widget.businessData['image'] ?? widget.businessData['logoUrl'],
                    ),
                  ),
                );
              },
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
        const SizedBox(height: 18),
        SizedBox(
          height: 166,
          child: _isProductsLoading
              ? const Center(child: CircularProgressIndicator())
              : (_products.isEmpty
                  ? Center(
                      child: Text(
                        lang.translate('menu_preparing'),
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _products.length.clamp(0, 3),
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return _buildMenuItemCard(product);
                      },
                    )),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(dynamic product) {
    final imageUrl = resolveImageUrl(product['imageUrl']);
    final price = (product['price'] as num?) ?? 0;

    return Container(
      width: 150,
      height: 166,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: const Color(0xFFFFFDF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Product Image Container
          Positioned(
            left: 2,
            top: 2,
            child: Container(
              width: 146,
              height: 83,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                    )
                  : Container(color: Colors.grey[100]),
            ),
          ),
          // Product Info
          Positioned(
            left: 10,
            top: 92,
            child: SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoText(
                    product['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontSize: 15, // Increased font size
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AutoText(
                    product['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF4F4A4A),
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Price
          Positioned(
            right: 10,
            bottom: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((product['discount'] ?? 0) > 0) ...[
                  Text(
                    '${price.toStringAsFixed(0)}₺',
                    style: GoogleFonts.outfit(
                      color: Colors.grey,
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  '${(price - (product['discount'] ?? 0)).toStringAsFixed(0)}₺',
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCampaignsSection(BuildContext context, LanguageProvider lang, Color brandColor) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('active_campaigns_header'),
          style: GoogleFonts.outfit(
            color: const Color(0xFF434343),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        Consumer<CampaignProvider>(
          builder: (context, campProvider, child) {
            final campaigns = campProvider.getCampaignsForBusiness(_businessId);
            if (campaigns.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  lang.translate('no_campaigns_soon'),
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              );
            }

            return Column(
              children: campaigns
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCampaignCard(c, brandColor),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }


  Future<void> _refreshData() async {
      // Re-fetch business data to update stamps/points
      try {
        final api = context.read<ApiService>();
        // We might need a specific endpoint to get single business details or just refresh list
        // For now, re-fetching global list and finding this business again
        // Or if we have a direct endpoint:
        final updatedData = await api.getBusinessById(_businessId);
        setState(() {
            _stamps = updatedData['stamps'] ?? _stamps;
            _stampsTarget = updatedData['stampsTarget'] ?? _stampsTarget;
            _giftsCount = updatedData['giftsCount'] ?? _giftsCount;
            _points = (updatedData['points'] ?? _points).toString();
        });
      } catch (e) {
          debugPrint("Error refreshing business data: $e");
      }
  }

  Future<void> _fetchProducts() async {
    try {
      final api = context.read<ApiService>();
      final products = await api.getBusinessProducts(_businessId);
      if (!mounted) return;
      setState(() {
        _products = products;
        _isProductsLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching business products: $e");
      if (!mounted) return;
      setState(() {
        _isProductsLoading = false;
      });
    }
  }

  Future<void> _navigateToGiftSelection() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final double points = double.tryParse(_points) ?? 0.0;
    
    final logoUrl = widget.businessData['logo'] ?? widget.businessData['image'] ?? widget.businessData['logoUrl'];
    final reviewScore = (widget.businessData['reviewScore'] ?? 0.0).toDouble();
    final reviewCount = widget.businessData['reviewCount'] ?? 0;

    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GiftSelectionScreen(
          businessId: _businessId,
          businessName: widget.businessData['name'] ?? '',
          currentPoints: points,
          currentGifts: _giftsCount,
          logoUrl: logoUrl,
          reviewScore: reviewScore,
          reviewCount: reviewCount,
        ),
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  void _showHistoryBottomSheet() {
    final rawLogoUrl = widget.businessData['logo'] ?? widget.businessData['image'] ?? widget.businessData['logoUrl'];
    final logoUrl = resolveImageUrl(rawLogoUrl) ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F7), // Premium light background
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              // Header with logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    if (logoUrl.isNotEmpty) 
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          image: DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      )
                    else 
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: AppTheme.deepBrown, size: 24),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Provider.of<LanguageProvider>(context, listen: false).translate('order_history'),
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.deepBrown),
                          ),
                          Text(
                             widget.businessData['name'] ?? '',
                             style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.deepBrown.withValues(alpha: 0.6)),
                             maxLines: 1, 
                             overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: context.read<ApiService>().getTransactionHistory(_businessId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("${Provider.of<LanguageProvider>(context, listen: false).translate('error')}: ${snapshot.error}"));
                    }
                    final lang = Provider.of<LanguageProvider>(context);
                    final history = snapshot.data ?? [];
                    if (history.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(Provider.of<LanguageProvider>(context, listen: false).translate('no_orders_yet'), style: GoogleFonts.outfit(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: history.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tx = history[index];
                        final type = tx['type']; // 'STAMP', 'POINT', 'gift_redemption'
                        // Check if pointsEarned is negative to determine if it's a spend
                        final pointsEarned = tx['pointsEarned']; // May be null or number
                        final description = tx['description'] ?? '';
                        
                        final date = DateTime.parse(tx['createdAt']);
                        final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(date);
                        
                        // Default values
                        // Use local variables that will be assigned in the branches below
                        final String title;
                        final String sign;
                        final Color color;
                        final List<Widget> amountWidgets = [];
                        
                        // Parse points securely
                        double? pts;
                        if (pointsEarned != null) {
                           if (pointsEarned is num) pts = pointsEarned.toDouble();
                           if (pointsEarned is String) pts = double.tryParse(pointsEarned);
                        } else if (type == 'POINT' && tx['value'] != null) {
                           if (tx['value'] is num) pts = tx['value'].toDouble();
                           if (tx['value'] is String) pts = double.tryParse(tx['value']);
                        }

                        if (type == 'gift_redemption') {
                          final isEntitlement = description.contains('Hediye Hakkı');
                          sign = "";
                          if (isEntitlement || pts == null || pts == 0) {
                             title = "Hediye Kullanıldı";
                             color = Colors.amber; 
                             amountWidgets.add(Text("-1 Hediye", style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 13)));
                           } else {
                              title = description.replaceAll('Hediye Alımı: ', '');
                              color = AppTheme.primaryColor;
                              amountWidgets.add(Text("${pts.toInt()} ${lang.translate('unit_point')}", style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 13)));
                           }
                        } else if (type == 'STAMP') {
                           title = Provider.of<LanguageProvider>(context, listen: false).translate('stamp_earned');
                           color = const Color(0xFF4CAF50); // Premium Green
                           sign = "+";
                           final stamps = tx['stampsEarned'] ?? tx['value'] ?? 1;
                           if (stamps != null) amountWidgets.add(Text("+$stamps ${lang.translate('unit_stamp')}", style: GoogleFonts.outfit(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)));
                           if (pts != null && pts != 0) {
                              amountWidgets.add(Text("+${pts.toInt()} ${lang.translate('unit_point')}", style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)));
                           }
                        } else if (type == 'POINT') {
                           sign = pts != null && pts < 0 ? "" : "+";
                           if (pts != null && pts < 0) {
                              title = lang.translate('point_spending');
                              color = AppTheme.primaryColor;
                              amountWidgets.add(Text("${pts.toInt()} Puan", style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 13)));
                           } else {
                              title = lang.translate('point_earned');
                              color = const Color(0xFF4CAF50);
                              if (pts != null && pts > 0) {
                                  amountWidgets.add(Text("+${pts.toInt()} ${lang.translate('unit_point')}", style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 13)));
                              }
                           }
                        } else if (type == 'GIFT_REDEEM') {
                           title = Provider.of<LanguageProvider>(context, listen: false).translate('gift_redeemed');
                           color = Colors.red;
                           sign = "-";
                           amountWidgets.add(Text("-1 Hediye", style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 13)));
                        } else {
                           title = "İşlem";
                           color = Colors.grey;
                           sign = "";
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  (sign == "-" || (pointsEarned != null && (pointsEarned as num) < 0)) ? Icons.shopping_bag_outlined : Icons.redeem_rounded,
                                  color: color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.deepBrown),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formattedDate,
                                      style: GoogleFonts.outfit(color: AppTheme.deepBrown.withValues(alpha: 0.5), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: amountWidgets,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
    
  @override
  Widget build(BuildContext context) {
    final data = widget.businessData;
    final String name = data['name'] ?? 'İşletme';
    final dynamic rawColor = data['color'];
    Color brandColor;
    if (rawColor is Color) {
      brandColor = rawColor;
    } else if (rawColor is String) {
      try {
        brandColor = Color(int.parse(rawColor.replaceAll('#', '0xFF')));
      } catch (e) {
        brandColor = const Color(0xFF76410B);
      }
    } else {
      brandColor = const Color(0xFF76410B);
    } 

    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFEBEBEB),
      body: Stack(
        children: [
          // Scrollable Content layer
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top section (Backgrounds + Stats + Actions)
                  Stack(
                    children: [
                      // Background Vector (Top Greyish Base - Figma 26:462)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -60, 
                        child: SvgPicture.asset(
                          'assets/figma/bg_top_26_462.svg',
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      
                      // Background Vector (Yellow Curve - Figma 26:461)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -40,
                        child: SvgPicture.asset(
                          'assets/figma/bg_26_461.svg',
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                      
                      // Content over background
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 130), // Increased spacing for Safe Area Custom Header so vector5 doesn't touch icons

                          // Statistics Section (Coffee cup + Damga/Puan)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildStatisticsSection(lang, brandColor, name),
                          ),

                          const SizedBox(height: 35), // Space based on Figma

                          // Action Buttons Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildActionButtonsRow(lang, brandColor),
                          ),

                          const SizedBox(height: 70),
                        ],
                      ),
                    ],
                  ),

                  // Menu and Campaigns (Curved overlapping container)
                  Transform.translate(
                    offset: const Offset(0, -50), // Increased pull up to overlap the drawn wavy background better
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.only(top: 24, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // [FIGMA] Menü Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildMenuSection(context, lang, brandColor, name),
                          ),

                          const SizedBox(height: 24),

                          // [FIGMA] Aktif Kampanyalar Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildActiveCampaignsSection(context, lang, brandColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom Header (Positioned at top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button moved up completely as requested
                    Transform.translate(
                      offset: const Offset(0, -15), // Pulled 1-1.5 CM upwards to avoid touching yellow BG
                      child: GestureDetector(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        child: SvgPicture.asset(
                          'assets/figma/back_button.svg',
                          width: 33,
                          height: 33,
                        ),
                      ),
                    ),
                    
                    // Right Action Buttons (Notification / Profile)
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
                                side: const BorderSide(width: 1, color: Color(0xFFDADADA)),
                                borderRadius: BorderRadius.circular(44),
                              ),
                              shadows: const [
                                BoxShadow(color: Color(0x3F7F7F7F), blurRadius: 4, offset: Offset(0, 4))
                              ],
                            ),
                            child: const Icon(Icons.notifications_none_rounded, size: 20, color: Color(0xFF76410B)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Profile Button
                        Builder(
                          builder: (context) {
                            final user = context.watch<AuthProvider>().currentUser;
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
                            
                            return GestureDetector(
                              onTap: () => context.push('/settings'),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: ShapeDecoration(
                                  color: Colors.white.withValues(alpha: 0.40),
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(width: 1.31, color: Color(0xFFDADADA)),
                                    borderRadius: BorderRadius.circular(57.75),
                                  ),
                                  shadows: const [
                                    BoxShadow(color: Color(0x3F7F7F7F), blurRadius: 5.25, offset: Offset(0, 5.25))
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(57.75),
                                  child: imageProvider != const AssetImage('assets/images/default_profile.png')
                                    ? CircleAvatar(
                                        backgroundColor: Colors.transparent,
                                        backgroundImage: imageProvider,
                                      )
                                    : const Icon(Icons.person_outline_rounded, size: 30, color: Color(0xFF76410B)),
                                ),
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isNew)
            Positioned.fill(
              child: Container(
                color: Colors.grey.withValues(alpha: 0.2), // Light grey overlay
              ),
            ),
        ],
      ),
      bottomNavigationBar: _isNew 
        ? Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 10 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: ElevatedButton(
              onPressed: _isAddingLoading ? null : _addToWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isAddingLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(lang.translate('add_to_wallet'), style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        : null,
    );
  }

  Future<void> _addToWallet() async {
    setState(() => _isAddingLoading = true);
    try {
      await context.read<ApiService>().addFirm(_businessId);
      if (mounted) {
        showCustomPopup(
          context,
          message: Provider.of<LanguageProvider>(context, listen: false).translate('added_to_wallet_msg'),
          type: PopupType.success,
        );
        // Refresh providers
        context.read<BusinessProvider>().fetchMyFirms();
        context.read<BusinessProvider>().fetchExploreFirms();
        // Unlock screen instead of popping
        setState(() {
           _isNew = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showCustomPopup(
          context,
          message: "${Provider.of<LanguageProvider>(context, listen: false).translate('error')}: $e",
          type: PopupType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingLoading = false);
    }
  }


  Widget _buildCampaignCard(CampaignModel campaign, Color color) {
    return GestureDetector(
      onTap: () => context.push('/campaign-detail', extra: campaign),
      child: Container(
        height: 142, // Increased from 127 to fit bigger text
        width: double.infinity,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFD7D7D7)),
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x14000000), // 0.08 alpha
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Left Image
            Positioned(
              left: 7,
              top: 7,
              child: Container(
                width: 140,
                height: 128, // Scaled down from 142 container to maintain 7px padding
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: const [
                    BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))
                  ],
                ),
                child: campaign.headerImage != null
                    ? Image.network(
                        resolveImageUrl(campaign.headerImage)!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      )
                    : const SizedBox(),
              ),
            ),
            // Right Content
            Positioned(
              left: 159, // slightly adjusted from 169 to give left padding as 140+7=147
              top: 15,
              right: 12, // add right padding constraint instead of fixed width
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business name placeholder in Figma "The Stock", here using campaign.businessName
                      Row(
                        children: [
                          Container(
                            width: 16, // Slighly bigger logo
                            height: 16, // Slighly bigger logo
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              image: DecorationImage(
                                image: NetworkImage(
                                  () {
                                    // Image resolving logic
                                    final raw = widget.businessData['logo'] ?? widget.businessData['image'];
                                    return resolveImageUrl(raw) ?? 'https://placehold.co/100.png';
                                  }()
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: AutoText(
                              campaign.businessName.isNotEmpty ? campaign.businessName : 'The Stock',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF131313),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AutoText(
                        campaign.title,
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      AutoText(
                        campaign.shortDescription,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF4F4A4A),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  
                  // Detayları Gör Button
                  SizedBox(
                    width: double.infinity,
                    height: 24, // Expanded slightly from Figma 20px for better touch target
                    child: ElevatedButton(
                      onPressed: () => context.push('/campaign-detail', extra: campaign),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9C06A),
                        foregroundColor: const Color(0xFF76410B),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        context.read<LanguageProvider>().translate('view_details'),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF77410C),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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
