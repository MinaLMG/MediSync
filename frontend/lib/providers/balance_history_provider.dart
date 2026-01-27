import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class BalanceHistoryProvider with ChangeNotifier {
  List<dynamic> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/balance-history/my'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _history = data['data'];
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch history';
      }
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPharmacyHistory(String pharmacyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/balance-history/$pharmacyId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _history = data['data'];
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch history';
      }
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
