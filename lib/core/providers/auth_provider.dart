import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  AuthProvider(this._authService, this._storageService);

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> loadUserSession() async {
    final token = await _storageService.getToken();
    if (token != null) {
      try {
        await fetchProfile();
      } catch (e) {
        print("Session Load Error: $e");
        // If fetch fails (token expired or net error), clear session
        // But don't block app start. If net error, user might still want to see cached data?
        // For now, logout on error implies "Require Login".
        await logout();
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    try {
      final userData = await _authService.getProfile();
      _currentUser = User.fromJson(userData);
      
      // Sync FCM Token silently
      try {
        final token = await NotificationService.getToken();
        if (token != null) {
          await _authService.apiService.updateFcmToken(token);
        }
      } catch (e) {
        print("FCM Sync Error: $e");
      }

      notifyListeners();
    } catch (e) {
      print("Fetch Profile Error: $e");
      rethrow;
    }
  }

  Future<void> login(String phoneNumber, String password) async {
    _setLoading(true);
    try {
      await _authService.login(phoneNumber, password);
      await fetchProfile(); // Fetch full profile after login
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendSmsVerification(String phoneNumber) async {
    await _authService.sendSmsVerification(phoneNumber);
  }

  Future<void> verifySmsCode(String phoneNumber, String code) async {
    _setLoading(true);
    try {
      await _authService.verifySmsCode(phoneNumber, code);
      await fetchProfile(); // Now we are fully logged in
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

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
