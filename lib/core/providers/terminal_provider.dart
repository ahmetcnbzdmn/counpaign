import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class TerminalProvider extends ChangeNotifier {
  final ApiService _apiService;

  TerminalProvider(this._apiService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<Map<String, dynamic>> processTransaction(String customerId, double amount) async {
    _setLoading(true);
    try {
      final response = await _apiService.client.post(
        ApiConfig.terminalTransaction,
        data: {
          'customerId': customerId,
          'amount': amount,
        },
      );
      return response.data;
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
