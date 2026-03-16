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

      // 2. Obtain Backend Token (primary auth — this is what the app uses)
      final backendResponse = await _apiService.client.post('/auth/login', data: {
        'phoneNumber': phoneNumber,
        'password': password
      });

      final backendToken = backendResponse.data['token'];
      final refreshToken = backendResponse.data['refreshToken'];
      if (backendToken != null) {
        await _storageService.saveToken(backendToken);
        if (refreshToken != null) {
          await _storageService.saveRefreshToken(refreshToken);
        }
      }

      // 3. Firebase Auth Login (secondary — keep in sync)
      User? firebaseUser;
      String? loggedInWithEmail;
      final emailsToTry = [email, "$phoneNumber@counpaign.local"];
      for (final tryEmail in emailsToTry) {
        try {
          final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: tryEmail,
            password: password,
          );
          firebaseUser = cred.user;
          loggedInWithEmail = tryEmail;
          break;
        } catch (_) {}
      }

      // If Firebase login succeeded with a different email than backend,
      // delete old Firebase user and recreate with correct email
      if (firebaseUser != null && loggedInWithEmail != email) {
        try {
          await firebaseUser.delete();
          final newCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          firebaseUser = newCred.user;
        } catch (syncErr) {
          // Try updateEmail as fallback
          try {
            firebaseUser = FirebaseAuth.instance.currentUser;
            if (firebaseUser != null) {
              // ignore: deprecated_member_use
              await firebaseUser.updateEmail(email);
            }
          } catch (_) {}
        }
      }

      return {'user': firebaseUser};
    } catch (e) {
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
      // ONLY Register in Custom Backend (MongoDB) - TempUser Queue
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
        },
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storageService.clearSession();
  }

  Future<void> deleteAccount(String password) async {
    // 1. Delete MongoDB data via API
    await _apiService.deleteAccount(password);

    // 2. Delete Firebase Auth user locally
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {
      // Non-blocking. The JWT and Mongo records are already dead.
    }

    // 3. Clear session
    await logout();
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.client.get('/customer/profile');
      return response.data;
    } catch (e) {
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

      // Sync email change to Firebase Auth so login keeps working
      if (email != null) {
        try {
          final fbUser = FirebaseAuth.instance.currentUser;
          if (fbUser != null && fbUser.email != email) {
            // ignore: deprecated_member_use
            await fbUser.updateEmail(email);
          }
        } catch (_) {
          // updateEmail may fail (deprecated/requires-recent-login)
          // Login flow will handle the sync with delete+recreate
        }
      }

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendSmsVerification(String phoneNumber) async {
    try {
      await _apiService.client.post('/auth/send-verification', data: {
        'phoneNumber': phoneNumber,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifySmsCode(String phoneNumber, String code, {String? email, String? password, String? name, String? surname}) async {
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

      // If this is a NEW Registration flow bridging from TempUser
      if (email != null && password != null) {
        try {
          // Now create Firebase Auth Credentials safely since we know phone is real
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          if (name != null) {
            await userCredential.user?.updateDisplayName("$name ${surname ?? ''}");
          }
        } catch (_) {
          // Non-blocking error. The backend JWT gives us full access anyway.
        }
      }

    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendResetSms(String phoneNumber) async {
    try {
      await _apiService.client.post('/auth/send-reset-sms', data: {
        'phoneNumber': phoneNumber,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<String> verifyResetCode(String phoneNumber, String code) async {
    try {
      final response = await _apiService.client.post('/auth/verify-reset-code', data: {
        'phoneNumber': phoneNumber,
        'code': code,
      });

      final resetToken = response.data['resetToken'];
      if (resetToken != null) {
        // Temporarily save reset token to enable the /reset-password call
        await _storageService.saveToken(resetToken);
        return resetToken;
      }
      throw Exception("Reset token missing");
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String newPassword) async {
    try {
      await _apiService.client.post('/auth/reset-password', data: {
        'password': newPassword,
      });

      // Clear the temporary reset token after use
      await logout();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      // 1. Update backend password first (validates old password)
      await _apiService.client.post('/auth/change-password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });

      // 2. Sync Firebase Auth credentials
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null && fbUser.email != null) {
        try {
          // Re-authenticate with current Firebase email + old password
          final credential = EmailAuthProvider.credential(
            email: fbUser.email!,
            password: oldPassword,
          );
          await fbUser.reauthenticateWithCredential(credential);

          // Update Firebase password to match backend
          await fbUser.updatePassword(newPassword);

          // Also sync Firebase email to backend email if they differ
          try {
            final profileData = await getProfile();
            final backendEmail = profileData['email'] as String?;
            if (backendEmail != null && backendEmail != fbUser.email) {
              // ignore: deprecated_member_use
              await fbUser.updateEmail(backendEmail);
            }
          } catch (_) {}
        } catch (_) {}
      }
    } catch (e) {
      rethrow;
    }
  }
}
