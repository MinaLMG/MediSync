import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class SettingsProvider with ChangeNotifier {
  Map<String, dynamic>? _settings;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get minCommission =>
      (_settings?['minimumCommission'] ?? 10.0).toDouble();
  double get minimumCommission => minCommission;
  double get shortageCommission =>
      (_settings?['shortageCommission'] ?? 5.0).toDouble();
  double get shortageSellerReward =>
      (_settings?['shortageSellerReward'] ?? 2.5).toDouble();

  Future<void> fetchSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _settings = data['data'];
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch settings';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> updateData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _settings = data['data'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to update settings';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
