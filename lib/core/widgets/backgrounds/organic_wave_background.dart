import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class OrganicWaveBackground extends StatelessWidget {
  final Widget child;

  const OrganicWaveBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Color
        Container(
          color: AppTheme.lightBackground, // Standardized Premium Cream
        ),
        
        // Custom Wave Painter
        Positioned.fill(
          child: CustomPaint(
            painter: _OrganicWavePainter(),
          ),
        ),
        
        // Content on top
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

class _OrganicWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.1) // Soft Orange
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = AppTheme.secondaryColor.withValues(alpha: 0.05) // Soft Muted Brown
      ..style = PaintingStyle.fill;

    // Top Wave (Orange Hue)
    final path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(size.width, 0);
    path1.lineTo(size.width, size.height * 0.15);
    path1.quadraticBezierTo(
      size.width * 0.75, size.height * 0.2, 
      size.width * 0.5, size.height * 0.15
    );
    path1.quadraticBezierTo(
      size.width * 0.25, size.height * 0.1, 
      0, size.height * 0.18
    );
    path1.close();
    canvas.drawPath(path1, paint1);

    // Bottom Wave (Brown Hue)
    final path2 = Path();
    path2.moveTo(0, size.height);
    path2.lineTo(size.width, size.height);
    path2.lineTo(size.width, size.height * 0.85);
    path2.quadraticBezierTo(
      size.width * 0.7, size.height * 0.95, 
      size.width * 0.4, size.height * 0.88
    );
    path2.quadraticBezierTo(
      size.width * 0.15, size.height * 0.82, 
      0, size.height * 0.9
    );
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
