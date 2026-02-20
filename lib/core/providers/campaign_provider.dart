import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/campaign_model.dart';

class CampaignProvider extends ChangeNotifier {
  final ApiService _apiService;

  CampaignProvider(this._apiService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final Map<String, List<CampaignModel>> _businessCampaigns = {};
  List<CampaignModel> _globalCampaigns = [];

  List<CampaignModel> get allCampaigns => _globalCampaigns; // Now returns fetched global list
  List<CampaignModel> get businessCampaignsFlat => _businessCampaigns.values.expand((x) => x).toList();

  List<CampaignModel> getCampaignsForBusiness(String businessId) {
    return _businessCampaigns[businessId] ?? [];
  }

  CampaignModel? getPromotedCampaign(String businessId) {
    final campaigns = getCampaignsForBusiness(businessId);
    if (campaigns.isEmpty) return null;
    
    // Find promoted one or take the first one
    return campaigns.firstWhere(
      (c) => c.isPromoted,
      orElse: () => campaigns.first,
    );
  }

  Future<void> fetchAllCampaigns() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.getAllCampaigns();
      _globalCampaigns = data.map((json) => CampaignModel.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching all campaigns: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCampaigns(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.getCampaignsByBusiness(businessId);
      _businessCampaigns[businessId] = data.map((json) => CampaignModel.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching campaigns: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
