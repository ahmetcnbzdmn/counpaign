import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/providers/auth_provider.dart' as app;
import '../../core/providers/language_provider.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/password_strength_indicator.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final lang = context.read<LanguageProvider>();
    final auth = context.read<app.AuthProvider>();

    // Tüm şifre şartlarını zorla
    if (!PasswordStrength.of(_newPasswordController.text).meetsAll) {
      showCustomPopup(
        context,
        message: lang.translate('pwd_requirements_not_met'),
        type: PopupType.error,
      );
      return;
    }

    try {
      await auth.changePassword(
        _oldPasswordController.text, 
        _newPasswordController.text
      );
      
      if (mounted) {
        // Show Premium Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9C06A).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFFF9C06A), size: 64),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    lang.translate('password_updated_title'),
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF131313)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lang.translate('password_updated_msg'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9C06A),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF9C06A).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx); // Close dialog
                          Navigator.pop(context); // Go back to settings
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(lang.translate('ok'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errMsg = lang.translate('update_failed');
        if (e is DioException) {
          errMsg = e.response?.data['error'] ?? lang.translate('an_error_occurred');
        }
        showCustomPopup(context, message: errMsg, type: PopupType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Styling constants matching edit_profile_screen.dart
    const textColor = Color(0xFF131313);
    const bgColor = Color(0xFFEBEBEB);
    const cardColor = Colors.white;
    const primaryBrand = Color(0xFF76410B);
    const accentColor = Color(0xFFF9C06A);
    final lang = context.watch<LanguageProvider>();
    final auth = context.watch<app.AuthProvider>();

    final bool passwordsMatch = _newPasswordController.text.isNotEmpty &&
                         _newPasswordController.text == _confirmPasswordController.text;
    final bool meetsAllReqs = PasswordStrength.of(_newPasswordController.text).meetsAll;
    final bool canSubmit = passwordsMatch && meetsAllReqs;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          lang.translate('change_password'), 
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)
        ),
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Illustration/Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: accentColor,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                lang.translate('password_security_tip'),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),

              // Fields
              _buildField(
                controller: _oldPasswordController,
                label: lang.translate('current_password'),
                obscureText: _obscureOld,
                textColor: textColor,
                cardColor: cardColor,
                primaryBrand: primaryBrand,
                onToggleVisibility: () => setState(() => _obscureOld = !_obscureOld),
              ),
              const SizedBox(height: 20),
              
              _buildField(
                controller: _newPasswordController,
                label: lang.translate('new_password'),
                obscureText: _obscureNew,
                textColor: textColor,
                cardColor: cardColor,
                primaryBrand: primaryBrand,
                onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
                onChanged: (val) => setState(() {}),
                validator: (val) {
                  if (val == null || val.isEmpty) return lang.translate('fill_all_fields');
                  if (val.length < 6) return lang.translate('password_min_chars');
                  return null;
                },
              ),

              // Şifre gücü göstergesi
              PasswordStrengthIndicator(
                password: _newPasswordController.text,
                textColor: textColor,
              ),

              const SizedBox(height: 20),

              _buildField(
                controller: _confirmPasswordController,
                label: lang.translate('confirm_password'),
                obscureText: _obscureConfirm,
                textColor: textColor,
                cardColor: cardColor,
                primaryBrand: primaryBrand,
                onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                onChanged: (val) => setState(() {}),
                validator: (val) {
                  if (val == null || val.isEmpty) return lang.translate('fill_all_fields');
                  if (val != _newPasswordController.text) return lang.translate('passwords_dont_match');
                  return null;
                },
              ),

              // Match Indicator
              if (_confirmPasswordController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 4),
                  child: Row(
                    children: [
                      Icon(
                        passwordsMatch ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                        color: passwordsMatch ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        passwordsMatch ? lang.translate('passwords_match') : lang.translate('passwords_dont_match'),
                        style: GoogleFonts.outfit(
                          color: passwordsMatch ? Colors.green : Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 56),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    color: canSubmit ? accentColor : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canSubmit ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ] : [],
                  ),
                  child: ElevatedButton(
                    onPressed: (auth.isLoading || !canSubmit) ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: textColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: auth.isLoading 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: accentColor, strokeWidth: 2.5)
                        )
                      : Text(lang.translate('update').toUpperCase()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required Color textColor,
    required Color cardColor,
    required Color primaryBrand,
    required VoidCallback onToggleVisibility,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w500),
      validator: validator ?? (val) => val == null || val.isEmpty ? Provider.of<LanguageProvider>(context, listen: false).translate('field_required') : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.5)),
        filled: true,
        fillColor: cardColor,
        prefixIcon: Icon(Icons.lock_outline_rounded, color: textColor.withValues(alpha: 0.4)),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: textColor.withValues(alpha: 0.4),
            size: 20,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF9C06A), width: 1.5)
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: const BorderSide(color: Colors.red, width: 1)
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
