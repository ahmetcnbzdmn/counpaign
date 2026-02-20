import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

String? resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  
  final base = ApiConfig.baseUrl.replaceAll('/api', '');
  
  // Ensure we don't have double slashes or missing slashes
  if (path.startsWith('/')) {
    return '$base$path';
  } else {
    return '$base/$path';
  }
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
      primaryColor = Colors.green;
      icon = Icons.check_circle_rounded;
      defaultTitle = Provider.of<LanguageProvider>(context, listen: false).translate('success_title');
      break;
    case PopupType.error:
      primaryColor = const Color(0xFFEE2C2C);
      icon = Icons.error_rounded;
      defaultTitle = Provider.of<LanguageProvider>(context, listen: false).translate('error');
      break;
    case PopupType.info:
      primaryColor = Colors.blue;
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
                          backgroundColor: type == PopupType.error ? const Color(0xFFEE2C2C) : theme.primaryColor,
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
