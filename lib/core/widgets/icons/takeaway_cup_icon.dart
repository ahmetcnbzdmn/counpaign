import 'package:flutter/material.dart';

class TakeawayCupIcon extends StatelessWidget {
  final Color color;
  final double size;

  const TakeawayCupIcon({
    super.key,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CupPainter(color: color),
    );
  }
}

class _CupPainter extends CustomPainter {
  final Color color;

  _CupPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    final w = size.width;
    final h = size.height;

    // Dimensions
    final lidHeight = h * 0.15;
    final lidOverhang = w * 0.05;
    final cupTopWidth = w * 0.65; // Narrower top
    final cupBottomWidth = w * 0.45; // Narrower bottom
    final cupHeight = h * 0.8;
    
    // Centers
    final centerX = w / 2;
    
    // Draw Lid
    // Top of lid (slightly narrower than rim)
    path.moveTo(centerX - cupTopWidth / 2 + lidOverhang, 0); 
    path.lineTo(centerX + cupTopWidth / 2 - lidOverhang, 0);
    // Rim of lid (widest part)
    path.lineTo(centerX + cupTopWidth / 2 + lidOverhang, lidHeight);
    path.lineTo(centerX - cupTopWidth / 2 - lidOverhang, lidHeight);
    path.close();

    // Draw Cup Body
    final bodyPath = Path();
    bodyPath.moveTo(centerX - cupTopWidth / 2, lidHeight + 2); // Start below lid
    bodyPath.lineTo(centerX + cupTopWidth / 2, lidHeight + 2);
    bodyPath.lineTo(centerX + cupBottomWidth / 2, h); // Taper to bottom
    bodyPath.lineTo(centerX - cupBottomWidth / 2, h);
    bodyPath.close();

    path.addPath(bodyPath, Offset.zero);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
