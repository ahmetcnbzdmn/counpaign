import 'dart:ui';
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
      onError: (DioException e, handler) {
        // Handle global errors (e.g. 401 Unauthorized -> Logout)
        if (e.response?.statusCode == 401) {
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
    print("[DEBUG] ApiService: Calling getMyFirms()");
    final response = await _dio.get('/wallet/my');
    print("[DEBUG] ApiService: getMyFirms returned ${response.data.length} items");
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
    print("[DEBUG] ApiService: Calling getTransactionHistory for $businessId");
    final response = await _dio.get('/transactions/history/$businessId');
    print("[DEBUG] ApiService: getTransactionHistory returned ${response.data.length} items");
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
  Future<Map<String, dynamic>> scanBusinessQR(String token, {String? expectedBusinessId}) async {
    try {
      final response = await _dio.post(
        '/qr/validate',
        data: {
          'token': token,
          if (expectedBusinessId != null) 'expectedBusinessId': expectedBusinessId,
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


  // Product / Menu Methods
  Future<List<dynamic>> getBusinessProducts(String businessId) async {
    final response = await _dio.get('/products/$businessId');
    return response.data as List<dynamic>;
  }

  // Notification Methods
  Future<void> updateFcmToken(String token) async {
    try {
      await _dio.post('/users/update-fcm-token', data: {'fcmToken': token});
      print("[DEBUG] FCM Token updated on backend");
    } catch (e) {
      print('Update FCM Token Error: $e');
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
