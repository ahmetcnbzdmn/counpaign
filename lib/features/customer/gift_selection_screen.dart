import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/auto_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'scanner_screen.dart';
import 'widgets/customer_points_card.dart';

class GiftSelectionScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final double currentPoints;
  final int currentGifts;
  final String? logoUrl;
  final double? reviewScore;
  final int? reviewCount;

  const GiftSelectionScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.currentPoints,
    required this.currentGifts,
    this.logoUrl,
    this.reviewScore,
    this.reviewCount,
  });

  @override
  State<GiftSelectionScreen> createState() => _GiftSelectionScreenState();
}

class _GiftSelectionScreenState extends State<GiftSelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoading = true;
  List<dynamic> _gifts = [];
  String? _redeemingGiftId; 
  String _selectedCategory = 'Tümü';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _fetchGifts();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchGifts() async {
    try {
      final api = context.read<ApiService>();
      final gifts = await api.getBusinessGifts(widget.businessId);
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      setState(() {
        _gifts = gifts;
        _selectedCategory = lang.locale.languageCode == 'tr' ? 'Tümü' : 'All';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching gifts: $e");
      setState(() => _isLoading = false);
    }
  }


  Future<void> _redeemGift(dynamic gift) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final api = context.read<ApiService>();
    
    // 1. Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.translate('confirm_redeem_title'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          "${lang.translate('confirm_redeem_msg')}${gift['title']}?\n(${gift['pointCost']} ${lang.translate('points')})",
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.translate('cancel'), style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEE2C2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.translate('confirm'), style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Prepare Redemption (creates token on backend)
    setState(() => _redeemingGiftId = gift['_id']);

    try {
      await api.prepareRedemption(widget.businessId, gift['_id']);
      
      // 3. Open QR Scanner to scan business's static QR
      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => CustomerScannerScreen(
              extra: {
                'expectedBusinessId': widget.businessId,
                'expectedBusinessName': widget.businessName,
                'expectedBusinessLogo': widget.logoUrl,
              },
            ),
          ),
        );

        // If scanner returned true (success), go home
        if (result == true && mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = lang.translate('error');
        if (e.toString().contains('Yetersiz puan')) {
          errorMsg = lang.translate('insufficient_points');
        }
        showCustomPopup(
          context,
          message: errorMsg,
          type: PopupType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _redeemingGiftId = null);
    }
  }

  Future<void> _redeemGiftEntitlement() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final api = context.read<ApiService>();

    // 1. Confirm Entitlement Usage
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.translate('redeem_entitlement_title'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          lang.translate('gift_entitlement_confirm'),
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.translate('cancel'), style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEE2C2C)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.translate('confirm'), style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Prepare Redemption & Open Scanner
    try {
      await api.prepareRedemption(widget.businessId, "", type: 'GIFT_ENTITLEMENT');

      // 3. Open QR Scanner to scan business's static QR
      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => CustomerScannerScreen(
              extra: {
                'expectedBusinessId': widget.businessId,
                'expectedBusinessName': widget.businessName,
                'expectedBusinessLogo': widget.logoUrl,
              },
            ),
          ),
        );

        // If scanner returned true (success), go home
        if (result == true && mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomPopup(
          context,
          message: lang.translate('gift_error_msg'),
          type: PopupType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final bool isTr = lang.locale.languageCode == 'tr';

    return Scaffold(
      backgroundColor: const Color(0xFFEBEBEB),
      body: Stack(
        children: [
          // Soft Hill background shape from Figma
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _HillClipper(),
              child: Container(
                height: 380,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFECCC),
                      Color(0xFFF9C06A),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Large half-star background deco
          Positioned(
            top: -120,
            left: 60,
            child: Opacity(
              opacity: 0.2, // Very subtle
              child: SvgPicture.asset(
                'assets/images/vector2.svg',
                width: 480,
                height: 480,
                colorFilter: const ColorFilter.mode(Color(0xFFF9C06A), BlendMode.srcIn),
              ),
            ),
          ),
          // Subtle watermark
          Positioned(
            left: -150,
            top: 220,
            child: SvgPicture.asset(
              'assets/images/union.svg',
              height: 320,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.015),
                BlendMode.srcIn,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildCafeInfoCard(isTr),
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const SizedBox(height: 20),
                      _buildPointsCard(isTr),
                      const SizedBox(height: 32),
                      _buildMenuTitle(isTr),
                      const SizedBox(height: 16),
                      _buildCategoryFilters(isTr),
                      const SizedBox(height: 24),
                      _buildProductGrid(lang, isTr),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
            ),
          ),
          Row(
            children: [
              // Notifications Button
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDADADA)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: Colors.black, size: 24),
                ),
              ),
              const SizedBox(width: 12),
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
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDADADA)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(42),
                        child: imageProvider != const AssetImage('assets/images/default_profile.png')
                          ? CircleAvatar(
                              backgroundColor: Colors.transparent,
                              backgroundImage: imageProvider,
                            )
                          : const Icon(Icons.person_outline_rounded, size: 24, color: Colors.black),
                      ),
                    ),
                  );
                }
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCafeInfoCard(bool isTr) {
    final String? resolvedLogo = resolveImageUrl(widget.logoUrl);
    
    return Container(
      margin: const EdgeInsets.only(top: 10, right: 20),
      alignment: Alignment.centerRight,
      child: SizedBox(
        height: 64,
        width: 185, // Matches the expansion in business detail
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Background SVG with shadow
            SvgPicture.asset(
              'assets/images/vector5.svg',
              width: 185,
              height: 74,
              fit: BoxFit.fill, // Allows stretching
            ),
            // Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(left: 30, right: 10), // Same padding alignment
                child: Transform.translate(
                  offset: const Offset(0, -3), // Move slightly up
                  child: Row(
                    children: [
                      Container(
                        width: 20, // Smaller logo size for alignment
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: resolvedLogo != null
                              ? Image.network(
                                  resolvedLogo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                                )
                              : Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(
                                widget.businessName,
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
                                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF9C06A)),
                                  const SizedBox(width: 2),
                                  Text(
                                    (widget.reviewScore ?? 0.0).toStringAsFixed(1).replaceAll('.', ','),
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF4A4A4A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isTr ? '(${widget.reviewCount ?? 0} değerlendirme)' : '(${widget.reviewCount ?? 0} reviews)',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF4A4A4A),
                                      fontSize: 10,
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
    );
  }

  Widget _buildPointsCard(bool isTr) {
    final title = isTr ? 'Hesabındaki puan' : 'Points in account';
    final pointsText = widget.currentPoints.toInt().toString();
    final noteText = isTr
        ? 'Puanlar, kazanıldıktan 6 ay sonra kaybolur.'
        : 'Points expire after 6 months.';

    return CustomerPointsCard(
      title: title,
      pointsText: pointsText,
      noteText: noteText,
    );
  }

  Widget _buildMenuTitle(bool isTr) {
    return Text(
      isTr ? 'Puan Menüsü' : 'Points Menu',
      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF434343)),
    );
  }

  Widget _buildCategoryFilters(bool isTr) {
    final List<String> categories = [isTr ? 'Tümü' : 'All'];
    for (var gift in _gifts) {
      final cat = gift['category'];
      if (cat != null && cat.toString().trim().isNotEmpty && !categories.contains(cat)) {
        categories.add(cat);
      }
    }

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF9C06A) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? null : Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(color: Color(0xFF77410C), shape: BoxShape.circle),
                      child: const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF9C06A)),
                    ),
                  if (isSelected)
                    const SizedBox(width: 4),
                  Text(
                    category,
                    style: GoogleFonts.outfit(
                      color: isSelected ? const Color(0xFF77410C) : const Color(0xFF757575),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(LanguageProvider lang, bool isTr) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
    }

    final allText = isTr ? 'Tümü' : 'All';
    final filteredGifts = _selectedCategory == allText 
        ? _gifts 
        : _gifts.where((g) => g['category'] == _selectedCategory).toList();
    
    if (filteredGifts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            lang.translate('no_gifts_yet'),
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredGifts.length,
      itemBuilder: (context, index) {
        final gift = filteredGifts[index];
        return _buildProductCard(gift, lang);
      },
    );
  }

  Widget _buildProductCard(dynamic gift, LanguageProvider lang) {
    final cost = gift['pointCost'];
    final canAfford = widget.currentPoints >= cost;
    final isRedeeming = _redeemingGiftId == gift['_id'];

    return GestureDetector(
      onTap: (canAfford && !isRedeeming) ? () => _redeemGift(gift) : null,
      child: Opacity(
        opacity: canAfford ? 1.0 : 0.6,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Stack(
                      children: [
                        if (gift['image'] != null && gift['image'].toString().isNotEmpty)
                          Positioned.fill(
                            child: Image.network(
                              resolveImageUrl(gift['image']) ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.coffee_rounded, size: 40, color: Color(0xFF77410C))),
                            ),
                          )
                        else
                          const Center(child: Icon(Icons.coffee_rounded, size: 40, color: Color(0xFF77410C))),
                        if (isRedeeming)
                          const Center(child: CircularProgressIndicator(color: Color(0xFF77410C))),
                      ],
                    ),
                  ),
                ),
              ),
              // Info content
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gift['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (gift['description'] != null && gift['description'].toString().trim().isNotEmpty)
                          ? gift['description']
                          : 'Özel hediye seçeneği',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF4F4B4B)),
                    ),
                    const SizedBox(height: 8),
                    // Points Badge
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9C06A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(1),
                              decoration: const BoxDecoration(color: Color(0xFF77410C), shape: BoxShape.circle),
                              child: const Icon(Icons.star_rounded, size: 11, color: Color(0xFFF9C06A)),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$cost",
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF77410C)),
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

}

// Hill Clipper for the soft background shape
class _HillClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.4);
    
    final centerX = size.width * 0.5;
    final centerY = size.height;
    
    // Very soft curve ascending to a broad peak
    path.cubicTo(
      size.width * 0.2, size.height * 0.4,
      size.width * 0.35, size.height * 0.1,
      centerX, 0
    );
    // Descending curve
    path.cubicTo(
      size.width * 0.65, size.height * 0.1,
      size.width * 0.8, size.height * 0.4,
      size.width, size.height * 0.4
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Peak Clipper removed
