import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/campaign_provider.dart';
import '../../core/providers/business_provider.dart';

import '../../core/models/campaign_model.dart';
import '../../core/widgets/auto_text.dart';
import '../../core/providers/language_provider.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/theme/app_theme.dart';

class CampaignsScreen extends StatefulWidget {
  final String? firmId;
  final String? firmName;

  const CampaignsScreen({
    super.key,
    this.firmId,
    this.firmName,
  });

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final TextEditingController _searchController = TextEditingController();
  

  int _selectedTabIndex = 0;

  bool get _isFiltered => widget.firmId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().fetchAllCampaigns();
      context.read<BusinessProvider>().fetchMyFirms();
      context.read<BusinessProvider>().fetchExploreFirms();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFEBEBEB);
    const cardColor = Colors.white;
    const textColor = Color(0xFF131313);
    const primaryBrand = Color(0xFF76410B);
    
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          _isFiltered
            ? (widget.firmName ?? lang.translate('deals'))
            : lang.translate('deals'),
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // [Search Bar - Hide if filtered]
            if (!_isFiltered)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.outfit(color: textColor),
                decoration: InputDecoration(
                  hintText: lang.translate('search_deal_venue'),
                  hintStyle: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search_rounded, color: textColor.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            
            // [2] Tabs (Horizontal Filters) - Hide if filtered
            if (!_isFiltered)
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: 3, // Fixed count 3
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  const sectionKeys = ['all', 'in_wallet', 'others'];
                  final isSelected = _selectedTabIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF9C06A) : cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.transparent : textColor.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        lang.translate(sectionKeys[index]),
                        style: GoogleFonts.outfit(
                          color: isSelected ? const Color(0xFF131313) : textColor.withValues(alpha: 0.6),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            if (_isFiltered) const SizedBox(height: 16),
            if (!_isFiltered) const SizedBox(height: 24),

            // [3] Campaigns List (Dynamic)
            Expanded(
              child: RefreshIndicator(
                color: primaryBrand,
                onRefresh: () async {
                   await Future.wait([
                     context.read<CampaignProvider>().fetchAllCampaigns(),
                     context.read<BusinessProvider>().fetchMyFirms(),
                     context.read<BusinessProvider>().fetchExploreFirms(),
                   ]);
                },
                child: Consumer2<CampaignProvider, BusinessProvider>(
                  builder: (context, campProvider, bizProvider, child) {
                  // 1. Get All Campaigns
                  var campaigns = campProvider.allCampaigns;
                  
                  // 2. Prepare Business Lookup Map (Combine MyFirms + ExploreFirms)
                  final allFirms = [...bizProvider.myFirms, ...bizProvider.exploreFirms];
                  final firmMap = <String, dynamic>{};
                  
                  for (var f in allFirms) {
                    final id1 = f['_id']?.toString();
                    final id2 = f['id']?.toString();
                    if (id1 != null) firmMap[id1] = f;
                    if (id2 != null) firmMap[id2] = f;
                  }

                  // 3. Filter by Tab (Only if not filtered by firm)
                  if (!_isFiltered) {
                    if (_selectedTabIndex == 1) { // Cüzdandakiler
                      campaigns = campaigns.where((c) => bizProvider.isFirmInWallet(c.businessId)).toList();
                    } else if (_selectedTabIndex == 2) { // Diğerleri
                      campaigns = campaigns.where((c) => !bizProvider.isFirmInWallet(c.businessId)).toList();
                    }
                  } else {
                    // Filter by specific firm
                    campaigns = campaigns.where((c) => c.businessId == widget.firmId).toList();
                  }

                  // 4. Filter by Search (Only if not filtered by firm)
                  if (!_isFiltered) {
                    final query = _searchController.text.toLowerCase();
                    if (query.isNotEmpty) {
                      campaigns = campaigns.where((c) {
                        final biz = firmMap[c.businessId];
                        final bizName = (biz?['companyName'] ?? '').toLowerCase();
                        final title = c.title.toLowerCase();
                        return title.contains(query) || bizName.contains(query);
                      }).toList();
                    }
                  }

                  if (campaigns.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _isFiltered 
                                ? "${widget.firmName ?? 'Bu kafe'} ${lang.translate('no_active_deals_firm')}"
                                : lang.translate('no_deals_found'), 
                            style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.4))
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: campaigns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      // Find business info
                      var biz = firmMap[campaign.businessId];
                      // Fallback dummy if not found
                      biz ??= {'companyName': widget.firmName ?? '...', 'cardColor': '#EE2C2C'};
                      
                      return _buildCampaignCard(context, campaign, biz);
                    },
                  );
                },
              ),
            ), // Close RefreshIndicator
          ),   // Close Expanded
          ],
        ),
      ),
    );
  }


  Widget _buildCampaignCard(BuildContext context, CampaignModel campaign, dynamic biz) {
    final brandName = biz['companyName'] ?? (widget.firmName ?? '...');
    final rawLogo = biz['logo'] ?? biz['image'];
    
    final lang = context.read<LanguageProvider>();
    return GestureDetector(
      onTap: () => context.push('/campaign-detail', extra: campaign),
      child: Container(
        height: 142,
        width: double.infinity,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFD7D7D7)),
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x14000000), 
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
                height: 128, 
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: const [
                    BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))
                  ],
                ),
                child: resolveImageUrl(campaign.headerImage) != null
                    ? Image.network(
                        resolveImageUrl(campaign.headerImage)!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
                      )
                    : const SizedBox(),
              ),
            ),
            // Right Content
            Positioned(
              left: 159, 
              top: 15,
              right: 12, 
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business name and logo
                      Row(
                        children: [
                          Container(
                            width: 16, 
                            height: 16, 
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.white,
                              image: resolveImageUrl(rawLogo) != null ? DecorationImage(
                                image: NetworkImage(resolveImageUrl(rawLogo)!),
                                fit: BoxFit.cover,
                              ) : null,
                            ),
                            child: resolveImageUrl(rawLogo) == null 
                                ? const Icon(Icons.storefront_rounded, color: Colors.white, size: 12) 
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: AutoText(
                              brandName,
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
                  
                  // Campaign Tag / Discount Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // The pill badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
                          ]
                        ),
                        child: AutoText(
                          campaign.discountAmount > 0
                              ? '₺${campaign.discountAmount.toStringAsFixed(0)} ${lang.translate('discount_label')}'
                              : campaign.bundleName.isNotEmpty ? campaign.bundleName : lang.translate('campaign_label'),
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      
                      // Small round circle nav button
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9C06A),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0x33F9C06A), blurRadius: 6, offset: Offset(0, 3)),
                          ],
                        ),
                        child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF76410B), size: 20),
                      )
                    ],
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
