import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/utils/ui_utils.dart';
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
    final isDarkMode = themeProvider.isDarkMode;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    
    final theme = Theme.of(context);
    final bgColor = const Color(0xFFEBEBEB);
    final cardColor = Colors.white;
    final textColor = const Color(0xFF131313);
    const primaryBrand = Color(0xFF76410B);

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
                            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/home');
                              }
                            },
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
                              BoxShadow(color: primaryBrand.withValues(alpha: 0.3), blurRadius: 20),
                            ]
                          ),
                          child: CircleAvatar(
                            backgroundImage: (user?.profileImage != null)
                                ? MemoryImage(base64Decode(user!.profileImage!)) as ImageProvider
                                : const AssetImage('assets/images/default_profile.png'),
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
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFA96307), Color(0xFF371E04)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/edit-profile'),
                        icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                        label: Text(context.watch<LanguageProvider>().translate('edit_profile'), style: const TextStyle(color: Colors.white)),
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
                         
                         _buildSettingsTile(icon: Icons.store_mall_directory_rounded, title: lang.translate('added_shops'), textColor: textColor, cardColor: cardColor, onTap: () => context.push('/my-firms')),
                         _buildSettingsTile(icon: Icons.history_rounded, title: lang.translate('order_history'), textColor: textColor, cardColor: cardColor, onTap: () => context.push('/order-history')),
                         _buildSettingsTile(icon: Icons.star_outline_rounded, title: lang.translate('my_reviews'), textColor: textColor, cardColor: cardColor, onTap: () => context.push('/my-reviews')),
                         
                         const SizedBox(height: 24),
                         
                         _buildSectionHeader(lang.translate('other'), textColor),
                         const SizedBox(height: 12),
                         _buildSettingsTile(icon: Icons.shield_outlined, title: "Gizlilik ve Güvenlik", textColor: textColor, cardColor: cardColor, onTap: () => context.push('/privacy-security')),
                         _buildSettingsTile(icon: Icons.help_outline_rounded, title: lang.translate('help_support'), textColor: textColor, cardColor: cardColor, onTap: () {}),
                         
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
                         const SizedBox(height: 12),
  
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

  void _showDeleteAccountDialog(BuildContext context, AuthProvider auth, Color cardColor, Color textColor, Color primaryBrand) {
    _passwordController.clear();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                const SizedBox(width: 8),
                Text(
                  "Hesabı Sil", 
                  style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20)
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hesabınızı silmek geri alınamaz bir işlemdir. Tüm puanlarınız, hediye geçmişiniz ve kişisel verileriniz kalıcı olarak silinecektir.\n\nİşlemi onaylamak için lütfen mevcut şifrenizi giriniz:",
                  style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.outfit(color: textColor, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Şifreniz",
                    hintStyle: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: textColor.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                child: Text("İPTAL", style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: isDeleting ? null : () async {
                  if (_passwordController.text.isEmpty) {
                    showCustomPopup(context, message: "Şifre girmelisiniz.", type: PopupType.error);
                    return;
                  }
                  
                  setState(() => isDeleting = true);
                  try {
                    await auth.deleteAccount(_passwordController.text);
                    if (context.mounted) {
                       Navigator.pop(dialogContext); // Close dialog
                       showCustomPopup(context, message: "Hesabınız başarıyla silindi.", type: PopupType.success);
                       // auth_provider handles unsetting the user, the router should auto direct to login since user is null.
                    }
                  } catch (e) {
                    if (context.mounted) {
                       setState(() => isDeleting = false);
                       String errMsg = e.toString();
                       if (e is DioException) {
                          errMsg = e.response?.data['error'] ?? "Silme işlemi başarısız.";
                       }
                       showCustomPopup(context, message: errMsg, type: PopupType.error);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isDeleting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("SİL", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
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

