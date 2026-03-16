import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/ui_utils.dart';
import 'package:counpaign/core/providers/auth_provider.dart';
import 'package:counpaign/core/providers/language_provider.dart';
import 'package:go_router/go_router.dart';

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
  bool _acceptedAgreement = false;
  bool _acceptedKvkk = false;

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
                    child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('cancel'), style: TextStyle(color: Colors.red.shade400)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('ok'), style: const TextStyle(color: Colors.blue)),
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
    final lang = context.read<LanguageProvider>();

    // Haptic Feedback for premium feel
    HapticFeedback.mediumImpact();

    try {
      if (_activePageIndex == 0) { // Login
         if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
           throw Exception(lang.translate('fill_all_fields_msg'));
         }
         await auth.login(_phoneController.text, _passwordController.text);
      } else { // Register
         if (_nameController.text.isEmpty || _surnameController.text.isEmpty ||
             _phoneController.text.isEmpty || _emailController.text.isEmpty ||
             _passwordController.text.isEmpty || _selectedGender == null || _selectedBirthDate == null) {
             throw Exception(lang.translate('fill_all_fields_msg'));
         }

         if (!_phoneController.text.startsWith('5')) {
           throw Exception(lang.translate('phone_start_5_msg'));
         }

         // Email Validation
         final emailRegex = RegExp(r"^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$");
         if (!emailRegex.hasMatch(_emailController.text)) {
           throw Exception(lang.translate('invalid_email_msg'));
         }

         if (_passwordController.text != _confirmPasswordController.text) {
           throw Exception(lang.translate('passwords_dont_match_msg'));
         }

         if (!_acceptedAgreement || !_acceptedKvkk) {
           throw Exception(lang.translate('accept_agreements_msg'));
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
           final statusCode = e.response?.statusCode;
           if (statusCode == 401 || statusCode == 400) {
             errorMessage = lang.translate('invalid_credential');
           } else if (statusCode == 404) {
             errorMessage = lang.translate('user_not_found');
           } else if (statusCode == 403) {
             errorMessage = lang.translate('user_disabled');
           } else {
             errorMessage = lang.translate('server_error_prefix');
           }
        } else if (e is FirebaseAuthException) {
           switch (e.code) {
             case 'email-already-in-use':
               errorMessage = lang.translate('email_in_use');
               break;
             case 'invalid-email':
               errorMessage = lang.translate('invalid_email_firebase');
               break;
             case 'weak-password':
               errorMessage = lang.translate('weak_password');
               break;
             case 'user-not-found':
               errorMessage = lang.translate('user_not_found');
               break;
             case 'wrong-password':
               errorMessage = lang.translate('wrong_password');
               break;
             case 'invalid-credential':
               errorMessage = lang.translate('invalid_credential');
               break;
             case 'user-disabled':
               errorMessage = lang.translate('user_disabled');
               break;
             default:
               errorMessage = "${lang.translate('login_error_prefix')}: ${e.message}";
           }
        } else if (e.toString().contains("DioException")) {
           errorMessage = lang.translate('register_failed');
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
    final lang = context.watch<LanguageProvider>();
    // Theme Colors
    const Color bgColor = Color(0xFFEBEBEB);
    const Color cardColor = Colors.white;
    const Color textColor = Color(0xFF131313);
    const Color primaryBrand = Color(0xFF76410B);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _activePageIndex == 1 ? AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => setState(() => _activePageIndex = 0),
        ),
      ) : null,
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
               crossAxisAlignment: CrossAxisAlignment.center,
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
                               'assets/images/splash_logo.png',
                               fit: BoxFit.cover,
                               errorBuilder: (c, o, s) => Image.asset(
                                 'assets/images/splash_logo.png',
                                 fit: BoxFit.cover,
                                 errorBuilder: (context, error, stackTrace) => const Icon(
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
                       
                       AnimatedSwitcher(
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
                         child: Column(
                           key: ValueKey<int>(_activePageIndex),
                           crossAxisAlignment: CrossAxisAlignment.center,
                           children: [
                             Text(
                               _activePageIndex == 0
                                   ? lang.translate('login_title')
                                   : lang.translate('register_title'),
                               textAlign: TextAlign.center,
                               style: GoogleFonts.outfit(
                                 fontSize: 34,
                                 fontWeight: FontWeight.w800,
                                 height: 1.15,
                                 color: textColor,
                                 letterSpacing: -0.8,
                               ),
                             ),
                             const SizedBox(height: 6),
                             Text(
                               _activePageIndex == 0
                                   ? lang.translate('login_subtitle')
                                   : lang.translate('register_subtitle'),
                               textAlign: TextAlign.center,
                               style: GoogleFonts.outfit(
                                 fontSize: 15,
                                 fontWeight: FontWeight.w600,
                                 color: const Color(0xFFF9C06A),
                                 letterSpacing: 0.1,
                               ),
                             ),
                           ],
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
                             Expanded(child: _buildModernTextField(controller: _nameController, hint: lang.translate('name'), icon: Icons.person)),
                             const SizedBox(width: 12),
                             Expanded(child: _buildModernTextField(controller: _surnameController, hint: lang.translate('surname'), icon: Icons.person_outline)),
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
                           hint: lang.translate('email'),
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
                               hint: Text(lang.translate('gender'), style: TextStyle(color: textColor.withValues(alpha: 0.3), fontSize: 14)),
                               isExpanded: true,
                               icon: const Icon(Icons.keyboard_arrow_down_rounded),
                               items: [
                                 DropdownMenuItem(value: 'male', child: Text(lang.translate('male'))),
                                 DropdownMenuItem(value: 'female', child: Text(lang.translate('female'))),
                                 DropdownMenuItem(value: 'other', child: Text(lang.translate('other_gender'))),
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
                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                                         ? lang.translate('birth_date')
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
                             lang.translate('birth_date_note'),
                             style: TextStyle(color: const Color(0xFFF9C06A).withValues(alpha: 0.9), fontSize: 11, fontStyle: FontStyle.italic),
                           ),
                         ),
                         const SizedBox(height: 16),
                       ],

                       _buildModernTextField(controller: _passwordController, hint: lang.translate('password'), icon: Icons.lock_outline_rounded, isPassword: true),
                       
                       if (_activePageIndex == 1) ...[
                         const SizedBox(height: 16),
                         _buildModernTextField(controller: _confirmPasswordController, hint: lang.translate('confirm_password'), icon: Icons.lock_reset_rounded, isPassword: true),
                       ],
                       
                       const SizedBox(height: 8),
                       
                       // Forgot Password
                       if (_activePageIndex == 0)
                         Align(
                           alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: Text(lang.translate('forgot_password'), style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 13)),
                            ),
                         ),

                       // Agreement Checkboxes (Register only)
                       if (_activePageIndex == 1) ...[
                         const SizedBox(height: 16),
                         _buildAgreementCheckbox(
                           value: _acceptedAgreement,
                           onChanged: (v) => setState(() => _acceptedAgreement = v ?? false),
                           text: lang.translate('accept_agreement_text'),
                           textColor: textColor,
                         ),
                         const SizedBox(height: 8),
                         _buildAgreementCheckbox(
                           value: _acceptedKvkk,
                           onChanged: (v) => setState(() => _acceptedKvkk = v ?? false),
                           text: lang.translate('accept_kvkk_text'),
                           textColor: textColor,
                         ),
                       ],

                       const SizedBox(height: 32),

                       // MAIN ACTION BUTTON
                       SizedBox(
                         width: double.infinity,
                         height: 56,
                         child: Container(
                           decoration: BoxDecoration(
                             color: const Color(0xFFF9C06A),
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
                               : Text(_activePageIndex == 0 ? lang.translate('login_btn') : lang.translate('register_btn')),
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
                               _activePageIndex == 0 ? lang.translate('no_account') : lang.translate('already_member'),
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

  Widget _buildAgreementCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFFF9C06A),
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              side: BorderSide(color: textColor.withValues(alpha: 0.3)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: GoogleFonts.outfit(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
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
        cursorColor: const Color(0xFFF9C06A),
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
