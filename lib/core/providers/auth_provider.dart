import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool _isGuestMode = false;
  bool get isGuestMode => _isGuestMode;
  bool get hasAppAccess => isAuthenticated || _isGuestMode;

  AuthProvider(this._authService, this._storageService);

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _accountWasDeleted = false;
  bool get accountWasDeleted => _accountWasDeleted;
  set accountWasDeleted(bool value) {
    _accountWasDeleted = value;
    notifyListeners();
  }
  void clearAccountDeletedFlag() => _accountWasDeleted = false;

  Future<void> loadUserSession() async {
    try {
      final token = await _storageService.getToken();
      
      if (token != null && token.isNotEmpty) {
        // Optimistically load cached user to prevent 401 kicks
        try {
          final cachedUserStr = await _storageService.getCachedUser();
          if (cachedUserStr != null && cachedUserStr.isNotEmpty) {
            _currentUser = User.fromJson(jsonDecode(cachedUserStr));
          }
        } catch (e) {
          debugPrint("Error loading cached user: $e");
        }

        try {
          await fetchProfile();
        } catch (e) {
          debugPrint("Session Load (fetchProfile) Error: $e");
          // Admin deleted this account → 404. Force logout immediately.
          final errStr = e.toString();
          if (errStr.contains('404') || errStr.contains('Kullanıcı bulunamadı')) {
            _accountWasDeleted = true;
            await logout();
            return;
          }
          // Network/server errors: keep cached user, don't kick out
        }
      } else {
         // No token found, ensure state is clean
         _currentUser = null;
      }
    } catch(e) {
       debugPrint("Storage Read Error: $e");
       await logout();
    } finally {
      // Must always initialize so Splash Screen can route away
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    try {
      final userData = await _authService.getProfile();
      _currentUser = User.fromJson(userData);
      
      // Save to cache for persistent login across restarts even on 401s
      await _storageService.saveCachedUser(jsonEncode(userData));
      
      // Sync FCM Token silently
      try {
        final token = await NotificationService.getToken();
        if (token != null) {
          await _authService.apiService.updateFcmToken(token);
        }
      } catch (e) {
        debugPrint("FCM Sync Error: $e");
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Fetch Profile Error: $e");
      rethrow;
    }
  }

  Future<void> login(String phoneNumber, String password, {String? guestId}) async {
    _setLoading(true);
    try {
      await _authService.login(phoneNumber, password, guestId: guestId);
      await fetchProfile(); // Fetch full profile after login
      _isGuestMode = false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendSmsVerification(String phoneNumber, {String? guestId}) async {
    await _authService.sendSmsVerification(phoneNumber, guestId: guestId);
  }

  Future<void> verifySmsCode(String phoneNumber, String code, {String? email, String? password, String? name, String? surname, String? guestId}) async {
    _setLoading(true);
    try {
      await _authService.verifySmsCode(
        phoneNumber,
        code,
        email: email,
        password: password,
        name: name,
        surname: surname,
        guestId: guestId,
      );
      await fetchProfile(); // Now we are fully logged in
      _isGuestMode = false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String name, 
    required String surname, 
    required String phoneNumber, 
    required String email, 
    required String password,
    String? gender,
    DateTime? birthDate,
    String? guestId,
  }) async {
    _setLoading(true);
    try {
      await _authService.register(
        name: name,
        surname: surname,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
        gender: gender,
        birthDate: birthDate,
        guestId: guestId,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? name, 
    String? surname, 
    String? email, 
    String? profileImage,
    String? gender,
    DateTime? birthDate,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    try {
      final updatedData = await _authService.updateProfile(
        name: name,
        surname: surname,
        email: email,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
        gender: gender,
        birthDate: birthDate,
      );
      _currentUser = User.fromJson(updatedData);
      notifyListeners(); 
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount(String password) async {
    _setLoading(true);
    try {
      await _authService.deleteAccount(password);
      _currentUser = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void enterGuestMode() {
    _isGuestMode = true;
    _currentUser = null;
    notifyListeners();
  }

  void exitGuestMode() {
    _isGuestMode = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _isGuestMode = false;
    notifyListeners();
  }

  Future<void> sendResetSms(String phoneNumber) async {
    _setLoading(true);
    try {
      await _authService.sendResetSms(phoneNumber);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyResetCode(String phoneNumber, String code) async {
    _setLoading(true);
    try {
      await _authService.verifyResetCode(phoneNumber, code);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String password) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(password);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    _setLoading(true);
    try {
      await _authService.changePassword(oldPassword, newPassword);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
