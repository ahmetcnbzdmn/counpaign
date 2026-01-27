import 'dart:convert';
import 'package:flutter/services.dart';

class LocationHelper {
  static Map<String, dynamic>? _data;
  static bool _isLoading = false;

  static Future<void> loadData() async {
    if (_data != null || _isLoading) return;
    _isLoading = true;
    try {
      final jsonString = await rootBundle.loadString('lib/core/constants/location_data.json');
      _data = json.decode(jsonString);
    } catch (e) {
      print('Location data loading error: $e');
    } finally {
      _isLoading = false;
    }
  }

  static List<String> getCities() {
    if (_data == null) return [];
    return (_data!['cities'] as List).map((e) => e['name'] as String).toList();
  }

  static List<String> getDistricts(String city) {
    if (_data == null) return [];
    final cityData = (_data!['cities'] as List).firstWhere(
      (e) => e['name'] == city,
      orElse: () => null,
    );
    if (cityData == null) return [];
    
    return (cityData['districts'] as List).map((e) => e['name'] as String).toList();
  }

  static List<String> getNeighborhoods(String city, String district) {
    if (_data == null) return [];
    final cityData = (_data!['cities'] as List).firstWhere(
      (e) => e['name'] == city,
      orElse: () => null,
    );
    if (cityData == null) return [];

    final districtData = (cityData['districts'] as List).firstWhere(
      (e) => e['name'] == district,
      orElse: () => null,
    );
    if (districtData == null) return [];

    return (districtData['neighborhoods'] as List).map((e) => e as String).toList();
  }
}
