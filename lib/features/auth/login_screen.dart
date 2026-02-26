import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/ui_utils.dart';
import 'package:counpaign/core/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatefulWidget {
  final int initialPageIndex;
  const LoginScreen({super.key, this.initialPageIndex = 0});

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
  late int _activePageIndex; // 0: Login, 1: Register

  @override
  void initState() {
    super.initState();
    _activePageIndex = widget.initialPageIndex;
  }
  String? _selectedGender;
  DateTime? _selectedBirthDate;

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

  void _showCupertinoDatePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text('İptal', style: TextStyle(color: Colors.red.shade400)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Tamam', style: TextStyle(color: Colors.blue)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Localizations.override(
                context: context,
                locale: const Locale('tr', 'TR'),
                child: Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    final maxDate = DateTime(now.year - 12, now.month, now.day);
                    final minDate = DateTime(1900);
                    
                    // Clamp initial date to be within range
                    DateTime initialDate = _selectedBirthDate ?? DateTime(now.year - 18, now.month, now.day);
                    if (initialDate.isAfter(maxDate)) {
                      initialDate = maxDate;
                    } else if (initialDate.isBefore(minDate)) {
                      initialDate = minDate;
                    }

                    return CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: initialDate,
                      maximumDate: maxDate,
                      minimumDate: minDate,
                      onDateTimeChanged: (date) {
                        setState(() => _selectedBirthDate = date);
                      },
                    );
                  }
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
             _passwordController.text.isEmpty || _selectedGender == null || _selectedBirthDate == null) {
             throw Exception("Lütfen tüm alanları doldurun.");
         }
         
         if (!_phoneController.text.startsWith('5')) {
           throw Exception("Telefon numarası 5 ile başlamalıdır.");
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
           name: _nameController.text, 
           surname: _surnameController.text,
           phoneNumber: _phoneController.text, 
           email: _emailController.text, 
           password: _passwordController.text,
           gender: _selectedGender,
           birthDate: _selectedBirthDate,
         );
         
         // SUCCESS: Send SMS & Navigate
         await auth.sendSmsVerification(_phoneController.text);
         
         if (mounted) {
           context.push('/verify-phone', extra: {
             'phoneNumber': _phoneController.text,
             'email': _emailController.text,
             'password': _passwordController.text,
             'name': _nameController.text,
             'surname': _surnameController.text,
           });
         }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        if (e is DioException) {
           errorMessage = e.response?.data['error'] ?? "Sunucu Hatası: ${e.message}";
        } else if (e is FirebaseAuthException) {
           switch (e.code) {
             case 'email-already-in-use':
               errorMessage = "Bu e-posta adresi zaten kullanımda.";
               break;
             case 'invalid-email':
               errorMessage = "Geçersiz e-posta adresi.";
               break;
             case 'weak-password':
               errorMessage = "Şifreniz çok zayıf.";
               break;
             case 'user-not-found':
               errorMessage = "Kullanıcı bulunamadı.";
               break;
             case 'wrong-password':
               errorMessage = "Şifre hatalı.";
               break;
             case 'invalid-credential':
               errorMessage = "Şifre veya kullanıcı bilgisi hatalı.";
               break;
             case 'user-disabled':
               errorMessage = "Bu hesap devre dışı bırakılmış.";
               break;
             default:
               errorMessage = "Giriş Hatası: ${e.message}";
           }
        } else if (e.toString().contains("DioException")) {
           errorMessage = "Kayıt Başarısız. Bilgilerinizi kontrol ediniz."; 
        }

        showCustomPopup(
          context,
          message: errorMessage,
          type: PopupType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    // Theme Colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Color bgColor = const Color(0xFFEBEBEB);
    final Color cardColor = Colors.white;
    final Color textColor = const Color(0xFF131313);
    final Color primaryBrand = const Color(0xFF76410B);
    
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
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.center,
                     children: [
                       // Application Logo with fade-in scale animation
                       TweenAnimationBuilder(
                         tween: Tween<double>(begin: 0.8, end: 1.0),
                         duration: const Duration(milliseconds: 600),
                         curve: Curves.easeOutBack,
                         builder: (context, scale, child) {
                           return Transform.scale(
                             scale: scale,
                             child: child,
                           );
                         },
                         child: Container(
                           height: 90,
                           width: 90,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             color: Colors.white,
                             boxShadow: [
                               BoxShadow(
                                 color: primaryBrand.withValues(alpha: 0.15),
                                 blurRadius: 20,
                                 offset: const Offset(0, 8),
                               ),
                             ],
                           ),
                           child: ClipOval(
                             child: Image.asset(
                               'assets/images/app_logo.png',
                               fit: BoxFit.cover,
                               errorBuilder: (c, o, s) => Image.asset(
                                 'assets/images/splash_logo.png',
                                 fit: BoxFit.cover,
                                 errorBuilder: (context, error, stackTrace) => Icon(
                                   Icons.local_cafe_rounded,
                                   size: 40,
                                   color: primaryBrand,
                                 ),
                               ),
                             ),
                           ),
                         ),
                       ),
                       
                       const SizedBox(height: 32),
                       
                       SizedBox(
                         height: 90, // Fixed height to prevent jitter
                         child: AnimatedSwitcher(
                           duration: const Duration(milliseconds: 400),
                           switchInCurve: Curves.easeOutCubic,
                           switchOutCurve: Curves.easeInCubic,
                           transitionBuilder: (Widget child, Animation<double> animation) {
                             return FadeTransition(opacity: animation, child: SlideTransition(
                               position: Tween<Offset>(
                                 begin: const Offset(0.0, 0.2),
                                 end: Offset.zero,
                               ).animate(animation),
                               child: child,
                             ));
                           },
                           child: Align(
                             alignment: Alignment.center,
                             key: ValueKey<int>(_activePageIndex),
                             child: Text(
                               _activePageIndex == 0 ? 'Hoşgeldin.\nGiriş Yap.' : 'Hesap\nOluştur.',
                               textAlign: TextAlign.center,
                               style: GoogleFonts.outfit(
                                 fontSize: 36,
                                 fontWeight: FontWeight.bold,
                                 height: 1.2,
                                 color: textColor,
                                 letterSpacing: -0.5,
                               ),
                             ),
                           ),
                         ),
                       ),
                     ],
                   ),
                   
                   const SizedBox(height: 32),
 
                   // [2] Form Area
                   Container(
                     decoration: BoxDecoration(
                       color: cardColor,
                       borderRadius: BorderRadius.circular(32),
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
                           FilteringTextInputFormatter.allow(RegExp(r'^5[0-9]*')), // Only permit numbers starting with 5
                         ]
                       ),
                       const SizedBox(height: 16),

                       if (_activePageIndex == 1) ...[
                         _buildModernTextField(
                           controller: _emailController, 
                           hint: 'E-posta Adresi', 
                           icon: Icons.alternate_email_rounded,
                           keyboardType: TextInputType.emailAddress,
                         ),
                         const SizedBox(height: 16),
                         
                         // Gender Selection (Vertical)
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 16),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(16),
                           ),
                           child: DropdownButtonHideUnderline(
                             child: DropdownButton<String>(
                               value: _selectedGender,
                               hint: Text("Cinsiyet", style: TextStyle(color: textColor.withValues(alpha: 0.3), fontSize: 14)),
                               isExpanded: true,
                               icon: const Icon(Icons.keyboard_arrow_down_rounded),
                               items: [
                                 DropdownMenuItem(value: 'male', child: Text("Erkek", style: TextStyle(color: textColor))),
                                 DropdownMenuItem(value: 'female', child: Text("Kadın", style: TextStyle(color: textColor))),
                                 DropdownMenuItem(value: 'other', child: Text("Diğer", style: TextStyle(color: textColor))),
                               ],
                               onChanged: (val) => setState(() => _selectedGender = val),
                             ),
                           ),
                         ),
                         const SizedBox(height: 16),

                         // Birth Date Picker (iOS Style)
                         InkWell(
                           onTap: () => _showCupertinoDatePicker(context),
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(16),
                             ),
                             child: Row(
                               children: [
                                 Icon(Icons.calendar_today_rounded, size: 18, color: textColor.withValues(alpha: 0.5)),
                                 const SizedBox(width: 12),
                                 Expanded(
                                   child: Text(
                                     _selectedBirthDate == null 
                                         ? "Doğum Tarihi" 
                                         : "${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}",
                                     style: TextStyle(
                                       color: _selectedBirthDate == null ? textColor.withValues(alpha: 0.3) : textColor,
                                       fontSize: 14,
                                     ),
                                   ),
                                 ),
                                 Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textColor.withValues(alpha: 0.3)),
                               ],
                             ),
                           ),
                         ),
                         
                         const SizedBox(height: 8),
                         Padding(
                           padding: const EdgeInsets.only(left: 4),
                           child: Text(
                             "* Kayıt olduktan sonra doğum tarihini değiştiremezsiniz.",
                             style: TextStyle(color: primaryBrand.withValues(alpha: 0.8), fontSize: 11, fontStyle: FontStyle.italic),
                           ),
                         ),
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
                              onPressed: () => context.push('/forgot-password'),
                              child: Text("Parolamı Unuttum?", style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 13)),
                            ),
                         ),

                       const SizedBox(height: 32),

                       // MAIN ACTION BUTTON
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
                             onPressed: isLoading ? null : _submit,
                             style: ElevatedButton.styleFrom(
                               backgroundColor: Colors.transparent,
                               shadowColor: Colors.transparent,
                               foregroundColor: Colors.white,
                               elevation: 0,
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                               textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                             ),
                             child: isLoading 
                               ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                               : Text(_activePageIndex == 0 ? 'Giriş Yap' : 'Kayıt Ol'),
                           ),
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
                               color: textColor.withValues(alpha: 0.05),
                               borderRadius: BorderRadius.circular(30),
                             ),
                             child: Text(
                               _activePageIndex == 0 ? "Hesabın yok mu? Kayıt Ol" : "Zaten üye misin? Giriş Yap",
                               style: TextStyle(
                                 color: textColor.withValues(alpha: 0.5),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFF131313), fontWeight: FontWeight.w500),
        cursorColor: const Color(0xFF76410B),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: const Color(0xFF131313).withValues(alpha: 0.3)),
          prefixIcon: Icon(icon, color: const Color(0xFF131313).withValues(alpha: 0.54), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        inputFormatters: inputFormatters,
      ),
    );
  }
}
