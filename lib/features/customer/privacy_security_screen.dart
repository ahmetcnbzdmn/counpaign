import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_theme.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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
                  obscureText: true, // Hides input
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

  Widget _buildTile({
    required IconData icon, 
    required String title, 
    Color? titleColor,
    Color? iconColor,
    bool showArrow = true,
    required Color textColor,
    required Color cardColor,
    VoidCallback? onTap,
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

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = context.read<AuthProvider>();
    
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    const primaryBrand = Color(0xFF76410B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Gizlilik ve Güvenlik", 
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)
        ),
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Change Password
            _buildTile(
              icon: Icons.vpn_key_rounded, 
              title: "Şifre Değiştir", 
              textColor: textColor, 
              cardColor: cardColor, 
              showArrow: false,
              onTap: null,
            ),
            
            // Privacy Policy
            _buildTile(
              icon: Icons.description_outlined, 
              title: "Gizlilik Sözleşmesi", 
              textColor: textColor, 
              cardColor: cardColor, 
              showArrow: false,
              onTap: null,
            ),

            const SizedBox(height: 32),

            // Delete Account
            _buildTile(
              icon: Icons.delete_forever_rounded, 
              title: "Hesabı Sil", 
              titleColor: const Color.fromARGB(255, 175, 41, 41),
              iconColor: const Color.fromARGB(255, 175, 41, 41),
              textColor: textColor,
              cardColor: cardColor,
              showArrow: false,
              onTap: () {
                _showDeleteAccountDialog(context, auth, cardColor, textColor, primaryBrand);
              }
            ),
          ],
        ),
      ),
    );
  }
}
