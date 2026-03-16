import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/language_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _passwordController = TextEditingController();
  
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    
    const bgColor = Color(0xFFEBEBEB);
    const cardColor = Colors.white;
    const textColor = Color(0xFF131313);
    const primaryBrand = Color(0xFF76410B);

    // Initial Loading or No User
    if (auth.isLoading && user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
        backgroundColor: bgColor,
        body: Column(
          children: [
            // [1] Header Area (Fixed - does not scroll)
            AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                  ]
                ),
                child: Column(
                  children: [
                    // Avatar
                    // Header Row with Back Button and Avatar
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/home');
                              }
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ImageProvider img;
                            if (user?.profileImage != null) {
                              img = MemoryImage(base64Decode(user!.profileImage!));
                            } else {
                              img = const AssetImage('assets/images/default_profile.png');
                            }
                            _showFullScreenPhoto(context, img);
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFF9C06A), width: 2),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFF9C06A).withValues(alpha: 0.3), blurRadius: 20),
                              ]
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              backgroundImage: (user?.profileImage != null)
                                  ? MemoryImage(base64Decode(user!.profileImage!)) as ImageProvider
                                  : const AssetImage('assets/images/default_profile.png'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Name
                    Text(user?.fullName ?? context.read<LanguageProvider>().translate('guest_user'), style: GoogleFonts.outfit(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(user?.email ?? "", style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14)),
                    
                    const SizedBox(height: 24),
                    
                    // Edit Button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9C06A), // Main yellow theme
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/edit-profile'),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text(
                          context.watch<LanguageProvider>().translate('edit_profile'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    )
                  ],
                ),
              ),

            // [2] Settings Actions (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Consumer<LanguageProvider>(
                    builder: (context, lang, child) {
                      return Column(
                      children: [
                         _buildSectionHeader(lang.translate('general'), textColor),
                         const SizedBox(height: 12),
                         
                         _buildSettingsTile(icon: Icons.store_mall_directory_rounded, title: lang.translate('added_shops'), textColor: textColor, cardColor: cardColor, onTap: () => context.push('/my-firms')),
                         _buildSettingsTile(icon: Icons.history_rounded, title: lang.translate('order_history'), textColor: textColor, cardColor: cardColor, onTap: () => context.push('/order-history')),
                         _buildSettingsTile(icon: Icons.star_outline_rounded, title: lang.translate('my_reviews'), textColor: textColor, cardColor: cardColor, onTap: () => context.push('/my-reviews')),
                         
                         const SizedBox(height: 24),
                         
                         _buildSectionHeader(lang.translate('other'), textColor),
                         const SizedBox(height: 12),
                         _buildSettingsTile(icon: Icons.shield_outlined, title: lang.translate('privacy_policy'), textColor: textColor, cardColor: cardColor, onTap: () => context.push('/privacy-security')),
                         _buildSettingsTile(icon: Icons.help_outline_rounded, title: lang.translate('help_support'), textColor: textColor, cardColor: cardColor, onTap: () => _showHelpSupportSheet(context, lang)),
                         
                         // Removed notification settings and rate app items as requested
                         
                         
                         // Removed Dark mode and notifications
  
                         // Language Option
                         _buildSettingsTile(
                             icon: Icons.language_rounded, 
                             title: lang.translate('language_option'), 
                             textColor: textColor, 
                             cardColor: cardColor, 
                             onTap: () {
                               showDialog(
                                 context: context,
                                 builder: (context) => AlertDialog(
                                   backgroundColor: cardColor,
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                   contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                                   title: Center(
                                     child: Text(
                                       lang.translate('select_language'), 
                                       style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)
                                     ),
                                   ),
                                   content: Column(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       _buildLanguageOption(context, lang, 'tr', "Türkçe", "🇹🇷", textColor, const Color(0xFFF9C06A)),
                                       const SizedBox(height: 8),
                                       _buildLanguageOption(context, lang, 'en', "English", "🇬🇧", textColor, const Color(0xFFF9C06A)),
                                     ],
                                   ),
                                 ),
                               );
                             }
                           ),

                         const SizedBox(height: 12),
  
                         // Logout
                         _buildSettingsTile(
                           icon: Icons.logout_rounded, 
                           title: lang.translate('logout'), 
                           titleColor: const Color(0xFFFF4C4C),
                           iconColor: const Color(0xFFFF4C4C),
                           textColor: textColor,
                           cardColor: cardColor,
                           showArrow: false,
                           onTap: () async {
                             // Reset theme to default (Light)
                             themeProvider.toggleTheme(false); 
                             await auth.logout();
                           }
                         ),
                         const SizedBox(height: 12),
  
                         const SizedBox(height: 100),
                      ],
                      );
                    }
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }


  void _showFullScreenPhoto(BuildContext context, ImageProvider imageProvider) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Stack(
                  children: [
                    Center(
                      child: Hero(
                        tag: 'profile_photo',
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      right: 20,
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 24),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHelpSupportSheet(BuildContext context, LanguageProvider lang) {
    const bgColor = Color(0xFFEBEBEB);
    const cardColor = Colors.white;
    const textColor = Color(0xFF131313);
    const yellow = Color(0xFFF9C06A);
    const deepBrown = Color(0xFF76410B);

    final contacts = [
      {
        'key': 'contact_support',
        'descKey': 'contact_support_desc',
        'icon': Icons.headset_mic_rounded,
        'iconBg': const Color(0xFFE8F4FD),
        'iconColor': const Color(0xFF2196F3),
        'contact': 'support@counpaign.com',
        'type': 'email',
      },
      {
        'key': 'contact_sales',
        'descKey': 'contact_sales_desc',
        'icon': Icons.storefront_rounded,
        'iconBg': const Color(0xFFFFF3E0),
        'iconColor': deepBrown,
        'contact': '05464135531',
        'type': 'phone',
      },
      {
        'key': 'contact_info',
        'descKey': 'contact_info_desc',
        'icon': Icons.info_outline_rounded,
        'iconBg': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF4CAF50),
        'contact': 'info@counpaign.com',
        'type': 'email',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: textColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 24),
              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: yellow.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: deepBrown, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.translate('help_support'),
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Text(
                        lang.translate('help_support_subtitle'),
                        style: GoogleFonts.outfit(fontSize: 13, color: textColor.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...contacts.map((c) {
                final icon = c['icon'] as IconData;
                final iconBg = c['iconBg'] as Color;
                final iconColor = c['iconColor'] as Color;
                final contact = c['contact'] as String;
                final type = c['type'] as String;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      splashFactory: NoSplash.splashFactory,
                      highlightColor: yellow.withValues(alpha: 0.08),
                      onTap: () async {
                        if (type == 'phone') {
                          final waMessage = lang.translate('whatsapp_sales_message');
                          final waUri = Uri.parse('https://wa.me/905464135531?text=${Uri.encodeComponent(waMessage)}');
                          if (await canLaunchUrl(waUri)) launchUrl(waUri, mode: LaunchMode.externalApplication);
                        } else {
                          // Try Gmail app first, fallback to default mail
                          final gmailUri = Uri.parse('googlegmail:///co?to=$contact');
                          if (await canLaunchUrl(gmailUri)) {
                            launchUrl(gmailUri, mode: LaunchMode.externalApplication);
                          } else {
                            final uri = Uri(scheme: 'mailto', path: contact);
                            if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                              child: Icon(icon, color: iconColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.translate(c['key'] as String),
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    lang.translate(c['descKey'] as String),
                                    style: GoogleFonts.outfit(fontSize: 12, color: textColor.withValues(alpha: 0.5), height: 1.4),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        type == 'phone' ? Icons.phone_rounded : Icons.mail_outline_rounded,
                                        size: 13,
                                        color: deepBrown.withValues(alpha: 0.7),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        type == 'phone' ? '+90 546 413 5531' : contact,
                                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: deepBrown),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textColor.withValues(alpha: 0.25)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon, 
    required String title, 
    Color? titleColor,
    Color? iconColor,
    bool showArrow = true,
    required Color textColor,
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? textColor).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? textColor, size: 20),
        ),
        title: Text(title, style: GoogleFonts.outfit(color: titleColor ?? textColor, fontSize: 16, fontWeight: FontWeight.w600)),
        trailing: showArrow 
            ? Icon(Icons.arrow_forward_ios_rounded, color: textColor.withValues(alpha: 0.3), size: 16)
            : null,
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, LanguageProvider lang, String code, String name, String flag, Color textColor, Color activeColor) {
    final isSelected = lang.locale.languageCode == code;
    return InkWell(
      onTap: () {
        lang.setLanguage(code);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: activeColor, width: 1.5) : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.outfit(
                  color: textColor, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: activeColor, size: 20),
          ],
        ),
      ),
    );
  }
}

