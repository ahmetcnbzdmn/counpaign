import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _roleKey = 'user_role';
  static const String _userKey = 'cached_user';

  // Secure storage for sensitive data (tokens, user data)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // === SECURE STORAGE (tokens, credentials, user data) ===

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> saveCachedUser(String userJson) async {
    await _secureStorage.write(key: _userKey, value: userJson);
  }

  Future<String?> getCachedUser() async {
    return await _secureStorage.read(key: _userKey);
  }

  Future<void> saveRole(String role) async {
    await _secureStorage.write(key: _roleKey, value: role);
  }

  Future<String?> getRole() async {
    return await _secureStorage.read(key: _roleKey);
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _roleKey);
    await _secureStorage.delete(key: _userKey);
  }

  // === SHARED PREFERENCES (non-sensitive settings) ===

  static const String _introKey = 'has_seen_intro';
  static const String _themeKey = 'app_theme';
  static const String _langKey = 'app_language';
  static const String _guestSessionKey = 'guest_session';
  static const String _installationIdKey = 'installation_id';

  Future<void> setHasSeenIntro(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introKey, seen);
  }

  Future<bool> hasSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_introKey) ?? false;
  }

  Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  Future<bool?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey);
  }

  Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, languageCode);
  }

  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey);
  }

  Future<void> saveGuestSession(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestSessionKey, json);
  }

  Future<String?> getGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_guestSessionKey);
  }

  Future<void> clearGuestSession({bool resetInstallationId = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestSessionKey);
    if (resetInstallationId) {
      await prefs.remove(_installationIdKey);
    }
  }

  /// Stable installation ID — persists across app restarts (not reinstalls)
  Future<String> getOrCreateInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installationIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    // Generate cryptographically secure UUID v4
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant bits
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final id = '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
    await prefs.setString(_installationIdKey, id);
    return id;
  }
}
