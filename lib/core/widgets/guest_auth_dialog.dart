import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

/// Shows a bottom sheet dialog prompting guests to log in or register.
/// Call [GuestAuthDialog.show] wherever a restricted feature is tapped.
class GuestAuthDialog {
  static void show(
    BuildContext context, {
    String? message,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GuestAuthSheet(message: message),
    );
  }
}

class _GuestAuthSheet extends StatelessWidget {
  final String? message;
  const _GuestAuthSheet({this.message});

  @override
  Widget build(BuildContext context) {
    const Color primaryBrand = Color(0xFF76410B);
    const Color accent = Color(0xFFF9C06A);
    const Color textColor = Color(0xFF131313);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded, color: primaryBrand, size: 32),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Kayıt Olmanız Gerekiyor',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),

          // Message
          Text(
            message ?? 'Bu özelliği kullanabilmek için ücretsiz hesap oluşturmalısın.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: textColor.withValues(alpha: 0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Kayıt Ol button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/login', extra: {'pageIndex': 1});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Kayıt Ol',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
