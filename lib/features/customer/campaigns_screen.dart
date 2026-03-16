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

  void _onSearchChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFEBEBEB);
    const cardColor = Colors.white;
    const textColor = Color(0xFF131313);
    const yellow = Color(0xFFF9C06A);
    const deepBrown = Color(0xFF76410B);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── Premium Fixed Header ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
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
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
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
                      _isFiltered
                          ? (widget.firmName ?? lang.translate('deals'))
                          : lang.translate('deals'),
                      style: GoogleFonts.outfit(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    if (!_isFiltered) ...[
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
                  ],
                ),
              ],
            ),
          ),

          // ── Search + Tabs ─────────────────────────────────────────
          if (!_isFiltered) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.outfit(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: lang.translate('search_deal_venue'),
                    hintStyle: GoogleFonts.outfit(
                      color: textColor.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: textColor.withValues(alpha: 0.35),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  const sectionKeys = ['all', 'in_wallet', 'others'];
                  final isSelected = _selectedTabIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? yellow : cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [BoxShadow(color: yellow.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]
                            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Text(
                        lang.translate(sectionKeys[index]),
                        style: GoogleFonts.outfit(
                          color: isSelected ? deepBrown : textColor.withValues(alpha: 0.6),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 16),

          // ── Campaigns List ────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: yellow,
              onRefresh: () async {
                await Future.wait([
                  context.read<CampaignProvider>().fetchAllCampaigns(),
                  context.read<BusinessProvider>().fetchMyFirms(),
                  context.read<BusinessProvider>().fetchExploreFirms(),
                ]);
              },
              child: Consumer2<CampaignProvider, BusinessProvider>(
                builder: (context, campProvider, bizProvider, child) {
                  var campaigns = campProvider.allCampaigns;

                  final allFirms = [...bizProvider.myFirms, ...bizProvider.exploreFirms];
                  final firmMap = <String, dynamic>{};
                  for (var f in allFirms) {
                    final id1 = f['_id']?.toString();
                    final id2 = f['id']?.toString();
                    if (id1 != null) firmMap[id1] = f;
                    if (id2 != null) firmMap[id2] = f;
                  }

                  if (!_isFiltered) {
                    if (_selectedTabIndex == 1) {
                      campaigns = campaigns.where((c) => bizProvider.isFirmInWallet(c.businessId)).toList();
                    } else if (_selectedTabIndex == 2) {
                      campaigns = campaigns.where((c) => !bizProvider.isFirmInWallet(c.businessId)).toList();
                    }
                  } else {
                    campaigns = campaigns.where((c) => c.businessId == widget.firmId).toList();
                  }

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
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: yellow.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_offer_rounded, size: 48, color: yellow),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isFiltered
                                ? "${widget.firmName ?? ''} ${lang.translate('no_active_deals_firm')}"
                                : lang.translate('no_deals_found'),
                            style: GoogleFonts.outfit(
                              color: textColor.withValues(alpha: 0.45),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: campaigns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      var biz = firmMap[campaign.businessId];
                      biz ??= {'companyName': widget.firmName ?? '...', 'cardColor': '#EE2C2C'};
                      return _buildCampaignCard(
                        context, campaign, biz,
                        yellow: yellow,
                        deepBrown: deepBrown,
                        textColor: textColor,
                        cardColor: cardColor,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(
    BuildContext context,
    CampaignModel campaign,
    dynamic biz, {
    required Color yellow,
    required Color deepBrown,
    required Color textColor,
    required Color cardColor,
  }) {
    final brandName = biz['companyName'] ?? (widget.firmName ?? '...');
    final rawLogo = biz['logo'] ?? biz['image'];
    final lang = context.read<LanguageProvider>();
    final headerUrl = resolveImageUrl(campaign.headerImage);
    final logoUrl = resolveImageUrl(rawLogo);

    return GestureDetector(
      onTap: () => context.push('/campaign-detail', extra: campaign),
      child: Container(
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Image ───────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              child: headerUrl != null
                  ? Image.network(
                      headerUrl,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(yellow),
                    )
                  : _buildImagePlaceholder(yellow),
            ),

            // ── Content ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business row
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: yellow.withValues(alpha: 0.15),
                          image: logoUrl != null
                              ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
                              : null,
                        ),
                        child: logoUrl == null
                            ? Icon(Icons.storefront_rounded, color: deepBrown, size: 12)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        brandName,
                        style: GoogleFonts.outfit(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Campaign Title
                  AutoText(
                    campaign.title,
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (campaign.shortDescription.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    AutoText(
                      campaign.shortDescription,
                      style: GoogleFonts.outfit(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Bottom row: badge + arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: yellow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: yellow.withValues(alpha: 0.5)),
                        ),
                        child: AutoText(
                          campaign.discountAmount > 0
                              ? '₺${campaign.discountAmount.toStringAsFixed(0)} ${lang.translate('discount_label')}'
                              : campaign.bundleName.isNotEmpty
                                  ? campaign.bundleName
                                  : lang.translate('campaign_label'),
                          style: GoogleFonts.outfit(
                            color: deepBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(Color yellow) {
    return Container(
      height: 120,
      width: double.infinity,
      color: yellow.withValues(alpha: 0.12),
      child: const Center(
        child: Icon(Icons.local_offer_rounded, color: Color(0xFFF9C06A), size: 40),
      ),
    );
  }
}
