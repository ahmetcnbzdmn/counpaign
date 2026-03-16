import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/language_provider.dart';

class LegalContentScreen extends StatefulWidget {
  final String title;
  final String assetBaseName; // e.g. 'user_agreement'

  const LegalContentScreen({
    super.key,
    required this.title,
    required this.assetBaseName,
  });

  @override
  State<LegalContentScreen> createState() => _LegalContentScreenState();
}

class _LegalContentScreenState extends State<LegalContentScreen> {
  String _htmlContent = '';
  bool _loading = true;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadHtml();
    }
  }

  Future<void> _loadHtml() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final suffix = lang.locale.languageCode == 'tr' ? '_tr' : '_en';
    final path = 'assets/legal/${widget.assetBaseName}$suffix.html';
    final content = await rootBundle.loadString(path);
    if (mounted) {
      setState(() {
        _htmlContent = content;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Html(
                data: _htmlContent,
                style: {
                  "body": Style(
                    color: textColor,
                    fontSize: FontSize(14),
                    lineHeight: LineHeight(1.65),
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                  "h1": Style(
                    color: textColor,
                    fontSize: FontSize(24),
                    fontWeight: FontWeight.bold,
                  ),
                  "h2": Style(
                    color: textColor,
                    fontSize: FontSize(18),
                    fontWeight: FontWeight.bold,
                  ),
                  "h3": Style(
                    color: textColor,
                    fontSize: FontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                  "p": Style(
                    color: textColor.withValues(alpha: 0.85),
                    fontSize: FontSize(14),
                  ),
                  "li": Style(
                    color: textColor.withValues(alpha: 0.85),
                    fontSize: FontSize(14),
                  ),
                  ".card": Style(
                    backgroundColor: Colors.transparent,
                    border: Border.all(color: Colors.transparent),
                    padding: HtmlPaddings.zero,
                  ),
                  ".meta": Style(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: FontSize(13),
                  ),
                  ".box": Style(
                    backgroundColor: textColor.withValues(alpha: 0.05),
                    padding: HtmlPaddings.all(12),
                    margin: Margins.symmetric(vertical: 12),
                  ),
                  "strong": Style(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                },
              ),
            ),
    );
  }
}
