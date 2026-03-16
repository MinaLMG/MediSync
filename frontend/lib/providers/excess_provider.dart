import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class ExcessProvider with ChangeNotifier {
  List<dynamic> _pendingExcesses = [];
  List<dynamic> _availableExcesses = [];
  List<dynamic> _fulfilledExcesses = [];
  List<dynamic> _marketExcesses = [];
  List<dynamic> _hubs = [];
  List<dynamic> _marketInsight = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get pendingExcesses => _pendingExcesses;
  List<dynamic> get availableExcesses => _availableExcesses;
  List<dynamic> get fulfilledExcesses => _fulfilledExcesses;
  List<dynamic> get marketExcesses => _marketExcesses;
  List<dynamic> get hubs => _hubs;
  List<dynamic> get marketInsight => _marketInsight;
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

  // Fetch Fulfilled Excesses (Admin)
  Future<void> fetchFulfilledExcesses() async {
    await _fetchExcesses(
      '/excess/fulfilled',
      (data) => _fulfilledExcesses = data,
    );
  }

  // Fetch Market Excesses (Pharmacy)
  Future<void> fetchMarketExcesses({bool detailed = false}) async {
    String url = '/excess/market?excludeShortageFulfillment=true';
    if (detailed) {
      url += '&detailed=true';
    }
    await _fetchExcesses(url, (data) => _marketExcesses = data);
  }

  // Fetch Available Excesses (Admin/User)
  Future<void> fetchAvailableExcesses() async {
    await _fetchExcesses(
      '/excess/available',
      (data) => _availableExcesses = data,
    );
  }

  // Fetch My Excesses (Hub/Pharmacy)
  List<dynamic> _myExcesses = [];
  List<dynamic> get myExcesses => _myExcesses;

  Future<void> fetchMyExcesses() async {
    await _fetchExcesses('/excess/my', (data) => _myExcesses = data);
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

  Future<bool> updateExcess(String id, Map<String, dynamic> updateData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
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
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Update failed';
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

  // Approve Excess
  Future<bool> approveExcess(String id) async {
    return await _performAction('/excess/$id/approve', 'PUT');
  }

  Future<bool> rejectExcess(String id, String reason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
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
        _isLoading = false;
        fetchPendingExcesses();
        fetchAvailableExcesses();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Rejection failed';
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

  // Delete Excess
  Future<bool> deleteExcess(String id) async {
    return await _performAction('/excess/$id', 'DELETE');
  }

  Future<bool> _performAction(String endpoint, String method) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
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
        _isLoading = false;
        // Refresh lists
        fetchPendingExcesses();
        fetchAvailableExcesses();
        fetchFulfilledExcesses();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Action failed';
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

  // Fetch Hubs (Admin)
  Future<void> fetchHubs() async {
    await _fetchExcesses('/admin/hubs', (data) => _hubs = data);
  }

  // Add to Hub (Admin)
  Future<bool> addToHub(String excessId, String hubId, int quantity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/excess/add-to-hub'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'excessId': excessId,
          'hubId': hubId,
          'quantity': quantity,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _isLoading = false;
        fetchAvailableExcesses();
        fetchFulfilledExcesses();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Add to hub failed';
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

  // Fetch Market Insight
  Future<void> fetchMarketInsight(
    String productId,
    String volumeId,
    double price,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    _marketInsight = [];
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      final response = await http.get(
        Uri.parse(
          '${Constants.baseUrl}/excess/market-insight?product=$productId&volume=$volumeId&price=$price',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _marketInsight = data['data'];
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch market insight';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}
