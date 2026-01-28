import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class AppSuggestionProvider with ChangeNotifier {
  List<dynamic> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Pending counts for Admin
  int _waitingUsersCount = 0;
  int _pendingExcessCount = 0;
  int _pendingProductSuggestionsCount = 0;
  int _appSuggestionsCount = 0;
  int _deliveryRequestsCount = 0;
  int _pendingAccountUpdatesCount = 0;
  int _pendingOrdersCount = 0;

  List<dynamic> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get waitingUsersCount => _waitingUsersCount;
  int get pendingExcessCount => _pendingExcessCount;
  int get pendingProductSuggestionsCount => _pendingProductSuggestionsCount;
  int get appSuggestionsCount => _appSuggestionsCount;
  int get deliveryRequestsCount => _deliveryRequestsCount;
  int get pendingAccountUpdatesCount => _pendingAccountUpdatesCount;
  int get pendingOrdersCount => _pendingOrdersCount;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.tokenKey);
  }

  Future<void> fetchPendingCounts() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/admin/pending-counts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _waitingUsersCount = data['data']['waitingUsers'] ?? 0;
        _pendingExcessCount = data['data']['pendingExcesses'] ?? 0;
        _pendingProductSuggestionsCount =
            data['data']['pendingSuggestions'] ?? 0;
        _appSuggestionsCount = data['data']['appSuggestions'] ?? 0;
        _deliveryRequestsCount = data['data']['deliveryRequests'] ?? 0;
        _pendingAccountUpdatesCount =
            data['data']['pendingAccountUpdates'] ?? 0;
        _pendingOrdersCount = data['data']['pendingOrders'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching pending counts: $e');
    }
  }

  Future<bool> submitSuggestion(String content) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/suggestions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'content': content}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to submit suggestion';
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

  Future<void> fetchAllSuggestions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/suggestions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _suggestions = data['data'];
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch suggestions';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsSeen(String id) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/suggestions/$id/seen'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final index = _suggestions.indexWhere((s) => s['_id'] == id);
        if (index != -1) {
          _suggestions[index]['seen'] = true;
          if (_appSuggestionsCount > 0) {
            _appSuggestionsCount--;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking suggestion as seen: $e');
    }
  }
}
