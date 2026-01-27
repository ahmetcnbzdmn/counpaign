import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/participation_provider.dart';
import '../../core/providers/campaign_provider.dart';
import '../../core/models/campaign_model.dart';
import '../../core/widgets/swipe_back_detector.dart';

class ParticipationsScreen extends StatefulWidget {
  const ParticipationsScreen({super.key});

  @override
  State<ParticipationsScreen> createState() => _ParticipationsScreenState();
}

class _ParticipationsScreenState extends State<ParticipationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParticipationProvider>().fetchMyParticipations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;

    return SwipeBackDetector(
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textTheme.bodyLarge?.color),
            onPressed: () => context.pop(),
          ),
          title: Text(
            "Aktif Kampanyalarım",
            style: GoogleFonts.outfit(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Consumer2<ParticipationProvider, CampaignProvider>(
          builder: (context, partProvider, campProvider, child) {
            if (partProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final participations = partProvider.participations;

            if (participations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stars_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      "Henüz katıldığın bir kampanya yok.",
                      style: GoogleFonts.outfit(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.push('/campaigns'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEE2C2C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Kampanyaları Keşfet", style: GoogleFonts.outfit(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: participations.length,
              itemBuilder: (context, index) {
                final part = participations[index];
                // Try to find the campaign data
                final campaign = campProvider.allCampaigns.firstWhere(
                  (c) => c.id == part.campaignId,
                  orElse: () => CampaignModel(
                    id: part.campaignId,
                    businessId: '',
                    title: 'Yükleniyor...',
                    shortDescription: '',
                    content: '',
                    rewardType: '',
                    rewardValue: 0,
                    rewardValidityDays: 0,
                    icon: 'star_rounded',
                    isPromoted: false,
                    displayOrder: 0,
                    startDate: DateTime.now(),
                    endDate: DateTime.now(),
                    createdAt: DateTime.now(),
                  ),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEE2C2C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_parseCampaignIcon(campaign.icon), color: const Color(0xFFEE2C2C)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  campaign.title,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  part.isCompleted ? "Tamamlandı" : "Devam Ediyor",
                                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: part.targetProgress > 0 ? part.currentProgress / part.targetProgress : 0,
                          backgroundColor: Colors.grey.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEE2C2C)),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${part.currentProgress} / ${part.targetProgress}",
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            part.isCompleted ? "🤩 Hazır!" : "🚀 Hedefe Az Kaldı",
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
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
