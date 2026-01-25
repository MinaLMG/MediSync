import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class DeliveryRequestProvider with ChangeNotifier {
  List<dynamic> _pendingRequests = [];
  List<dynamic> _myRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get pendingRequests => _pendingRequests;
  List<dynamic> get myRequests => _myRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.tokenKey);
  }

  Future<void> fetchPendingRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/delivery-requests/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _pendingRequests = data['data'];
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch pending requests';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/delivery-requests/my-requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _myRequests = data['data'];
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch your requests';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRequest(String transactionId, String requestType) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/delivery-requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'transactionId': transactionId,
          'requestType': requestType,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        await fetchMyRequests();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to create request';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reviewRequest(String requestId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/delivery-requests/$requestId/review'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await fetchPendingRequests();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to review request';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cleanupRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/delivery-requests/cleanup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to cleanup requests';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
