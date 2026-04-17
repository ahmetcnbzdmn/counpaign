import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

/// 0..4 arası güç skoru. 0 = boş, 1 = çok zayıf, 4 = güçlü.
class PasswordStrength {
  final int score; // 0..4
  final bool hasLength;     // ≥ 8
  final bool hasUppercase;  // A-Z
  final bool hasLowercase;  // a-z
  final bool hasNumber;     // 0-9
  final bool hasSymbol;     // özel karakter

  const PasswordStrength({
    required this.score,
    required this.hasLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSymbol,
  });

  /// Kayıt/şifre değiştir akışı için tüm şartların sağlanıp sağlanmadığı.
  /// (Aşağıdaki chip listesiyle birebir aynı dört kriter)
  bool get meetsAll => hasLength && hasUppercase && hasNumber && hasSymbol;

  static PasswordStrength of(String pwd) {
    if (pwd.isEmpty) {
      return const PasswordStrength(
        score: 0, hasLength: false, hasUppercase: false,
        hasLowercase: false, hasNumber: false, hasSymbol: false,
      );
    }
    final hasLength = pwd.length >= 8;
    final hasUpper = pwd.contains(RegExp(r'[A-Z]'));
    final hasLower = pwd.contains(RegExp(r'[a-z]'));
    final hasNum = pwd.contains(RegExp(r'\d'));
    final hasSym = pwd.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\\[\]~`;]'));

    int s = 0;
    if (pwd.length >= 6) s++;                    // 1: minimum
    if (hasLength && (hasUpper || hasLower)) s++; // 2: 8+ ve harf var
    if (hasNum && (hasUpper || hasLower)) s++;    // 3: harf+rakam
    if (hasSym && hasLength) s++;                 // 4: 8+ ve özel karakter
    if (pwd.length >= 12 && hasNum && hasUpper && hasLower && hasSym) s = 4; // bonus

    return PasswordStrength(
      score: s.clamp(0, 4),
      hasLength: hasLength,
      hasUppercase: hasUpper,
      hasLowercase: hasLower,
      hasNumber: hasNum,
      hasSymbol: hasSym,
    );
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final Color textColor;
  final bool showRequirements;
  final bool compact; // küçük ekranlar için

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.textColor = const Color(0xFF131313),
    this.showRequirements = true,
    this.compact = false,
  });

  Color _colorFor(int score) {
    switch (score) {
      case 0:
      case 1: return const Color(0xFFE53935); // kırmızı
      case 2: return const Color(0xFFFB8C00); // turuncu
      case 3: return const Color(0xFFFBC02D); // sarı
      case 4: return const Color(0xFF43A047); // yeşil
      default: return const Color(0xFFE53935);
    }
  }

  String _labelFor(int score, LanguageProvider lang) {
    switch (score) {
      case 0: return lang.translate('pwd_strength_empty');
      case 1: return lang.translate('pwd_strength_weak');
      case 2: return lang.translate('pwd_strength_fair');
      case 3: return lang.translate('pwd_strength_good');
      case 4: return lang.translate('pwd_strength_strong');
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final s = PasswordStrength.of(password);
    final color = _colorFor(s.score);
    final label = _labelFor(s.score, lang);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 4 segmentli güç barı ===
            Row(
              children: List.generate(4, (i) {
                final filled = i < s.score;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                      height: 6,
                      decoration: BoxDecoration(
                        color: filled ? color : textColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: filled
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            // === Etiket ===
            Row(
              children: [
                Icon(
                  s.score >= 3
                      ? Icons.shield_rounded
                      : s.score == 2
                          ? Icons.shield_outlined
                          : Icons.warning_amber_rounded,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  '${lang.translate('pwd_strength_label')}: ',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            // === Gereksinim listesi ===
            if (showRequirements && !compact) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip(lang.translate('pwd_req_length'), s.hasLength),
                  _chip(lang.translate('pwd_req_upper'), s.hasUppercase),
                  _chip(lang.translate('pwd_req_number'), s.hasNumber),
                  _chip(lang.translate('pwd_req_symbol'), s.hasSymbol),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool met) {
    final c = met ? const Color(0xFF43A047) : textColor.withValues(alpha: 0.45);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: met
            ? const Color(0xFF43A047).withValues(alpha: 0.10)
            : textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: met
              ? const Color(0xFF43A047).withValues(alpha: 0.35)
              : textColor.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_rounded : Icons.circle_outlined,
            size: 12,
            color: c,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
