import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService(this._apiService, this._storageService);

  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    try {
      // Map phone to internal email for Firebase
      final email = "$phoneNumber@counpaign.local";
      
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          await _storageService.saveToken(token);
        }
      }
      
      return {'user': user};
    } catch (e) {
      print("Firebase Login Error: $e");
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
      // 1. Register in Firebase
      final internalEmail = "$phoneNumber@counpaign.local";
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: internalEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName("$name $surname");
      }

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
      
      final token = response.data['token'];
      if (token != null) {
        await _storageService.saveToken(token);
      }
      
      return response.data;
    } catch (e) {
       print("Dual Register Error: $e");
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
         print("Backend Error: ${e.response?.data ?? e.message}");
         print("Request URI: ${e.requestOptions.uri}");
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
         print("Backend Error: ${e.response?.data ?? e.message}");
      }
      rethrow;
    }
  }
}
