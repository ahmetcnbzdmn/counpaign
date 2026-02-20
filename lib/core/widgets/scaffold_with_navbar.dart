import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


import 'package:shake/shake.dart';
import 'package:vibration/vibration.dart';

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
        // Use push for full screen scanner on shake
        if (await Vibration.hasVibrator() == true) {
          Vibration.vibrate(duration: 500);
        }
        if (mounted) context.push('/customer-scanner');
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
