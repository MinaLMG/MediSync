import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class ExcessProvider with ChangeNotifier {
  List<dynamic> _pendingExcesses = [];
  List<dynamic> _availableExcesses = [];
  List<dynamic> _marketExcesses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get pendingExcesses => _pendingExcesses;
  List<dynamic> get availableExcesses => _availableExcesses;
  List<dynamic> get marketExcesses => _marketExcesses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Add Excess
  Future<bool> addExcess(Map<String, dynamic> excessData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/excess'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(excessData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to add excess';
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

  // Fetch Pending Excesses (Admin)
  Future<void> fetchPendingExcesses() async {
    await _fetchExcesses('/excess/pending', (data) => _pendingExcesses = data);
  }

  // Fetch Market Excesses (Pharmacy)
  Future<void> fetchMarketExcesses() async {
    await _fetchExcesses(
      '/excess/market?excludeShortageFulfillment=true',
      (data) => _marketExcesses = data,
    );
  }

  // Fetch Available Excesses (Admin/User)
  Future<void> fetchAvailableExcesses() async {
    await _fetchExcesses(
      '/excess/available',
      (data) => _availableExcesses = data,
    );
  }

  Future<void> _fetchExcesses(
    String endpoint,
    Function(List<dynamic>) onSuccess,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        onSuccess(data['data']);
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch excesses';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Excess
  Future<bool> updateExcess(String id, Map<String, dynamic> updateData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/excess/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        fetchPendingExcesses();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Update failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      notifyListeners();
      return false;
    }
  }

  // Approve Excess
  Future<bool> approveExcess(String id) async {
    return await _performAction('/excess/$id/approve', 'PUT');
  }

  // Reject Excess
  Future<bool> rejectExcess(String id, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/excess/$id/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'rejectionReason': reason}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        fetchPendingExcesses();
        fetchAvailableExcesses();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Rejection failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete Excess
  Future<bool> deleteExcess(String id) async {
    return await _performAction('/excess/$id', 'DELETE');
  }

  Future<bool> _performAction(String endpoint, String method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      final uri = Uri.parse('${Constants.baseUrl}$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      http.Response response;
      if (method == 'PUT') {
        response = await http.put(uri, headers: headers);
      } else {
        response = await http.delete(uri, headers: headers);
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Refresh lists
        fetchPendingExcesses();
        fetchAvailableExcesses();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Action failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      notifyListeners();
      return false;
    }
  }
}
