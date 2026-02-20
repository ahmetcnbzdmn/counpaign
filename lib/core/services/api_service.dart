import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  final Dio _dio;
  final StorageService _storageService;

  ApiService(this._storageService)
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Handle global errors (e.g. 401 Unauthorized)
        if (e.response?.statusCode == 401) {
          final refreshToken = await _storageService.getRefreshToken();
          
          if (refreshToken != null) {
            try {
              // Create a new Dio instance to avoid interceptor loop
              final refreshDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
              final refreshResponse = await refreshDio.post(
                '/auth/refresh-token',
                data: {'refreshToken': refreshToken},
              );

              if (refreshResponse.statusCode == 200) {
                final newToken = refreshResponse.data['token'];
                await _storageService.saveToken(newToken);

                // Retry original request with new token
                final options = e.requestOptions;
                options.headers['Authorization'] = 'Bearer $newToken';
                
                // Create a generic response using the resolved token
                final retryResponse = await _dio.fetch(options);
                return handler.resolve(retryResponse);
              }
            } catch (refreshErr) {
              debugPrint('Token refresh failed: $refreshErr');
              // Token refresh failed, continue to trigger unauthorized
            }
          }

          onUnauthorized?.call();
        }
        return handler.next(e);
      },
    ));
  }

  // Callback to handle 401 errors (e.g. trigger logout)
  VoidCallback? onUnauthorized;

  Dio get client => _dio;

  // Wallet / Firm Methods
  Future<List<dynamic>> getAvailableFirms() async {
    final response = await _dio.get('/wallet/explore');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getNewestBusinesses() async {
    final response = await _dio.get('/wallet/explore/newest');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getBusinessById(String id) async {
    final response = await _dio.get('/wallet/explore/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<void> addFirm(String businessId) async {
    await _dio.post('/wallet/add', data: {'businessId': businessId});
  }

  Future<void> removeFirm(String businessId) async {
    await _dio.post('/wallet/remove', data: {'businessId': businessId});
  }

  Future<void> reorderWallet(List<String> orderedIds) async {
    await _dio.post('/wallet/reorder', data: {'order': orderedIds});
  }

  Future<List<dynamic>> getMyFirms() async {
    debugPrint("[DEBUG] ApiService: Calling getMyFirms()");
    final response = await _dio.get('/wallet/my');
    debugPrint("[DEBUG] ApiService: getMyFirms returned ${response.data.length} items");
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

  // Simulation Methods (for development/demo)
  Future<Map<String, dynamic>> simulateProcessTransaction(String customerId, String businessId) async {
    final response = await _dio.post('/transactions/process', data: {
      'customerId': customerId,
      'businessId': businessId,
      'type': 'STAMP'
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> simulateRedeemGift(String customerId, String businessId) async {
    final response = await _dio.post('/transactions/process', data: {
      'customerId': customerId,
      'businessId': businessId,
      'type': 'GIFT_REDEEM'
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTransactionHistory(String businessId) async {
    debugPrint("[DEBUG] ApiService: Calling getTransactionHistory for $businessId");
    final response = await _dio.get('/transactions/history/$businessId');
    debugPrint("[DEBUG] ApiService: getTransactionHistory returned ${response.data.length} items");
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> simulateAddPoints(String customerId, String businessId, int value) async {
    final response = await _dio.post('/transactions/process', data: {
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
  Future<Map<String, dynamic>> scanBusinessQR(String token, {String? expectedBusinessId, double? latitude, double? longitude}) async {
    try {
      final response = await _dio.post(
        '/qr/validate',
        data: {
          'token': token,
          if (expectedBusinessId != null) 'expectedBusinessId': expectedBusinessId,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        }
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data['error'] == 'Firm Mismatch') {
         throw Exception("FIRM_MISMATCH");
      }
      rethrow; // Replaced _handleDioError(e) as it's not defined in the provided context.
    }
  }

  Future<Map<String, dynamic>> checkConfirmationStatus(String token) async {
    final response = await _dio.get('/qr/status/customer/$token');
    return response.data as Map<String, dynamic>;
  }

  // Gift Methods
  Future<List<dynamic>> getBusinessGifts(String businessId) async {
    final response = await _dio.get('/gifts/business/$businessId');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> prepareRedemption(String businessId, String giftId, {String type = 'POINT'}) async {
    final response = await _dio.post('/gifts/prepare-redemption', data: {
      'businessId': businessId,
      'giftId': giftId,
      'redemptionType': type
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> cancelRedemption(String token) async {
    await _dio.post('/gifts/cancel-redemption', data: {'token': token});
  }

  Future<Map<String, dynamic>> redeemGift(String businessId, String giftId) async {
    final response = await _dio.post('/gifts/redeem', data: {
      'businessId': businessId,
      'giftId': giftId
    });
    return response.data as Map<String, dynamic>;
  }


  // Participation Methods
  Future<List<dynamic>> getMyParticipations() async {
    final response = await _dio.get('/participations/my');
    return response.data as List<dynamic>;
  }

  Future<void> joinCampaign(String campaignId) async {
    await _dio.post('/participations/join/$campaignId');
  }

  // Product / Menu Methods
  Future<List<dynamic>> getBusinessProducts(String businessId) async {
    final response = await _dio.get('/products/$businessId');
    return response.data as List<dynamic>;
  }

  // Notification Methods
  Future<void> updateFcmToken(String token) async {
    try {
      await _dio.post('/users/update-fcm-token', data: {'fcmToken': token});
      debugPrint("[DEBUG] FCM Token updated on backend");
    } catch (e) {
      debugPrint('Update FCM Token Error: $e');
    }
  }
  Future<List<dynamic>> getUserNotifications() async {
    final response = await _dio.get('/notifications/user');
    return response.data as List<dynamic>;
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _dio.put('/notifications/$notificationId/read');
  }

  Future<void> deleteNotification(String notificationId) async {
    // Soft delete - marks as deleted but keeps in DB for admin panel
    await _dio.put('/notifications/$notificationId/soft-delete');
  }
}
