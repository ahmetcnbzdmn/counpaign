import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/campaign_model.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/swipe_back_detector.dart';

import '../../core/widgets/auto_text.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/providers/language_provider.dart';

class CampaignDetailScreen extends StatelessWidget {
  final CampaignModel campaign;

  const CampaignDetailScreen({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = theme.cardColor;
    const accentColor = Color(0xFFEE2C2C);

    return SwipeBackDetector(
      child: Scaffold(
        backgroundColor: bgColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, bgColor, accentColor),
            _buildContent(context, bgColor, textColor, cardColor, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Color bgColor, Color accentColor) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      stretch: true,
      backgroundColor: bgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            campaign.headerImage != null
                ? Image.network(resolveImageUrl(campaign.headerImage)!, fit: BoxFit.cover)
                : Container(color: accentColor),
            // Gradient to help transition
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.2)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // CURVE ON TOP: This stays at the bottom of the App Bar and OVER the image
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: Container(
          height: 30,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color bgColor, Color textColor, Color cardColor, Color accentColor) {
    return SliverToBoxAdapter(
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 120), // 20px air from curve bottom
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [NEW] Business Name Box (Top Left)
            FutureBuilder<Map<String, dynamic>?>(
              future: context.read<ApiService>().getBusinessById(campaign.businessId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final businessName = snapshot.data!['companyName'] ?? 'İşletme';
                final color = (snapshot.data!['cardColor'] != null) 
                    ? Color(int.parse(snapshot.data!['cardColor'].replaceAll('#', '0xFF')))
                    : accentColor;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    businessName,
                    style: GoogleFonts.outfit(
                      color: color,
                      fontWeight: FontWeight.bold, 
                      fontSize: 13
                    ),
                  ),
                );
              },
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(30), // Radius 30
                    border: Border.all(color: accentColor.withValues(alpha: 0.12), width: 1.5),
                  ),
                  child: Icon(_parseCampaignIcon(campaign.icon), color: accentColor, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoText(
                        campaign.title,
                        style: GoogleFonts.outfit(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold, 
                          color: textColor, 
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AutoText(
                        campaign.shortDescription,
                        style: GoogleFonts.outfit(fontSize: 14, color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
                  const SizedBox(height: 40),
                  
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: textColor.withValues(alpha: 0.05), width: 1),
                    ),
                    child: Row(
                      children: [
                        if (campaign.menuItems.isNotEmpty) ...[
                          _buildInfoItem(
                            context,
                            Icons.local_offer_rounded,
                            campaign.bundleName.isNotEmpty ? campaign.bundleName : campaign.menuItems.map((e) => e.productName).join(' + '),
                            // Price Display Logic
                            null, // Passing null as value to use custom child
                            customValueWidget: Row(
                              children: [
                                if (campaign.discountAmount > 0) ...[
                                  Text(
                                    '₺${campaign.totalPrice.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: textColor.withValues(alpha: 0.5),
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₺${campaign.discountedPrice.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      color: accentColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ] else
                                  Text(
                                    '₺${campaign.totalPrice.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            accentColor,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(width: 1, height: 40, color: textColor.withValues(alpha: 0.1)),
                          ),
                        ],
                        _buildInfoItem(
                          context,
                          Icons.calendar_today_rounded,
                          Provider.of<LanguageProvider>(context).translate('date_label'),
                          DateFormat('dd.MM.yyyy').format(campaign.endDate),
                          Colors.blueAccent,
                        ),
                      ],
                    ),
                  ),
              
              const SizedBox(height: 40),
              _buildSectionTitle(Provider.of<LanguageProvider>(context).translate('about_campaign')),
              const SizedBox(height: 12),
              AutoText(
                campaign.content,
                style: GoogleFonts.outfit(fontSize: 15, color: textColor.withValues(alpha: 0.7), height: 1.6),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(Provider.of<LanguageProvider>(context).translate('how_to_use')),
              const SizedBox(height: 12),
              _buildStepItem(1, Provider.of<LanguageProvider>(context).translate('step_1')),
              _buildStepItem(2, Provider.of<LanguageProvider>(context).translate('step_2')),
            ],
          ),
        ),
      );
  }

  Widget _buildSectionTitle(String title) {
    return AutoText(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildStepItem(int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$step.",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AutoText(
              text,
              style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label, String? value, Color color, {Widget? customValueWidget}) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(fontSize: 12, color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          customValueWidget ?? AutoText(
            value ?? '',
            style: GoogleFonts.outfit(fontSize: 15, color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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
}
