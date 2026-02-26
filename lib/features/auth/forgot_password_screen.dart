import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/ui_utils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _resetPassword() async {
    if (_emailController.text.isEmpty) {
      showCustomPopup(context, message: 'Lütfen e-posta adresinizi girin.', type: PopupType.error);
      return;
    }

    // Email validation regex (basic)
    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(_emailController.text)) {
      showCustomPopup(context, message: 'Lütfen geçerli bir e-posta adresi girin.', type: PopupType.error);
      return;
    }

    setState(() => _isLoading = true);
    
    // Dismiss keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      
      if (mounted) {
        showCustomPopup(
          context, 
          message: 'Sıfırlama bağlantısı e-posta adresinize gönderildi.', 
          type: PopupType.success
        );
        // Clean feedback loop: Allow user to go back to login after short delay or manually
        Future.delayed(const Duration(seconds: 2), () {
           if (mounted) context.pop();
        });
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Bir hata oluştu.';
      if (e.code == 'user-not-found') {
        message = 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
      } else if (e.code == 'invalid-email') {
        message = 'Geçersiz e-posta adresi.';
      }
      if (mounted) {
        showCustomPopup(context, message: message, type: PopupType.error);
      }
    } catch (e) {
      if (mounted) {
        showCustomPopup(context, message: 'Bağlantı hatası.', type: PopupType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = const Color(0xFF131313);
    final cardColor = Colors.white;
    const primaryBrand = Color(0xFF76410B);
    final bgColor = const Color(0xFFEBEBEB);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: textColor),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Header with Logo
                Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo.png', // Since they recently changed to app_logo in another task
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Image.asset(
                            'assets/images/splash_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (c, o, s) => Icon(Icons.lock_reset_rounded, size: 60, color: primaryBrand),
                          ),
                        ),
                      ),
                    ),
                ),
                const SizedBox(height: 32),
                
                Text(
                  'Şifremi\nUnuttum?',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hesabınıza kayıtlı e-posta adresinizi girin. Size şifrenizi sıfırlamanız için bir bağlantı göndereceğiz.',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: textColor.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Input
                Container(
                   decoration: BoxDecoration(
                     color: cardColor,
                     borderRadius: BorderRadius.circular(16),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withValues(alpha: 0.05),
                         blurRadius: 10,
                         offset: const Offset(0, 4),
                       )
                     ]
                   ),
                   child: TextField(
                     controller: _emailController,
                     keyboardType: TextInputType.emailAddress,
                     style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                     cursorColor: primaryBrand,
                     decoration: InputDecoration(
                       hintText: 'E-posta Adresi',
                       hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
                       prefixIcon: Icon(Icons.mail_outline_rounded, color: textColor.withValues(alpha: 0.5)),
                       border: InputBorder.none,
                       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                     ),
                   ),
                 ),
                 
                 const SizedBox(height: 32),
                 
                 // Button
                 SizedBox(
                   width: double.infinity,
                   height: 56,
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
                       onPressed: _isLoading ? null : _resetPassword,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.transparent,
                         shadowColor: Colors.transparent,
                         foregroundColor: Colors.white,
                         elevation: 0,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                         textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                       ),
                       child: _isLoading 
                         ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                         : const Text('GÖNDER'),
                     ),
                   ),
                 ),
                 const SizedBox(height: 40), // Bottom spacing for scrolls
              ],
            ),
          ),
        ),
      ),
    );
  }
}
