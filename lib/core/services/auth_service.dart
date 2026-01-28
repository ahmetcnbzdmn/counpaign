import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService(this._apiService, this._storageService);

  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    try {
      final response = await _apiService.client.post(
        '/auth/login', // Unified login endpoint
        data: {
          'phoneNumber': phoneNumber,
          'password': password,
        },
      );
      
      final token = response.data['token'];
      final user = response.data['user'];
      
      if (token != null) {
        await _storageService.saveToken(token);
        // Default to customer role if not provided, or get from backend
        final role = user != null ? user['role'] : 'customer';
        await _storageService.saveRole(role ?? 'customer');
      }
      return response.data;
    } catch (e) {
      if (e is DioException) {
         // Log the real backend error for debugging
         print("Backend Error: ${e.response?.data ?? e.message}");
      }
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
      final response = await _apiService.client.post(
        '/auth/register', // Unified register endpoint
        data: {
          'name': name,
          'surname': surname,
          'phoneNumber': phoneNumber,
          'email': email,
          'password': password,
          'gender': gender,
          'birthDate': birthDate?.toIso8601String(),
        },
      );
      
      // Auto login after register
      final token = response.data['token'];
      if (token != null) {
        await _storageService.saveToken(token);
        await _storageService.saveRole('customer'); // Default role
      }
      return response.data;
    } catch (e) {
       if (e is DioException) {
         print("Backend Error: ${e.response?.data ?? e.message}");
      }
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
