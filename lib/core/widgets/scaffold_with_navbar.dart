import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:counpaign/core/widgets/design_system/glass_card.dart';
import 'package:flutter/services.dart';

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
        if (await Vibration.hasVibrator() ?? false) {
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

  Widget _buildModernNavBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), // Float from bottom
      child: GlassCard(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        borderRadius: 24,
        color: isDark 
            ? const Color(0xFF1E293B).withOpacity(0.85) 
            : Colors.white.withOpacity(0.85),
        child: Material(
          type: MaterialType.transparency,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: widget.navigationShell.currentIndex,
                onTap: () => _onTap(context, 0),
              ),
               _NavBarItem(
                icon: Icons.local_offer_rounded,
                label: 'Kampanya',
                index: 1,
                currentIndex: widget.navigationShell.currentIndex,
                onTap: () => _onTap(context, 1),
              ),
               // Highlighted QR Button
               _NavBarItem(
                icon: Icons.qr_code_scanner_rounded,
                label: '',
                index: 2,
                currentIndex: widget.navigationShell.currentIndex,
                isSpecial: true,
                onTap: () => _onTap(context, 2),
              ),
               _NavBarItem(
                icon: Icons.map_rounded,
                label: 'Harita',
                index: 3,
                currentIndex: widget.navigationShell.currentIndex,
                onTap: () => _onTap(context, 3),
              ),
               _NavBarItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                index: 4,
                currentIndex: widget.navigationShell.currentIndex,
                onTap: () => _onTap(context, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    if (index == 2) {
      context.push('/customer-scanner');
      return;
    }
    
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;
  final bool isSpecial;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final theme = Theme.of(context);
    final color = isSelected 
        ? theme.primaryColor 
        : theme.iconTheme.color?.withOpacity(0.5) ?? Colors.grey;

    if (isSpecial) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.qr_code_2, color: Colors.white, size: 28),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
