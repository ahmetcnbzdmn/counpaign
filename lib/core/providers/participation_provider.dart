import 'package:flutter/material.dart';
import '../models/participation_model.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';

class ParticipationProvider with ChangeNotifier {
  final ApiService _apiService;
  List<ParticipationModel> _participations = [];
  bool _isLoading = false;

  ParticipationProvider(this._apiService) {
    fetchMyParticipations();
  }

  List<ParticipationModel> get participations => _participations;
  bool get isLoading => _isLoading;

  Future<void> fetchMyParticipations() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.getMyParticipations();
      _participations = data.map((json) => ParticipationModel.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching participations: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinCampaign(String campaignId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.joinCampaign(campaignId);
      await fetchMyParticipations();
      return true;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        // Already joined case - treat as soft success
        await fetchMyParticipations();
        return true;
      }
      print("Error joining campaign: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isParticipating(String campaignId) {
    return _participations.any((p) => p.campaignId == campaignId && !p.isCompleted);
  }

  Future<Map<String, dynamic>> scanBusinessQR(String token, {String? expectedBusinessId}) async {
    try {
      _isLoading = true;
      notifyListeners();
      final result = await _apiService.scanBusinessQR(token, expectedBusinessId: expectedBusinessId);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkConfirmationStatus(String token) async {
    return await _apiService.checkConfirmationStatus(token);
  }
}
