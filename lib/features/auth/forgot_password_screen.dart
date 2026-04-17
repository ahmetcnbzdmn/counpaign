import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/widgets/password_strength_indicator.dart';

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

  @override
  void initState() {
    super.initState();
    // Şifre alanları değiştikçe güç & eşleşme göstergesi rebuild olsun
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_onPasswordChanged);
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _sendSms() async {
    final lang = context.read<LanguageProvider>();
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      showCustomPopup(context, message: lang.translate('invalid_phone_msg'), type: PopupType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      String normalizedPhone = phone;
      if (normalizedPhone.startsWith('0')) normalizedPhone = normalizedPhone.substring(1);
      if (normalizedPhone.startsWith('90')) normalizedPhone = normalizedPhone.substring(2);
      if (normalizedPhone.startsWith('+90')) normalizedPhone = normalizedPhone.substring(3);

      await context.read<AuthProvider>().sendResetSms(normalizedPhone);

      if (mounted) {
        showCustomPopup(context, message: lang.translate('code_sent_msg'), type: PopupType.success);
        setState(() => _currentStep = ResetStep.otp);
      }
    } catch (e) {
      if (mounted) showCustomPopup(context, message: lang.translate('sms_failed_msg'), type: PopupType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyOtp() async {
    final lang = context.read<LanguageProvider>();
    final code = _otpController.text.trim();
    if (code.length != 6) {
      showCustomPopup(context, message: lang.translate('enter_6_digit_msg'), type: PopupType.error);
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
        showCustomPopup(context, message: lang.translate('code_verified_msg'), type: PopupType.success);
        setState(() => _currentStep = ResetStep.newPassword);
      }
    } catch (e) {
      if (mounted) showCustomPopup(context, message: lang.translate('invalid_code_msg'), type: PopupType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetPassword() async {
    final lang = context.read<LanguageProvider>();
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    // Tüm şifre şartlarını zorla (8+ karakter, büyük harf, rakam, özel karakter)
    if (!PasswordStrength.of(pass).meetsAll) {
      showCustomPopup(
        context,
        message: lang.translate('pwd_requirements_not_met'),
        type: PopupType.error,
      );
      return;
    }

    if (pass != confirm) {
      showCustomPopup(context, message: lang.translate('passwords_no_match_msg'), type: PopupType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().resetPassword(pass);

      if (mounted) {
        showCustomPopup(context, message: lang.translate('password_reset_success'), type: PopupType.success);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/');
        });
      }
    } catch (e) {
      if (mounted) showCustomPopup(context, message: lang.translate('password_same_error'), type: PopupType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF131313);
    const bgColor = Color(0xFFEBEBEB);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: textColor),
        title: Text(
          _currentStep == ResetStep.phone ? lang.translate('forgot_password_title')
          : _currentStep == ResetStep.otp ? lang.translate('verification_title')
          : lang.translate('new_password_title'),
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
                  Text(lang.translate('phone_number_label'), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text(lang.translate('phone_number_desc'),
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
                  Text(lang.translate('enter_code_title'), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text('${_phoneController.text} ${lang.translate('otp_desc_prefix')}',
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
                  Text(lang.translate('new_password_title'), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text(lang.translate('new_password_desc'),
                    style: GoogleFonts.outfit(fontSize: 16, color: textColor.withValues(alpha: 0.7))),
                  const SizedBox(height: 32),
                  _buildInput(
                    controller: _passwordController,
                    hint: lang.translate('new_password_hint'),
                    icon: Icons.vpn_key_outlined,
                    isPassword: true,
                  ),
                  // Şifre gücü göstergesi
                  PasswordStrengthIndicator(
                    password: _passwordController.text,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    controller: _confirmPasswordController,
                    hint: lang.translate('confirm_password_hint'),
                    icon: Icons.check_circle_outline,
                    isPassword: true,
                  ),
                  // Eşleşme göstergesi
                  if (_confirmPasswordController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 4),
                      child: Builder(
                        builder: (_) {
                          final match = _passwordController.text ==
                              _confirmPasswordController.text;
                          final color = match
                              ? const Color(0xFF43A047)
                              : const Color(0xFFE53935);
                          return Row(
                            children: [
                              Icon(
                                match
                                    ? Icons.check_circle_rounded
                                    : Icons.error_rounded,
                                size: 14,
                                color: color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                match
                                    ? lang.translate('passwords_match')
                                    : lang.translate('passwords_dont_match'),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],

                const SizedBox(height: 40),
                _buildButton(lang),
                const SizedBox(height: 20),
                if (_currentStep != ResetStep.phone)
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _currentStep = ResetStep.phone),
                      child: Text(lang.translate('go_back_btn'), style: GoogleFonts.outfit(color: const Color(0xFFF9C06A), fontWeight: FontWeight.bold)),
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
    IconData? icon,
    Widget? child,
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
          prefixIcon: child ?? (icon != null ? Icon(icon, color: const Color(0xFF131313).withValues(alpha: 0.5)) : null),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildButton(LanguageProvider lang) {
    // Yeni şifre adımındayken: tüm şartlar + eşleşme sağlanmalı
    final bool canSubmitPassword = _currentStep != ResetStep.newPassword ||
        (PasswordStrength.of(_passwordController.text).meetsAll &&
            _passwordController.text.isNotEmpty &&
            _passwordController.text == _confirmPasswordController.text);
    final bool disabled = _isLoading || !canSubmitPassword;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade400 : const Color(0xFFF9C06A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFF9C06A).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: disabled ? null : () {
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
            : Text(
                _currentStep == ResetStep.phone ? lang.translate('send_code_btn')
                : _currentStep == ResetStep.otp ? lang.translate('verify_btn')
                : lang.translate('update_password_btn'),
              ),
        ),
      ),
    );
  }
}
