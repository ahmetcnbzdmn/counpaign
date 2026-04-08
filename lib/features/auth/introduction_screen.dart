import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/guest_provider.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    final List<Map<String, dynamic>> pages = [
      {
        'title': lang.translate('intro_title_1'),
        'description': lang.translate('intro_desc_1'),
        'icon': Icons.local_cafe_rounded,
      },
      {
        'title': lang.translate('intro_title_2'),
        'description': lang.translate('intro_desc_2'),
        'icon': Icons.qr_code_scanner_rounded,
      },
      {
        'title': lang.translate('intro_title_3'),
        'description': lang.translate('intro_desc_3'),
        'icon': Icons.stars_rounded,
      },
    ];

    const primaryColor = Color(0xFFF9C06A);
    const bgColor = Color(0xFFFDFBF7);
    const textColor = Color(0xFF3E2723);

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
                    primaryColor.withValues(alpha: 0.08),
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
                    color: const Color(0xFF3E2723),
                    letterSpacing: -1,
                  ),
                ),

                // Slider
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                page['icon'],
                                size: 100,
                                color: const Color(0xFFD4940A),
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
                    pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? primaryColor : primaryColor.withValues(alpha: 0.3),
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
                        text: lang.translate('login_btn'),
                        onPressed: () async {
                          await StorageService().setHasSeenIntro(true);
                          if (context.mounted) context.push('/login', extra: {'pageIndex': 0});
                        },
                        isPrimary: true,
                      ),
                      const SizedBox(height: 12),
                      _buildButton(
                        context,
                        text: lang.translate('create_account_btn'),
                        onPressed: () async {
                          await StorageService().setHasSeenIntro(true);
                          if (context.mounted) context.push('/login', extra: {'pageIndex': 1});
                        },
                        isPrimary: false,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          await StorageService().setHasSeenIntro(true);
                          if (!context.mounted) return;
                          try {
                            final auth = context.read<AuthProvider>();
                            final guest = context.read<GuestProvider>();
                            await guest.startGuestSession();
                            auth.enterGuestMode();
                            if (context.mounted) context.go('/home');
                          } catch (_) {
                            final auth = context.read<AuthProvider>();
                            auth.enterGuestMode();
                            if (context.mounted) context.go('/home');
                          }
                        },
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              lang.translate('continue_as_guest'),
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor.withValues(alpha: 0.5),
                                decoration: TextDecoration.underline,
                                decorationColor: textColor.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
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
  }) {

    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF9C06A), Color(0xFFD4940A)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF9C06A).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
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
          foregroundColor: const Color(0xFF3E2723),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFFF9C06A).withValues(alpha: 0.4)),
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
