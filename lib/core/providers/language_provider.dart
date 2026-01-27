import 'package:translator/translator.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../localization/app_localizations.dart';

class LanguageProvider extends ChangeNotifier {
  final StorageService _storageService;
  final GoogleTranslator _translator = GoogleTranslator();
  final Map<String, String> _translationCache = {};
  
  Locale _locale = const Locale('tr');

  LanguageProvider(this._storageService) {
    _loadLanguage();
  }

  Locale get locale => _locale;

  Future<void> _loadLanguage() async {
    final savedLang = await _storageService.getLanguage();
    if (savedLang != null) {
      _locale = Locale(savedLang);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    
    _locale = Locale(languageCode);
    notifyListeners();
    
    await _storageService.saveLanguage(languageCode);
  }

  // Legacy sync method - static localizations
  String translate(String key) {
    return AppLocalizations.getString(key, _locale.languageCode);
  }

  // -------------------------------------------------------------------------
  // REAL AUTO TRANSLATION LOGIC
  // -------------------------------------------------------------------------
  
  /// Translates text from TR to EN if locale is EN.
  /// Returns a Future so UI must handle async state.
  Future<String> translateAuto(String text) async {
    // 1. If Turkish (Source) or Empty -> Return Original
    if (_locale.languageCode == 'tr' || text.trim().isEmpty) {
      return text;
    }
    
    // 2. Check Memory Cache
    if (_translationCache.containsKey(text)) {
      return _translationCache[text]!;
    }
    
    // 3. Perform Network Translation (Google Translate)
    try {
      final translation = await _translator.translate(text, from: 'tr', to: 'en');
      final result = translation.text;
      
      // Cache it
      _translationCache[text] = result;
      return result;
    } catch (e) {
      debugPrint("Translation Error: $e");
      return text; // Return original if net/api fails
    }
  }

  /// Kept for backward compatibility to avoid breaking existing sync calls immediately.
  /// It will check cache first, if missing return original.
  /// NOTE: This won't trigger a fetch. Use [translateAuto] for fetch.
  String translateDynamic(String text) {
    if (_locale.languageCode == 'tr') return text;
    
    // If we have it cached from a previous async call, return it.
    if (_translationCache.containsKey(text)) {
      return _translationCache[text]!;
    }
    
    // Fallback: Return original (Sync cannot wait)
    // You should migrate UI to use FutureBuilder or AutoText widget
    return text;
  }
}

