import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/swipe_back_detector.dart';
import 'package:provider/provider.dart';
import '../../core/providers/campaign_provider.dart';
import '../../core/providers/business_provider.dart';
import '../../core/providers/participation_provider.dart'; // [NEW] Import
import '../../core/models/campaign_model.dart';
import '../../core/widgets/auto_text.dart';
import 'dart:convert';
import '../../core/providers/language_provider.dart';
import '../../core/utils/ui_utils.dart';

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
  
  // Tabs
  final List<String> _tabs = ["Tümü", "Cüzdandakiler", "Diğerleri"];
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
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    const primaryBrand = Color(0xFFEE2C2C);
    
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // [1] Header Area
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Row(
                     children: [
                       IconButton(
                         icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                         onPressed: () {
                           if (context.canPop()) {
                             context.pop();
                           } else {
                             context.go('/home');
                           }
                         },
                       ),
                       Text(
                         _isFiltered ? "${widget.firmName ?? 'Kafe'} ${lang.translate('deals')}" : "${lang.translate('deals')}", 
                         style: GoogleFonts.outfit(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)
                       ),
                     ],
                   ),
                ],
              ),
            ),
            
            // [Search Bar - Hide if filtered]
            if (!_isFiltered)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.outfit(color: textColor),
                decoration: InputDecoration(
                  hintText: lang.translate('search_deal_venue'),
                  hintStyle: GoogleFonts.outfit(color: textColor.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search_rounded, color: textColor.withOpacity(0.5)),
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
                  final sectionKeys = ['all', 'in_wallet', 'others'];
                  final isSelected = _selectedTabIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryBrand : cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? primaryBrand : textColor.withOpacity(0.1)),
                      ),
                      child: Text(
                        lang.translate(sectionKeys[index]),
                        style: TextStyle(
                          color: isSelected ? Colors.white : textColor.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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
                     context.read<ParticipationProvider>().fetchMyParticipations(),
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
                          Icon(Icons.search_off_rounded, size: 64, color: textColor.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            _isFiltered 
                                ? "${widget.firmName ?? 'Bu kafe'} ${lang.translate('no_active_deals_firm')}"
                                : lang.translate('no_deals_found'), 
                            style: GoogleFonts.outfit(color: textColor.withOpacity(0.4))
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
                      
                      return _buildCampaignCard(context, campaign, biz['companyName'] ?? (widget.firmName ?? '...'), _parseHexColor(biz['cardColor']));
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

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFEE2C2C);
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFEE2C2C);
    }
  }

  Widget _buildCampaignCard(BuildContext context, CampaignModel campaign, String brandName, Color brandColor) {
    final lang = context.read<LanguageProvider>();
    return GestureDetector(
      onTap: () => context.push('/campaign-detail', extra: campaign),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // [Background Image]
              Positioned.fill(
                child: resolveImageUrl(campaign.headerImage) != null 
                  ? Image.network(
                      resolveImageUrl(campaign.headerImage)!,
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context).cardColor, 
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.white24))
                      ),
                    )
                  : Container(color: Theme.of(context).cardColor),
              ),
              
              // [Gradient Overlay]
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.4, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
  
              // [Top Tags]
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront_rounded, color: brandColor, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              brandName,
                              style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Discount/Reward Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEE2C2C),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFEE2C2C).withOpacity(0.4), blurRadius: 10),
                        ]
                      ),
                      child: Text(
                        campaign.rewardType == 'points' ? "+${campaign.rewardValue} ${lang.translate('points_reward')}" : lang.translate('coffee_reward'),
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
  
              // [Bottom Details]
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoText(
                              campaign.title,
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.1),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            AutoText(
                              campaign.shortDescription,
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Action Button (Small)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
