import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../core/services/storage_service.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Kahve Keyfini Katla!',
      'description': 'Her kahvende yeni bir ödül kazan, cüzdanını sevdiğin dükkanlarla doldur.',
      'icon': Icons.local_cafe_rounded,
    },
    {
      'title': 'Hızlı ve Kolay!',
      'description': 'QR kodu okut, saniyeler içinde puanlarını topla ve harca.',
      'icon': Icons.qr_code_scanner_rounded,
    },
    {
      'title': 'Özel Fırsatlar!',
      'description': 'Sadece sana özel kampanyaları keşfet, hiçbir fırsatı kaçırma.',
      'icon': Icons.stars_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF76410B);
    const bgColor = Color(0xFFEBEBEB);
    final textColor = const Color(0xFF131313);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Decor (Subtle Gradient)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withValues(alpha: 0.05),
                    bgColor,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Logo & Brand
                Text(
                  'Counpaign',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: -1,
                  ),
                ),
                
                // Slider
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                page['icon'],
                                size: 100,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              page['title'],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page['description'],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: textColor.withValues(alpha: 0.7),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? primaryColor : primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildButton(
                        context,
                        text: 'Giriş Yap',
                        onPressed: () async {
                          await StorageService().setHasSeenIntro(true);
                          if (context.mounted) context.push('/login', extra: {'pageIndex': 0});
                        },
                        isPrimary: true,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 12),
                      _buildButton(
                        context,
                        text: 'Yeni Hesap Oluştur',
                        onPressed: () async {
                          await StorageService().setHasSeenIntro(true);
                          if (context.mounted) context.push('/login', extra: {'pageIndex': 1});
                        },
                        isPrimary: false,
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    required Color primaryColor,
  }) {
    final theme = Theme.of(context);
    
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFA96307), Color(0xFF371E04)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3F7F7F7F),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF131313),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFF131313).withValues(alpha: 0.1)),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
