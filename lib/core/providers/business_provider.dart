import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class BusinessProvider extends ChangeNotifier {
  final ApiService _apiService;

  BusinessProvider(this._apiService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _terminals = [];
  List<dynamic> get terminals => _terminals;

  List<dynamic> _myFirms = [];
  List<dynamic> get myFirms => _myFirms;

  List<dynamic> _exploreFirms = [];
  List<dynamic> get exploreFirms => _exploreFirms;

  // Track currently viewed firm (Context-Aware Scanner Guard)
  String? _currentViewedFirmId;
  String? _currentViewedFirmName;
  Map<String, dynamic>? _currentViewedFirmExtra;

  int _homeSelectedFirmIndex = 0;
  int get homeSelectedFirmIndex => _homeSelectedFirmIndex;

  void setHomeSelectedFirmIndex(int index) {
    _homeSelectedFirmIndex = index;
  }

  String? get currentViewedFirmId => _currentViewedFirmId;
  String? get currentViewedFirmName => _currentViewedFirmName;
  Map<String, dynamic>? get currentViewedFirmExtra => _currentViewedFirmExtra;

  void setContextFirm(String id, String name, [Map<String, dynamic>? extra]) {
    _currentViewedFirmId = id;
    _currentViewedFirmName = name;
    _currentViewedFirmExtra = extra;
  }

  void clearContextFirm() {
    _currentViewedFirmId = null;
    _currentViewedFirmName = null;
    _currentViewedFirmExtra = null;
  }

  bool isFirmInWallet(String businessId) {
    return _myFirms.any((firm) => firm['id'] == businessId);
  }

  Future<void> fetchTerminals() async {
    _setLoading(true);
    try {
      final response = await _apiService.client.get(ApiConfig.getTerminals);
      _terminals = response.data;
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMyFirms() async {
    _setLoading(true);
    try {
      final firms = await _apiService.getMyFirms();
      _myFirms = firms;
      notifyListeners();
    } catch (e) {
      // Don't rethrow to avoid crashing UI, just log or handle
      debugPrint("Error fetching my firms: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchExploreFirms() async {
    _setLoading(true);
    try {
      final firms = await _apiService.getAvailableFirms();
      _exploreFirms = firms;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching explore firms: $e");
    } finally {
      _setLoading(false);
    }
  }

  void reorderFirms(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _myFirms.removeAt(oldIndex);
    _myFirms.insert(newIndex, item);
    notifyListeners();
  }

  Future<void> createTerminal(String name, String id, String password) async {
    _setLoading(true);
    try {
      await _apiService.client.post(
        ApiConfig.createTerminal,
        data: {
          'terminalName': name,
          'terminalId': id,
          'password': password,
        },
      );
      // Refresh list
      await fetchTerminals();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeFirm(String businessId, String password) async {
    // Optimistic update could be tricky with password verification, so we wait for API
    _setLoading(true);
    try {
      await _apiService.client.post(
        ApiConfig.removeBusiness,
        data: {
          'businessId': businessId,
          'password': password,
        },
      );
      // Refresh list to sync order
      await fetchMyFirms();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
