import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


import 'package:shake/shake.dart';
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';
import '../providers/business_provider.dart';
import '../providers/campaign_provider.dart';
import '../providers/language_provider.dart';
import '../utils/ui_utils.dart';

class ScaffoldWithNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final Widget? body;

  const ScaffoldWithNavBar({
    required this.navigationShell,
    this.body,
    super.key,
  });

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  late ShakeDetector detector;

  @override
  void initState() {
    super.initState();
    detector = ShakeDetector.autoStart(
      onPhoneShake: (_) async {
        if (!mounted) return;
        
        // 1. Check Current Route (Only allow on Home and Business Detail)
        final router = GoRouter.of(context);
        final location = router.routerDelegate.currentConfiguration.last.matchedLocation;
        
        if (location != '/home' && !location.startsWith('/business-detail')) {
            return; // Ignore shake on other screens (Profile, Notifications, Explore, Scanner itself)
        }

        final bProvider = context.read<BusinessProvider>();
        final cProvider = context.read<CampaignProvider>();
        final lang = context.read<LanguageProvider>();
        
        String? firmId;
        String? firmName;
        Map<String, dynamic>? extraData;

        // 2. Resolve Firm Context based on Route
        if (location.startsWith('/business-detail')) {
            firmId = bProvider.currentViewedFirmId;
            firmName = bProvider.currentViewedFirmName ?? 'İşletme';
            extraData = bProvider.currentViewedFirmExtra;
        } else if (location == '/home') {
            final myFirms = bProvider.myFirms;
            final index = bProvider.homeSelectedFirmIndex;
            
            if (myFirms.isNotEmpty && index < myFirms.length) {
                final firm = myFirms[index];
                if (firm['companyName'] == lang.translate('wallet_empty')) return; // Empty wallet state
                
                firmId = firm['id'];
                firmName = firm['companyName'] ?? firm['name'] ?? 'İşletme';
                extraData = {
                  'expectedBusinessId': firmId,
                  'expectedBusinessName': firmName,
                  'expectedBusinessColor': firm['cardColor'] ?? firm['color'],
                  'expectedBusinessLogo': firm['logo'] ?? firm['image'] ?? firm['logoUrl'],
                  'currentStamps': firm['stamps'] ?? 0,
                  'targetStamps': firm['stampsTarget'] ?? 8,
                  'currentGifts': firm['giftsCount'] ?? 0,
                  'currentPoints': firm['points'] ?? '0',
                };
            } else {
                return; // User is looking at the "Add Kafe" card (+ card)
            }
        }

        // 3. Campaign Check
        if (firmId != null) {
          final firmCampaigns = cProvider.allCampaigns.where((c) => c.businessId == firmId).toList();
          
          if (firmCampaigns.isEmpty) {
            // [NO CAMPAIGNS] Block scanner and show dialog
            if (mounted) {
              showNoCampaignsDialog(context, firmName ?? 'İşletme');
            }
            return;
          }
        } else {
            return; // Safety guard
        }

        // 4. Allow QR Scanner with vibration
        if (await Vibration.hasVibrator() == true) {
          Vibration.vibrate(duration: 500);
        }
        if (mounted) {
           context.push('/customer-scanner', extra: extraData);
        }
      },
      minimumShakeCount: 1,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 2.7,
    );
  }

  @override
  void dispose() {
    detector.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For better immersion, we extend body behind the navbar
    return Scaffold(
      extendBody: true, 
      body: widget.body ?? widget.navigationShell,
      // bottomNavigationBar: _buildModernNavBar(context), // NavBar removed as requested
    );
  }

}
