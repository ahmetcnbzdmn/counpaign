import 'package:flutter/foundation.dart';

import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  final Dio _dio;
  final StorageService _storageService;
  bool _isRefreshing = false;
  final List<Completer<bool>> _requestQueue = [];

    ApiService(this._storageService)
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15), // Reduced to fail faster and retry
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        )) {
    
    // Add Interceptors
    _dio.interceptors.addAll([
      // 1. Authorization Interceptor
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers.addAll({'Authorization': 'Bearer $token'});
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Handle 401 Unauthorized
          if (e.response?.statusCode == 401) {
            // No token at all (guest mode) - skip refresh entirely
            final currentToken = await _storageService.getToken();
            if (currentToken == null || currentToken.isEmpty) {
              onUnauthorized?.call(isAccountDeleted: false);
              return handler.next(e);
            }

            if (_isRefreshing) {
              final completer = Completer<bool>();
              _requestQueue.add(completer);
              final success = await completer.future;
              if (success) {
                final newToken = await _storageService.getToken();
                final options = e.requestOptions;
                options.headers['Authorization'] = 'Bearer $newToken';
                final retryResponse = await _dio.fetch(options);
                return handler.resolve(retryResponse);
              }
              return handler.next(e);
            }

            _isRefreshing = true;
            final refreshToken = await _storageService.getRefreshToken();
            
            if (refreshToken != null) {
              try {
                final refreshDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
                final refreshResponse = await refreshDio.post(
                  'auth/refresh-token',
                  data: {'refreshToken': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newToken = refreshResponse.data['token'];
                  await _storageService.saveToken(newToken);

                  for (var completer in _requestQueue) {
                    completer.complete(true);
                  }
                  _requestQueue.clear();
                  _isRefreshing = false;

                  final options = e.requestOptions;
                  options.headers['Authorization'] = 'Bearer $newToken';
                  final retryResponse = await _dio.fetch(options);
                  return handler.resolve(retryResponse);
                }
              } catch (_) {
              }
            }

            // Global fallback
            for (var completer in _requestQueue) {
              completer.complete(false);
            }
            _requestQueue.clear();
            _isRefreshing = false;

            // Check if specific deletion error from backend
            final bool isDeleted = e.response?.data?['error'] == 'ACCOUNT_DELETED';
            onUnauthorized?.call(isAccountDeleted: isDeleted);
          }
          return handler.next(e);
        },
      ),
      
      // 2. Retry Interceptor for connection errors
      _RetryInterceptor(_dio),
    ]);
  }

  // Callback to handle 401 errors (e.g. trigger logout)
  // isAccountDeleted: true if the backend explicitly returned ACCOUNT_DELETED
  void Function({bool isAccountDeleted})? onUnauthorized;

  Dio get client => _dio;

  // Wallet / Firm Methods
  Future<List<dynamic>> getAvailableFirms() async {
    final response = await _dio.get('wallet/explore');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getNewestBusinesses() async {
    final response = await _dio.get('wallet/explore/newest');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getBusinessById(String id) async {
    final response = await _dio.get('wallet/explore/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<void> addFirm(String businessId) async {
    await _dio.post('wallet/add', data: {'businessId': businessId});
  }

  Future<void> removeFirm(String businessId) async {
    await _dio.post('wallet/remove', data: {'businessId': businessId});
  }

  Future<void> reorderWallet(List<String> orderedIds) async {
    await _dio.post('wallet/reorder', data: {'order': orderedIds});
  }

  Future<List<dynamic>> getMyFirms() async {
    final response = await _dio.get('wallet/my');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getTransactions() async {
    final response = await _dio.get(ApiConfig.getTransactions);
    return response.data as List<dynamic>;
  }

  Future<void> submitReview(String transactionId, String businessId, int rating, String comment) async {
    await _dio.post(ApiConfig.createReview, data: {
      'transactionId': transactionId,
      'businessId': businessId,
      'rating': rating,
      'comment': comment
    });
  }

  Future<List<dynamic>> getReviews() async {
    final response = await _dio.get(ApiConfig.getReviews);
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getPendingReviews() async {
    final response = await _dio.get(ApiConfig.getPendingReviews);
    return response.data as List<dynamic>;
  }
  // Account Management
  Future<void> deleteAccount(String password) async {
    await _dio.delete('customer/profile', data: {'password': password});
  }

  // Simulation Methods (for development/demo)
  Future<Map<String, dynamic>> simulateProcessTransaction(String customerId, String businessId) async {
    final response = await _dio.post('transactions/process', data: {
      'customerId': customerId,
      'businessId': businessId,
      'type': 'STAMP'
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> simulateRedeemGift(String customerId, String businessId) async {
    final response = await _dio.post('transactions/process', data: {
      'customerId': customerId,
      'businessId': businessId,
      'type': 'GIFT_REDEEM'
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTransactionHistory(String businessId) async {
    final response = await _dio.get('transactions/history/$businessId');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> simulateAddPoints(String customerId, String businessId, int value) async {
    final response = await _dio.post('transactions/process', data: {
      'customerId': customerId,
      'businessId': businessId,
      'type': 'POINT',
      'value': value,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getAllCampaigns() async {
    try {
      final response = await client.get(ApiConfig.getCampaigns);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getCampaignsByBusiness(String businessId) async {
    final response = await _dio.get('${ApiConfig.businessCampaigns}/$businessId');
    return response.data as List<dynamic>;
  }

  // QR Methods
  Future<Map<String, dynamic>> scanBusinessQR(String token, {String? expectedBusinessId, double? latitude, double? longitude, String? guestId}) async {
    try {
      final response = await _dio.post(
        'qr/validate',
        data: {
          'token': token,
          if (expectedBusinessId != null) 'expectedBusinessId': expectedBusinessId,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (guestId != null) 'guestId': guestId,
        }
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data['error'] == 'Firm Mismatch') {
         throw Exception("FIRM_MISMATCH");
      } else if (e.response?.statusCode == 400 && e.response?.data['error'] == 'Kampanya Bulunamadı') {
         throw Exception("NO_CAMPAIGN:${e.response?.data['message']}");
      } else if (e.response?.statusCode == 403 && e.response?.data['error'] == 'GUEST_LIMIT_REACHED') {
         throw Exception("GUEST_LIMIT_REACHED");
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkConfirmationStatus(String token) async {
    final response = await _dio.get('qr/status/customer/$token');
    return response.data as Map<String, dynamic>;
  }

  Future<void> customerCancelQR(String pollToken) async {
    await _dio.post('qr/customer-cancel', data: {'pollToken': pollToken});
  }

  // Gift Methods
  Future<List<dynamic>> getBusinessGifts(String businessId) async {
    final response = await _dio.get('gifts/business/$businessId');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> prepareRedemption(String businessId, String giftId, {String type = 'POINT'}) async {
    final response = await _dio.post('gifts/prepare-redemption', data: {
      'businessId': businessId,
      'giftId': giftId,
      'redemptionType': type
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> cancelRedemption(String token) async {
    await _dio.post('gifts/cancel-redemption', data: {'token': token});
  }

  Future<Map<String, dynamic>> redeemGift(String businessId, String giftId) async {
    final response = await _dio.post('gifts/redeem', data: {
      'businessId': businessId,
      'giftId': giftId
    });
    return response.data as Map<String, dynamic>;
  }


  // Participation Methods
  Future<List<dynamic>> getMyParticipations() async {
    final response = await _dio.get('participations/my');
    return response.data as List<dynamic>;
  }

  Future<void> joinCampaign(String campaignId) async {
    await _dio.post('participations/join/$campaignId');
  }

  // Product / Menu Methods
  Future<List<dynamic>> getBusinessProducts(String businessId) async {
    final response = await _dio.get('products/$businessId');
    return response.data as List<dynamic>;
  }

  // Notification Methods
  Future<void> updateFcmToken(String token) async {
    try {
      await _dio.post('users/update-fcm-token', data: {'fcmToken': token});
    } catch (_) {
    }
  }
  Future<List<dynamic>> getUserNotifications() async {
    final response = await _dio.get('notifications/user');
    return response.data as List<dynamic>;
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _dio.put('notifications/$notificationId/read');
  }

  Future<void> deleteNotification(String notificationId) async {
    // Soft delete - marks as deleted but keeps in DB for admin panel
    await _dio.put('notifications/$notificationId/soft-delete');
  }

  // ===== GUEST SESSION =====

  Future<Map<String, dynamic>> createGuestSession({String? deviceId}) async {
    final response = await _dio.post('guest/session', data: {
      if (deviceId != null) 'deviceId': deviceId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getGuestSession(String guestId) async {
    final response = await _dio.get('guest/session/$guestId');
    return response.data;
  }

  Future<List<dynamic>> getGuestTransactions(String guestId) async {
    final response = await _dio.get('guest/transactions/$guestId');
    return response.data as List<dynamic>;
  }

  Future<void> deleteGuestSession(String guestId) async {
    await _dio.delete('guest/session/$guestId');
  }

  Future<void> addToGuestWallet(String guestId, String businessId) async {
    await _dio.post('guest/wallet/add', data: {'guestId': guestId, 'businessId': businessId});
  }

  Future<void> removeFromGuestWallet(String guestId, String businessId) async {
    await _dio.post('guest/wallet/remove', data: {'guestId': guestId, 'businessId': businessId});
  }
}

// Simple Retry Logic for transient connection errors
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries = 3;
  final int retryDelayMs = 2000;

  _RetryInterceptor(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    
    // Check if it's a connection/timeout error and we have retries left
    final extra = options.extra;
    final int retryCount = (extra['retry_count'] ?? 0) as int;

    final bool shouldRetry = (err.type == DioExceptionType.connectionError || 
                        err.type == DioExceptionType.connectionTimeout ||
                        err.type == DioExceptionType.unknown) &&
                       retryCount < maxRetries;

    if (shouldRetry) {
      // Retry silently
      
      await Future.delayed(Duration(milliseconds: retryDelayMs));
      
      options.extra['retry_count'] = retryCount + 1;
      
      try {
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } catch (e) {
        // If the retry itself fails, the onError will be called again recursively
        // until maxRetries is reached.
        return; 
      }
    }
    
    return handler.next(err);
  }
}
