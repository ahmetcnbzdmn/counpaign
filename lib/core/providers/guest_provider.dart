import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class GuestProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  String? _guestId;
  int _campaignUsageCount = 0;
  List<Map<String, dynamic>> _wallet = [];

  String? get guestId => _guestId;
  int get campaignUsageCount => _campaignUsageCount;
  int get usagesLeft => (3 - _campaignUsageCount).clamp(0, 3);
  bool get isGuest => _guestId != null;
  bool get hasUsagesLeft => usagesLeft > 0;
  List<Map<String, dynamic>> get wallet => _wallet;

  GuestProvider(this._apiService, this._storageService);

  /// Load existing guest session from local storage, then sync wallet from backend
  Future<void> loadGuestSession() async {
    final stored = await _storageService.getGuestSession();
    if (stored != null) {
      try {
        final data = jsonDecode(stored) as Map<String, dynamic>;
        _guestId = data['guestId'] as String?;
        _campaignUsageCount = (data['campaignUsageCount'] as int?) ?? 0;
        // Load cached wallet from local storage
        final walletJson = data['wallet'];
        if (walletJson is List) {
          _wallet = walletJson.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        notifyListeners();
        // Sync from backend to get fresh wallet + usage count
        await syncFromBackend();
      } catch (_) {
        await _storageService.clearGuestSession();
      }
    }
  }

  /// Start a new guest session — uses stable deviceId to recover existing session
  Future<void> startGuestSession() async {
    try {
      final deviceId = await _storageService.getOrCreateInstallationId();
      final result = await _apiService.createGuestSession(deviceId: deviceId);
      _guestId = result['guestId'] as String;
      _campaignUsageCount = (result['campaignUsageCount'] as int?) ?? 0;
      _wallet = _mergeWithRemote(_parseWallet(result['wallet']));

      await _saveLocal();
      notifyListeners();
    } catch (e) {
      debugPrint('GuestProvider startGuestSession error: $e');
      rethrow;
    }
  }

  /// Increment local usage count (called after successful QR scan)
  void incrementUsage() {
    _campaignUsageCount++;
    _saveLocal();
    notifyListeners();
  }

  /// Sync usage count + wallet from backend
  Future<void> syncFromBackend() async {
    if (_guestId == null) return;
    try {
      final result = await _apiService.getGuestSession(_guestId!);
      _campaignUsageCount = (result['campaignUsageCount'] as int?) ?? _campaignUsageCount;
      _wallet = _mergeWithRemote(_parseWallet(result['wallet']));
      await _saveLocal();
      notifyListeners();
    } catch (e) {
      final errStr = e.toString();
      // Session expired or deleted on server — clear local state
      if (errStr.contains('404') || errStr.contains('bulunamadı')) {
        await _storageService.clearGuestSession();
        _guestId = null;
        _campaignUsageCount = 0;
        _wallet = [];
        notifyListeners();
      }
      // Other errors (network, server) are silently ignored to avoid disrupting UX
    }
  }

  /// Add a firm to guest wallet
  Future<void> addToWallet(String businessId, Map<String, dynamic> businessData) async {
    if (_guestId == null) return;
    // Optimistic update
    if (!_wallet.any((f) => _firmId(f) == businessId)) {
      _wallet.add({...businessData, '_id': businessId, 'id': businessId});
      await _saveLocal();
      notifyListeners();
    }
    // Persist to backend (fire and forget)
    try {
      await _apiService.addToGuestWallet(_guestId!, businessId);
      await syncFromBackend();
    } catch (e) {
      debugPrint('addToGuestWallet error: $e');
    }
  }

  /// Remove a firm from guest wallet
  Future<void> removeFromWallet(String businessId) async {
    if (_guestId == null) return;
    _wallet.removeWhere((f) => _firmId(f) == businessId);
    await _saveLocal();
    notifyListeners();
    try {
      await _apiService.removeFromGuestWallet(_guestId!, businessId);
    } catch (e) {
      debugPrint('removeFromGuestWallet error: $e');
    }
  }

  /// Clear guest session (called after successful registration/login or manual delete)
  Future<void> clear({bool deleteFromServer = false}) async {
    final idToDelete = _guestId;
    _guestId = null;
    _campaignUsageCount = 0;
    _wallet = [];
    // If user explicitly deletes, also reset installationId so backend
    // won't recover the same session via deviceId
    await _storageService.clearGuestSession(resetInstallationId: deleteFromServer);
    notifyListeners();
    if (deleteFromServer && idToDelete != null) {
      try {
        await _apiService.deleteGuestSession(idToDelete);
      } catch (e) {
        debugPrint('deleteGuestSession error (non-blocking): $e');
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────

  String _firmId(Map<String, dynamic> f) =>
      (f['_id'] ?? f['id'] ?? '').toString();

  List<Map<String, dynamic>> _parseWallet(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Merges remote wallet items (dynamic data) with local ones (static data)
  List<Map<String, dynamic>> _mergeWithRemote(List<Map<String, dynamic>> remoteWallet) {
    return remoteWallet.map((remoteItem) {
      final firmId = _firmId(remoteItem);
      // Find matching local item to preserve its static data (name, logo, ratings, etc.)
      final localItem = _wallet.firstWhere(
        (l) => _firmId(l) == firmId,
        orElse: () => <String, dynamic>{},
      );
      
      // Merge: Local static data + remote dynamic data (stamps, points)
      return {
        ...localItem, 
        ...remoteItem, // Remote overrides stamps/points
        '_id': firmId,
        'id': firmId,
      };
    }).toList();
  }

  Future<void> _saveLocal() async {
    await _storageService.saveGuestSession(jsonEncode({
      'guestId': _guestId,
      'campaignUsageCount': _campaignUsageCount,
      'wallet': _wallet,
    }));
  }
}
