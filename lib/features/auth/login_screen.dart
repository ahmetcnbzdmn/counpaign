import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:counpaign/core/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Input Controllers
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State
  int _activePageIndex = 0; // 0: Login, 1: Register

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final auth = context.read<AuthProvider>();
    
    // Haptic Feedback for premium feel
    HapticFeedback.mediumImpact();

    try {
      if (_activePageIndex == 0) { // Login
         if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
           throw Exception("Lütfen tüm alanları doldurun.");
         }
         await auth.login(_phoneController.text, _passwordController.text);
      } else { // Register
         if (_nameController.text.isEmpty || _surnameController.text.isEmpty || 
             _phoneController.text.isEmpty || _emailController.text.isEmpty || 
             _passwordController.text.isEmpty) {
             throw Exception("Lütfen tüm alanları doldurun.");
         }
         
         // Email Validation
         final emailRegex = RegExp(r"^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$");
         if (!emailRegex.hasMatch(_emailController.text)) {
           throw Exception("Lütfen geçerli bir e-posta adresi giriniz.");
         }

         if (_passwordController.text != _confirmPasswordController.text) {
           throw Exception("Şifreler eşleşmiyor.");
         }
         
         await auth.register(
           _nameController.text, 
           _surnameController.text,
           _phoneController.text, 
           _emailController.text, 
           _passwordController.text
        );
      }
    } catch (e) {
      if (mounted) {
        // DEBUG MODE: Show RAW error to understand what's happening
        String errorMessage = e.toString();
        
        if (e.toString().contains("DioException")) {
           // Try to show the server response body directly
           // We can't access e.response.data cleanly in catch(Object e) without casting, 
           // but we can suggest the user to look at the console or try to print it if possible.
           // Let's rely on AuthService printing it to console as well.
           errorMessage = "Sunucu Hatası (Detay): $e";
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("HATA: $errorMessage", maxLines: 4), // Allow more lines
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    // Theme Colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Color bgColor = theme.scaffoldBackgroundColor;
    final Color cardColor = theme.cardColor;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E2329);
    final Color primaryBrand = theme.primaryColor;
    
    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
        child: SingleChildScrollView(
          child: Container(
             constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 80,
             ),
             padding: const EdgeInsets.symmetric(horizontal: 24.0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 const SizedBox(height: 60),
                 
                   // [1] Header Area
                   AnimatedSwitcher(
                     duration: const Duration(milliseconds: 300),
                     child: Text(
                       _activePageIndex == 0 ? 'Hoşgeldin.\nGiriş Yap.' : 'Hesap\nOluştur.',
                       key: ValueKey<int>(_activePageIndex),
                       style: GoogleFonts.outfit(
                         fontSize: 40,
                         fontWeight: FontWeight.bold,
                         height: 1.1,
                         color: textColor,
                       ),
                     ),
                   ),
                   
                   const SizedBox(height: 48),
 
                   // [2] Form Area
                   Container(
                     decoration: BoxDecoration(
                       color: cardColor,
                       borderRadius: BorderRadius.circular(32),
                       boxShadow: [
                         BoxShadow(
                             color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                             blurRadius: 20, 
                             offset: const Offset(0, 10)
                         )
                       ]
                     ),
                   padding: const EdgeInsets.all(24),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       
                       // REGISTER FIELDS
                       if (_activePageIndex == 1) ...[
                         Row(
                           children: [
                             Expanded(child: _buildModernTextField(controller: _nameController, hint: 'Ad', icon: Icons.person)),
                             const SizedBox(width: 12),
                             Expanded(child: _buildModernTextField(controller: _surnameController, hint: 'Soyad', icon: Icons.person_outline)),
                           ],
                         ),
                         const SizedBox(height: 16),
                       ],
                       
                       // LOGIN & REGISTER FIELDS (Common)
                       // Phone Input (Primary Identifier)
                       _buildModernTextField(
                         controller: _phoneController, 
                         hint: '5XX XXX XX XX', 
                         icon: Icons.phone_android_rounded,
                         keyboardType: TextInputType.phone,
                         inputFormatters: [
                           FilteringTextInputFormatter.digitsOnly,
                           LengthLimitingTextInputFormatter(10),
                           FilteringTextInputFormatter.deny(RegExp(r'^0+')), // Deny starting with 0
                         ]
                       ),
                       const SizedBox(height: 16),

                       if (_activePageIndex == 1) ...[
                         _buildModernTextField(controller: _emailController, hint: 'E-posta', icon: Icons.alternate_email, keyboardType: TextInputType.emailAddress),
                         const SizedBox(height: 16),
                       ],

                       _buildModernTextField(controller: _passwordController, hint: 'Şifre', icon: Icons.lock_outline_rounded, isPassword: true),
                       
                       if (_activePageIndex == 1) ...[
                         const SizedBox(height: 16),
                         _buildModernTextField(controller: _confirmPasswordController, hint: 'Şifreyi Doğrula', icon: Icons.lock_reset_rounded, isPassword: true),
                       ],
                       
                       const SizedBox(height: 8),
                       
                       // Forgot Password
                       if (_activePageIndex == 0)
                         Align(
                           alignment: Alignment.centerRight,
                           child: TextButton(
                             onPressed: () {},
                             child: Text("Parolamı Unuttum?", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13)),
                           ),
                         ),

                       const SizedBox(height: 32),

                       // MAIN ACTION BUTTON
                       SizedBox(
                         width: double.infinity,
                         height: 56,
                         child: ElevatedButton(
                           onPressed: isLoading ? null : _submit,
                           style: ElevatedButton.styleFrom(
                             backgroundColor: primaryBrand,
                             foregroundColor: Colors.white, // Button Text is always White on Green
                             elevation: 0,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                             textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                           ),
                           child: isLoading 
                             ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                             : Text(_activePageIndex == 0 ? 'Giriş Yap' : 'Kayıt Ol'),
                         ),
                       ),

                       const SizedBox(height: 24),

                       // Toggle Login/Register
                       Center(
                         child: GestureDetector(
                           onTap: () {
                             setState(() {
                               _activePageIndex = _activePageIndex == 0 ? 1 : 0;
                             });
                           },
                           child: Container(
                             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                             decoration: BoxDecoration(
                               color: textColor.withOpacity(0.05),
                               borderRadius: BorderRadius.circular(30),
                             ),
                             child: Text(
                               _activePageIndex == 0 ? "Hesabın yok mu? Kayıt Ol" : "Zaten üye misin? Giriş Yap",
                               style: TextStyle(
                                 color: textColor.withOpacity(0.7),
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
                 
                 const SizedBox(height: 32),
               ],
             ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2329) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500),
        cursorColor: Theme.of(context).primaryColor,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.3)),
          prefixIcon: Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.54), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        inputFormatters: inputFormatters,
      ),
    );
  }
}
