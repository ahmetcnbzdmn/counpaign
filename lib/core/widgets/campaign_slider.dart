import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/campaign_model.dart';
import '../providers/language_provider.dart';
import 'auto_text.dart';

class CampaignSlider extends StatefulWidget {
  final List<CampaignModel> campaigns;
  final Color? iconColor;

  const CampaignSlider({
    super.key,
    required this.campaigns,
    this.iconColor,
  });

  @override
  State<CampaignSlider> createState() => _CampaignSliderState();
}

class _CampaignSliderState extends State<CampaignSlider> {
  late final PageController _pageController;
  late final Timer _timer;
  int _currentIndex = 0;
  static const int _initialPage = 1000;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _pageController = PageController(initialPage: _initialPage);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      if (widget.campaigns.length <= 1) return;

      _pageController.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.campaigns.isEmpty) return const SizedBox.shrink();
    
    final lang = context.watch<LanguageProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 64, // Standard height for the campaign box
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index % widget.campaigns.length;
              });
            },
            itemBuilder: (context, index) {
              final promoted = widget.campaigns[index % widget.campaigns.length];
              return GestureDetector(
                onTap: () => context.push('/campaign-detail', extra: promoted),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _parseCampaignIcon(promoted.icon),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AutoText(
                              promoted.title,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            AutoText(
                              promoted.shortDescription,
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.campaigns.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.campaigns.length, (index) {
              final isSelected = _currentIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isSelected ? 12 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  IconData _parseCampaignIcon(String name) {
    switch (name) {
      case 'stars_rounded':
        return Icons.stars_rounded;
      case 'local_cafe_rounded':
        return Icons.local_cafe_rounded;
      case 'icecream':
        return Icons.icecream_rounded;
      case 'local_offer_rounded':
        return Icons.local_offer_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}
