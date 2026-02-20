import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(milliseconds: 3000), // Total 3 seconds
       vsync: this,
    );

    // Sequence: Enter from Left -> Stay -> Exit to Right
    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(-2.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35, // 35% of time for entry
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: Offset.zero),
        weight: 30, // 30% of time stay
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: const Offset(5.0, 0.0))
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 35, // 35% of time for exit
      ),
    ]).animate(_controller);

    _controller.forward();

    // Navigate after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
           context.go('/home'); 
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Background Decor: Full Pattern of Small Cups (Optimized)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CupPatternPainter(
                    // "Kırmızı bi tık daha açık olsun" - Using a lighter, softer red
                    color: const Color(0xFFFF5252), 
                    animationValue: _controller.value, 
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // Centered Logo with Animation (Restored)
          Center(
             child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEE2C2C).withValues(alpha: 0.2), 
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        )
                      ]
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.asset(
                        'assets/images/splash_logo.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Optimized CustomPainter for drawing hundreds of cups efficiently
class _CupPatternPainter extends CustomPainter {
  final Color color;
  final double animationValue;

  _CupPatternPainter({required this.color, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const crossAxisCount = 12;
    final spacing = size.width / crossAxisCount;
    // "Bardaklar birbirine değmesin ama büyük olsun"
    final iconSize = spacing * 0.75; 
    
    final rows = (size.height / spacing).ceil();

    final cupPath = _createCupPath(iconSize);
    
    final angle = animationValue * 2 * 3.14159;

    for (int col = -1; col < crossAxisCount + 1; col++) { // Extra columns for stagger
      for (int row = 0; row < rows; row++) {
        double x = col * spacing + spacing / 2;
        final y = row * spacing + spacing / 2;

        // "Kaldırım örüntüsü" - Stagger every other row
        if (row % 2 != 0) {
          x += spacing / 2;
        }

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angle);
        canvas.translate(-iconSize / 2, -iconSize / 2);
        canvas.drawPath(cupPath, paint);
        canvas.restore();
      }
    }
  }

  Path _createCupPath(double size) {
    final path = Path();
    final w = size;
    final h = size;

    // Dimensions (copied from TakeawayCupIcon)
    final lidHeight = h * 0.15;
    final lidOverhang = w * 0.05;
    final cupTopWidth = w * 0.65;
    final cupBottomWidth = w * 0.45;
    
    final centerX = w / 2;
    
    // Draw Lid
    path.moveTo(centerX - cupTopWidth / 2 + lidOverhang, 0); 
    path.lineTo(centerX + cupTopWidth / 2 - lidOverhang, 0);
    path.lineTo(centerX + cupTopWidth / 2 + lidOverhang, lidHeight);
    path.lineTo(centerX - cupTopWidth / 2 - lidOverhang, lidHeight);
    path.close();

    // Draw Cup Body
    final bodyPath = Path();
    bodyPath.moveTo(centerX - cupTopWidth / 2, lidHeight + 2);
    bodyPath.lineTo(centerX + cupTopWidth / 2, lidHeight + 2);
    bodyPath.lineTo(centerX + cupBottomWidth / 2, h);
    bodyPath.lineTo(centerX - cupBottomWidth / 2, h);
    bodyPath.close();

    path.addPath(bodyPath, Offset.zero);
    return path;
  }

  @override
  bool shouldRepaint(covariant _CupPatternPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}
