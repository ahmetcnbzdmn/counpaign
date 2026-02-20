import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService(this._apiService, this._storageService);

  ApiService get apiService => _apiService;

  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    try {
      // 1. Lookup Email from Backend
      final response = await _apiService.client.post('/auth/lookup-email', data: {
        'phoneNumber': phoneNumber
      });
      
      final email = response.data['email'];
      
      UserCredential? userCredential;
      
      try {
        // 2. Login with Real Email (Preferred)
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (firebaseError) {
        // FALLBACK: If real email fails, try Legacy "Fake" Email
        // Old users are stored as "phone@counpaign.local" in Firebase
        debugPrint("Login with real email failed ($firebaseError). Trying legacy fallback...");
        
        final legacyEmail = "$phoneNumber@counpaign.local";
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: legacyEmail,
          password: password,
        );
      }
      
      final user = userCredential.user;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          await _storageService.saveToken(token);
        }
      }
      
      return {'user': user};
    } catch (e) {
      debugPrint("Firebase Login Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String name, 
    required String surname, 
    required String phoneNumber, 
    required String email, 
    required String password,
    String? gender,
    DateTime? birthDate,
  }) async {
    try {
      // 1. Register in Firebase with REAL Email
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName("$name $surname");
      }

      try {
        // 2. Register in Custom Backend (MongoDB)
        final response = await _apiService.client.post(
          '/auth/register',
          data: {
            'name': name,
            'surname': surname,
            'phoneNumber': phoneNumber,
            'email': email,
            'password': password,
            'gender': gender,
            'birthDate': birthDate?.toIso8601String(),
            'firebaseUid': user?.uid, // Added UID for linking if needed later
          },
        );
        
        return response.data;
      } catch (backendError) {
        // ROLLBACK: Delete Firebase User if Backend fails
        debugPrint("Backend Register Failed: $backendError. Rollback Firebase User.");
        await user?.delete();
        rethrow;
      }
    } catch (e) {
       debugPrint("Dual Register Error: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storageService.clearSession();
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.client.get('/customer/profile');
      return response.data;
    } catch (e) {
      if (e is DioException) {
         debugPrint("Backend Error: ${e.response?.data ?? e.message}");
         debugPrint("Request URI: ${e.requestOptions.uri}");
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name, 
    String? surname, 
    String? email, 
    String? profileImage,
    String? gender,
    DateTime? birthDate,
    String? phoneNumber,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (surname != null) data['surname'] = surname;
      if (email != null) data['email'] = email;
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
      if (profileImage != null) data['profileImage'] = profileImage;
      if (gender != null) data['gender'] = gender;
      if (birthDate != null) data['birthDate'] = birthDate.toIso8601String();

      final response = await _apiService.client.put(
        '/customer/profile',
        data: data,
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
         debugPrint("Backend Error: ${e.response?.data ?? e.message}");
      }
      rethrow;
    }
  }

  Future<void> sendSmsVerification(String phoneNumber) async {
    try {
      await _apiService.client.post('/auth/send-verification', data: {
        'phoneNumber': phoneNumber,
      });
    } catch (e) {
      if (e is DioException) {
         debugPrint("SMS Send Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  Future<void> verifySmsCode(String phoneNumber, String code) async {
    try {
      final response = await _apiService.client.post('/auth/verify-code', data: {
        'phoneNumber': phoneNumber,
        'code': code,
      });
      
      final token = response.data['token'];
      final refreshToken = response.data['refreshToken'];

      if (token != null) {
        await _storageService.saveToken(token);
        if (refreshToken != null) {
          await _storageService.saveRefreshToken(refreshToken);
        }
      }
    } catch (e) {
      if (e is DioException) {
         debugPrint("SMS Verify Error: ${e.response?.data}");
      }
      rethrow;
    }
  }
}
