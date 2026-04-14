import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';

/// Renders a price with ₺ symbol where ₺ uses Roboto font (guaranteed to have ₺ on Android).
/// [suffix]: true = "100₺" format, false = "₺100" format (default).
Widget tlText(String amount, TextStyle style, {bool suffix = false, int? maxLines, TextOverflow? overflow}) {
  final tlStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: style.fontSize,
    fontWeight: style.fontWeight,
    color: style.color,
    decoration: style.decoration,
    decorationColor: style.decorationColor,
  );
  return Text.rich(
    TextSpan(
      children: suffix
          ? [TextSpan(text: amount, style: style), TextSpan(text: '₺', style: tlStyle)]
          : [TextSpan(text: '₺', style: tlStyle), TextSpan(text: amount, style: style)],
    ),
    maxLines: maxLines,
    overflow: overflow,
  );
}

String resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  
  // Remove /api and optional trailing slash to get the domain root
  String base = ApiConfig.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
  
  // Ensure base doesn't end with / and path doesn't start with / for clean concatenation
  if (base.endsWith('/')) base = base.substring(0, base.length - 1);
  
  String cleanPath = path;
  if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
  
  return '$base/$cleanPath';
}

double parseRating(dynamic data) {
  if (data == null) return 0.0;
  if (data is num) return data.toDouble();
  
  if (data is Map) {
    final score = data['score'] ?? data['rating'] ?? data['average'] ?? data['avg'] ?? data['value'];
    if (score != null) return parseRating(score);
  }
  
  if (data is String) {
    return double.tryParse(data) ?? 0.0;
  }
  
  return 0.0;
}

int parseReviewCount(dynamic data) {
  if (data == null) return 0;
  if (data is num) return data.toInt();
  
  if (data is Map) {
    final count = data['count'] ?? data['total'] ?? data['ratingCount'] ?? data['reviewCount'];
    if (count != null) return parseReviewCount(count);
  }
  
  if (data is String) {
    return int.tryParse(data) ?? 0;
  }
  
  return 0;
}


enum PopupType { success, error, info }

Future<void> showCustomPopup(
  BuildContext context, {
  required String message,
  PopupType type = PopupType.info,
  String? title,
  Duration duration = const Duration(seconds: 3),
}) {
  // Clean technical prefixes from message (e.g. "Exception: ", "DioException: ")
  String cleanedMessage = message;
  final prefixes = ["Exception:", "DioException:", "Error:", "FormatException:"];
  
  for (var prefix in prefixes) {
    if (cleanedMessage.contains(prefix)) {
      cleanedMessage = cleanedMessage.split(prefix).last.trim();
    }
  }
  
  // Also handle common "Exception [" or similar formats
  if (cleanedMessage.startsWith("Exception [")) {
     final start = cleanedMessage.indexOf("]") + 1;
     cleanedMessage = cleanedMessage.substring(start).trim();
  }

  final theme = Theme.of(context);
  
  Color primaryColor;
  IconData icon;
  String defaultTitle;

  switch (type) {
    case PopupType.success:
      primaryColor = AppTheme.primaryColor;
      icon = Icons.check_circle_rounded;
      defaultTitle = Provider.of<LanguageProvider>(context, listen: false).translate('success_title');
      break;
    case PopupType.error:
      primaryColor = const Color(0xFFD32F2F); // Slightly deeper premium red
      icon = Icons.error_rounded;
      defaultTitle = Provider.of<LanguageProvider>(context, listen: false).translate('error');
      break;
    case PopupType.info:
      primaryColor = AppTheme.primaryColor;
      icon = Icons.info_rounded;
      defaultTitle = Provider.of<LanguageProvider>(context, listen: false).translate('info');
      break;
  }

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (context, anim1, anim2, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
        child: FadeTransition(
          opacity: anim1,
          child: AlertDialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: EdgeInsets.zero,
            content: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: primaryColor, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title ?? defaultTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cleanedMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('ok'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

void showNoCampaignsDialog(BuildContext context, String firmName) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.domain_disabled_rounded, color: AppTheme.deepBrown, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              Provider.of<LanguageProvider>(context, listen: false).translate('no_active_campaigns_title'),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Provider.of<LanguageProvider>(context, listen: false).translate('no_active_campaigns_desc').replaceFirst('{firmName}', firmName),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.bodyText,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('ok'), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
