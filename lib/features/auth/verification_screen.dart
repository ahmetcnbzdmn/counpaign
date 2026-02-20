import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/providers/auth_provider.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  
  const VerificationScreen({
    super.key, 
    required this.phoneNumber,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verify() async {
    if (_pinController.length != 6) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final auth = context.read<AuthProvider>();
      await auth.verifySmsCode(widget.phoneNumber, _pinController.text);
      
      if (mounted) {
        // Success Haptic
        HapticFeedback.heavyImpact();
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        _pinController.clear(); // Clear on error for retry
        showCustomPopup(
          context,
          message: e.toString().contains("Exception:") 
              ? e.toString().replaceAll("Exception: ", "") 
              : "Doğrulama başarısız.",
          type: PopupType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resendCode() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.sendSmsVerification(widget.phoneNumber);
      if (mounted) {
        showCustomPopup(context, message: "Kod tekrar gönderildi.", type: PopupType.success);
      }
    } catch (e) {
      if (mounted) {
        showCustomPopup(context, message: "Kod gönderilemedi.", type: PopupType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2329);
    final primaryColor = theme.primaryColor;

    // Pinput Theme
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2329) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: primaryColor),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );

    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      color: isDark ? const Color(0xFF2C333D) : const Color(0xFFE5E7EB),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Icon / Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.mark_email_unread_rounded, size: 48, color: primaryColor),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Doğrulama Kodu',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              
              const SizedBox(height: 12),
              
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'Lütfen ',
                  style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.6), fontSize: 16),
                  children: [
                    TextSpan(
                      text: widget.phoneNumber,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' numarasına gönderilen 6 haneli kodu giriniz.'),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // PIN Input
              Pinput(
                length: 6,
                controller: _pinController,
                focusNode: _focusNode,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                separatorBuilder: (index) => const SizedBox(width: 8),
                onCompleted: (pin) => _verify(),
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                cursor: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      width: 22,
                      height: 1,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('DOĞRULA'),
                ),
              ),

              const SizedBox(height: 24),

              // Resend
              TextButton(
                onPressed: _isLoading ? null : _resendCode,
                child: Text(
                  "Kodu tekrar gönder",
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
