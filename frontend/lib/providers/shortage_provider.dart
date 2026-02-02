import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import 'auth_provider.dart';

class ShortageProvider with ChangeNotifier {
  AuthProvider _authProvider;
  List<dynamic> _myShortages = [];
  List<dynamic> _activeShortages = [];
  List<dynamic> _fulfilledShortages = [];
  List<String> _globalShortages = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  void update(AuthProvider auth) {
    _authProvider = auth;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  ShortageProvider(this._authProvider);

  List<dynamic> get myShortages => _myShortages;
  List<dynamic> get activeShortages => _activeShortages;
  List<dynamic> get fulfilledShortages => _fulfilledShortages;
  List<String> get globalShortages => _globalShortages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  set isLoading(bool value) {
    _isLoading = value;
    if (!_isDisposed) notifyListeners();
  }

  Future<void> fetchMyShortages() async {
    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/shortage/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _myShortages = data['data'];
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch shortages';
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> fetchActiveShortages() async {
    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/shortage/active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _activeShortages = data['data'];
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch active shortages';
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> fetchFulfilledShortages() async {
    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/shortage/fulfilled'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _fulfilledShortages = data['data'];
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
      } else {
        _errorMessage =
            data['message'] ?? 'Failed to fetch fulfilled shortages';
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<bool> createShortage(Map<String, dynamic> shortageData) async {
    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/shortage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(shortageData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to create shortage';
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/shortage/order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(orderData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to create order';
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  Future<bool> updateShortage(
    String id,
    Map<String, dynamic> shortageData,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/shortage/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(shortageData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to update shortage';
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  Future<bool> deleteShortage(String id) async {
    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/shortage/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to delete shortage';
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  Future<void> fetchGlobalActiveShortages() async {
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/shortage/global-active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _globalShortages = List<String>.from(data['data']);
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch news';
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }
}
