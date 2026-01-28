import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

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
    const primaryColor = Color(0xFFEE2C2C);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    primaryColor.withOpacity(0.05),
                    theme.scaffoldBackgroundColor,
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
                                color: primaryColor.withOpacity(0.1),
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
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page['description'],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
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
                        color: _currentPage == index ? primaryColor : primaryColor.withOpacity(0.2),
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
                        onPressed: () => context.push('/login', extra: {'pageIndex': 0}),
                        isPrimary: true,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 12),
                      _buildButton(
                        context,
                        text: 'Yeni Hesap Oluştur',
                        onPressed: () => context.push('/login', extra: {'pageIndex': 1}),
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
    
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? primaryColor : theme.cardColor,
          foregroundColor: isPrimary ? Colors.white : theme.textTheme.bodyLarge?.color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary ? BorderSide.none : BorderSide(color: theme.dividerColor),
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
