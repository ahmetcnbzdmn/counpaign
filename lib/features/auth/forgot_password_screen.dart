import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/providers/auth_provider.dart';

enum ResetStep { phone, otp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  ResetStep _currentStep = ResetStep.phone;
  bool _isLoading = false;

  void _sendSms() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      showCustomPopup(context, message: 'Lütfen geçerli bir telefon numarası girin.', type: PopupType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Normalize phone for backend: 5xx... (backend prepends +90)
      String normalizedPhone = phone;
      if (normalizedPhone.startsWith('0')) normalizedPhone = normalizedPhone.substring(1);
      if (normalizedPhone.startsWith('90')) normalizedPhone = normalizedPhone.substring(2);
      if (normalizedPhone.startsWith('+90')) normalizedPhone = normalizedPhone.substring(3);

      await context.read<AuthProvider>().sendResetSms(normalizedPhone);
      
      if (mounted) {
        showCustomPopup(context, message: 'Doğrulama kodu gönderildi.', type: PopupType.success);
        setState(() => _currentStep = ResetStep.otp);
      }
    } catch (e) {
      if (mounted) showCustomPopup(context, message: 'SMS gönderilemedi. Numaranızı kontrol edin.', type: PopupType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      showCustomPopup(context, message: 'Lütfen 6 haneli kodu girin.', type: PopupType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      String normalizedPhone = _phoneController.text.trim();
      if (normalizedPhone.startsWith('0')) normalizedPhone = normalizedPhone.substring(1);
      if (normalizedPhone.startsWith('90')) normalizedPhone = normalizedPhone.substring(2);
      if (normalizedPhone.startsWith('+90')) normalizedPhone = normalizedPhone.substring(3);

      await context.read<AuthProvider>().verifyResetCode(normalizedPhone, code);
      
      if (mounted) {
        showCustomPopup(context, message: 'Kod doğrulandı. Yeni şifrenizi belirleyin.', type: PopupType.success);
        setState(() => _currentStep = ResetStep.newPassword);
      }
    } catch (e) {
      if (mounted) showCustomPopup(context, message: 'Geçersiz doğrulama kodu.', type: PopupType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetPassword() async {
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (pass.length < 6) {
      showCustomPopup(context, message: 'Şifreniz en az 6 karakter olmalıdır.', type: PopupType.error);
      return;
    }

    if (pass != confirm) {
      showCustomPopup(context, message: 'Şifreler uyuşmuyor.', type: PopupType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().resetPassword(pass);
      
      if (mounted) {
        showCustomPopup(context, message: 'Şifreniz başarıyla güncellendi.', type: PopupType.success);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/'); // Redirect to home/login
        });
      }
    } catch (e) {
      String errorMsg = 'Yeni şifreniz eski şifrenizle aynı olamaz. Lütfen farklı bir şifre belirleyin.';
      if (e.toString().contains('aynı olamaz')) {
        errorMsg = 'Yeni şifreniz eski şifrenizle aynı olamaz.';
      }
      if (mounted) showCustomPopup(context, message: errorMsg, type: PopupType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF131313);
    const primaryBrand = Color(0xFF76410B);
    const bgColor = Color(0xFFEBEBEB);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: textColor),
        title: Text(
          _currentStep == ResetStep.phone ? 'Şifremi Unuttum' 
          : _currentStep == ResetStep.otp ? 'Doğrulama' 
          : 'Yeni Şifre',
          style: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      child: const ClipOval(child: Image(image: AssetImage('assets/images/splash_logo.png'), fit: BoxFit.cover)),
                    ),
                ),
                const SizedBox(height: 32),
                
                if (_currentStep == ResetStep.phone) ...[
                  Text('Telefon Numaranız', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text('Hesabınıza kayıtlı telefon numaranızı girin. Size doğrulama kodu göndereceğiz.', 
                    style: GoogleFonts.outfit(fontSize: 16, color: textColor.withValues(alpha: 0.7))),
                  const SizedBox(height: 32),
                    _buildInput(
                      controller: _phoneController,
                      hint: '5xx xxx xx xx',
                      icon: Icons.phone_android_rounded,
                      type: TextInputType.phone,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                ] else if (_currentStep == ResetStep.otp) ...[
                  Text('Kodu Girin', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text('${_phoneController.text} numarasına gönderilen 6 haneli kodu girin.', 
                    style: GoogleFonts.outfit(fontSize: 16, color: textColor.withValues(alpha: 0.7))),
                  const SizedBox(height: 32),
                  _buildInput(
                    controller: _otpController,
                    hint: '000000',
                    icon: Icons.lock_outline_rounded,
                    type: TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                ] else ...[
                  Text('Yeni Şifre', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text('Lütfen yeni şifrenizi belirleyin.', 
                    style: GoogleFonts.outfit(fontSize: 16, color: textColor.withValues(alpha: 0.7))),
                  const SizedBox(height: 32),
                  _buildInput(
                    controller: _passwordController,
                    hint: 'Yeni Şifre',
                    icon: Icons.vpn_key_outlined,
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    controller: _confirmPasswordController,
                    hint: 'Şifreyi Onayla',
                    icon: Icons.check_circle_outline,
                    isPassword: true,
                  ),
                ],

                const SizedBox(height: 40),
                _buildButton(),
                const SizedBox(height: 20),
                if (_currentStep != ResetStep.phone)
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _currentStep = ResetStep.phone),
                      child: Text('Geri Dön', style: GoogleFonts.outfit(color: const Color(0xFFF9C06A), fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    IconData? icon, // Changed to nullable IconData
    Widget? child, // Added child parameter
    TextInputType type = TextInputType.text,
    bool isPassword = false,
    List<TextInputFormatter>? formatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.7), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: isPassword,
        inputFormatters: formatters,
        style: const TextStyle(color: Color(0xFF131313), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: child ?? (icon != null ? Icon(icon, color: const Color(0xFF131313).withValues(alpha: 0.5)) : null), // Use child if provided, else icon
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9C06A),
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
          onPressed: _isLoading ? null : () {
            if (_currentStep == ResetStep.phone) {
              _sendSms();
            } else if (_currentStep == ResetStep.otp) {
              _verifyOtp();
            } else {
              _resetPassword();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading 
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(_currentStep == ResetStep.phone ? 'KOD GÖNDER' : _currentStep == ResetStep.otp ? 'DOĞRULA' : 'ŞİFREYİ GÜNCELLE'),
        ),
      ),
    );
  }
}
