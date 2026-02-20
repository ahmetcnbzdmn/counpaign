import 'package:flutter/material.dart';

class TakeawayCupIcon extends StatelessWidget {
  final double size;
  final double fillLevel; // 0.0 to 1.0
  final Color cupColor;
  final Color liquidColor;

  const TakeawayCupIcon({
    super.key,
    required this.size,
    this.fillLevel = 0.0,
    this.cupColor = Colors.white,
    this.liquidColor = const Color(0xFF6F4E37), // Coffee Brown
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CupPainter(
        fillLevel: fillLevel.clamp(0.0, 1.0), 
        cupColor: cupColor,
        liquidColor: liquidColor
      ),
    );
  }
}

class _CupPainter extends CustomPainter {
  final double fillLevel;
  final Color cupColor;
  final Color liquidColor;

  _CupPainter({
    required this.fillLevel,
    required this.cupColor,
    required this.liquidColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dimensions
    final lidHeight = h * 0.15;
    final lidOverhang = w * 0.05;
    final cupTopWidth = w * 0.70; 
    final cupBottomWidth = w * 0.50;
    
    // Centers
    final centerX = w / 2;
    
    // 1. Define Cup Body Path
    final bodyPath = Path();
    bodyPath.moveTo(centerX - cupTopWidth / 2, lidHeight + 4); 
    bodyPath.lineTo(centerX + cupTopWidth / 2, lidHeight + 4);
    bodyPath.lineTo(centerX + cupBottomWidth / 2, h); 
    bodyPath.lineTo(centerX - cupBottomWidth / 2, h);
    bodyPath.close();

    // 2. Draw Cup Body (3D Effect)
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [
           cupColor.withValues(alpha: 0.9), // Left highlight
           Colors.grey.shade300,      // Shadow
           cupColor,                  // Right highlight
        ],
        stops: const [0.1, 0.5, 0.9],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(bodyPath, bodyPaint);

    // 3. Draw Liquid (Clipped to Body)
    if (fillLevel > 0) {
      canvas.save();
      canvas.clipPath(bodyPath);

      // Liquid Height relative to CUP BODY (not total height)
      final bodyHeight = h - (lidHeight + 4);
      final liquidTop = h - (bodyHeight * fillLevel);

      final liquidRect = Rect.fromLTRB(0, liquidTop, w, h);
      final liquidPaint = Paint()..color = liquidColor;
      
      canvas.drawRect(liquidRect, liquidPaint);
      
      // Top Surface of Liquid (Elliptical) if not full
      if (fillLevel < 1.0) {
         // Optional detail
      }
      
      canvas.restore();
    }

    // 4. Draw Lid (3D Effect)
    final lidPath = Path();
    // Top surface
    lidPath.moveTo(centerX - cupTopWidth / 2 + lidOverhang, 0); 
    lidPath.lineTo(centerX + cupTopWidth / 2 - lidOverhang, 0);
    // Bevel
    lidPath.lineTo(centerX + cupTopWidth / 2 + lidOverhang, lidHeight);
    lidPath.lineTo(centerX - cupTopWidth / 2 - lidOverhang, lidHeight);
    lidPath.close();

    final lidPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white,
          Colors.grey.shade300,
          Colors.white,
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, lidHeight));

    canvas.drawPath(lidPath, lidPaint);
    
    // Lid Shadow / Line at bottom of lid
    final lidLinePaint = Paint()
       ..color = Colors.grey.withValues(alpha: 0.3)
       ..style = PaintingStyle.stroke
       ..strokeWidth = 1;
    canvas.drawPath(lidPath, lidLinePaint);
  }

  @override
  bool shouldRepaint(covariant _CupPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel || 
           oldDelegate.cupColor != cupColor;
  }
}
