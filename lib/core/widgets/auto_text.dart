import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AutoText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const AutoText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  State<AutoText> createState() => _AutoTextState();
}

class _AutoTextState extends State<AutoText> {
  String? _translatedText;

  @override
  void didUpdateWidget(covariant AutoText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _translatedText = null; // Reset on text change
      _translate();
    }
  }

  @override
  void initState() {
    super.initState();
    _translate();
  }

  void _translate() {
    final lang = context.read<LanguageProvider>();
    
    // Initial check (Cache Hit?)
    // We can't access provider sync easily in initState without context listen issues if not careful,
    // but read() is fine.
    
    lang.translateAuto(widget.text).then((result) {
      if (mounted && result != widget.text) {
        setState(() {
          _translatedText = result;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    
    // If language is TR, just show original
    if (lang.locale.languageCode == 'tr') {
       return Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: widget.textAlign,
      );
    }

    // Use cached/translated text or fallback to original
    final display = _translatedText ?? widget.text;

    return Text(
      display,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }
}
