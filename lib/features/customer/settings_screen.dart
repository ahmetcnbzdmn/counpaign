import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/widgets/swipe_back_detector.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    const primaryBrand = Color(0xFFEE2C2C);

    // Initial Loading or No User
    if (auth.isLoading && user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // [1] Header Area
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
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
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
                            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                            onPressed: () => context.go('/home'),
                          ),
                        ),
                        Container(
                          width: 100,
                          height: 100,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryBrand, width: 2),
                            boxShadow: [
                              BoxShadow(color: primaryBrand.withOpacity(0.3), blurRadius: 20),
                            ]
                          ),
                          child: CircleAvatar(
                            backgroundImage: (user?.profileImage != null)
                                ? MemoryImage(base64Decode(user!.profileImage!)) as ImageProvider
                                : const NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=200'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Name
                    Text(user?.fullName ?? context.read<LanguageProvider>().translate('guest_user'), style: GoogleFonts.outfit(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(user?.email ?? "", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)),
                    
                    const SizedBox(height: 24),
                    
                    // Edit Button
                    ElevatedButton.icon(
                      onPressed: () => context.go('/settings/edit-profile'),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(context.watch<LanguageProvider>().translate('edit_profile')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textColor.withOpacity(0.05),
                        foregroundColor: textColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // [2] Settings Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Consumer<LanguageProvider>(
                  builder: (context, lang, child) {
                    return Column(
                      children: [
                         _buildSectionHeader(lang.translate('general'), textColor),
                         const SizedBox(height: 12),
                         
                         _buildSettingsTile(icon: Icons.notifications_none_rounded, title: lang.translate('notifications'), textColor: textColor, cardColor: cardColor, onTap: () => context.go('/settings/notifications')),
                         _buildSettingsTile(icon: Icons.store_mall_directory_rounded, title: lang.translate('added_shops'), textColor: textColor, cardColor: cardColor, onTap: () => context.go('/settings/my-firms')),
                         _buildSettingsTile(icon: Icons.history_rounded, title: lang.translate('order_history'), textColor: textColor, cardColor: cardColor, onTap: () => context.push('/settings/order-history')),
                         _buildSettingsTile(icon: Icons.star_outline_rounded, title: lang.translate('my_reviews'), textColor: textColor, cardColor: cardColor, onTap: () => context.push('/settings/my-reviews')),
                         
                         const SizedBox(height: 24),
                         
                         _buildSectionHeader(lang.translate('other'), textColor),
                         const SizedBox(height: 12),
                         _buildSettingsTile(icon: Icons.shield_outlined, title: lang.translate('privacy_security'), textColor: textColor, cardColor: cardColor, onTap: () {}),
                         _buildSettingsTile(icon: Icons.help_outline_rounded, title: lang.translate('help_support'), textColor: textColor, cardColor: cardColor, onTap: () {}),
                         
                         _buildSettingsTile(icon: Icons.settings_outlined, title: lang.translate('notification_settings'), textColor: textColor, cardColor: cardColor, onTap: () {}),
                         _buildSettingsTile(icon: Icons.thumb_up_alt_outlined, title: lang.translate('rate_app'), textColor: textColor, cardColor: cardColor, onTap: () {}),
                         
                         // Theme Toggle
                         AnimatedContainer(
                           duration: const Duration(milliseconds: 300),
                           margin: const EdgeInsets.only(bottom: 12),
                           decoration: BoxDecoration(
                             color: cardColor,
                             borderRadius: BorderRadius.circular(20),
                             border: Border.all(color: textColor.withOpacity(0.05)),
                           ),
                           child: ListTile(
                             contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                             leading: Container(
                               padding: const EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: textColor.withOpacity(0.1),
                                 shape: BoxShape.circle,
                               ),
                               child: Icon(isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: textColor, size: 20),
                             ),
                             title: Text(lang.translate('dark_mode'), style: GoogleFonts.outfit(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                             trailing: Switch.adaptive(
                               value: isDarkMode, 
                               onChanged: (val) => themeProvider.toggleTheme(val),
                               activeColor: const Color(0xFFEE2C2C),
                             ),
                           ),
                         ),
  
                         const SizedBox(height: 12),
  
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
                                       _buildLanguageOption(context, lang, 'tr', "Türkçe", "🇹🇷", textColor, primaryBrand),
                                       const SizedBox(height: 8),
                                       _buildLanguageOption(context, lang, 'en', "English", "🇬🇧", textColor, primaryBrand),
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
                         const SizedBox(height: 100),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(color: textColor.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
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
        border: Border.all(color: textColor.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? textColor).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? textColor, size: 20),
        ),
        title: Text(title, style: GoogleFonts.outfit(color: titleColor ?? textColor, fontSize: 16, fontWeight: FontWeight.w600)),
        trailing: showArrow 
            ? Icon(Icons.arrow_forward_ios_rounded, color: textColor.withOpacity(0.3), size: 16)
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
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
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

