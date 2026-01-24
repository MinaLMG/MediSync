import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String? get token => _token; // Public getter
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get userId => _currentUser?['_id'];
  String? get errorMessage => _errorMessage;
  String? get userRole => _currentUser?['role'];
  String? get userStatus => _currentUser?['status'];

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _token = data['data']['token'];
        _currentUser = data['data'];

        // Save to Shared Preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(Constants.tokenKey, _token!);
        await prefs.setString(Constants.userDataKey, json.encode(_currentUser));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Login failed';
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

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _token = data['data']['token'];
        _currentUser = data['data'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(Constants.tokenKey, _token!);
        await prefs.setString(Constants.userDataKey, json.encode(_currentUser));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Registration failed';
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

  Future<bool> linkPharmacy(
    Map<String, String> fields,
    Map<String, String> filePaths,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${Constants.baseUrl}/auth/link-pharmacy');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $_token';

      // Add fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add files
      for (var entry in filePaths.entries) {
        if (entry.value.isNotEmpty) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, entry.value),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _currentUser = data['data']['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(Constants.userDataKey, json.encode(_currentUser));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to link pharmacy';
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

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Constants.tokenKey);
    await prefs.remove(Constants.userDataKey);
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(Constants.tokenKey)) return;

    final token = prefs.getString(Constants.tokenKey);
    final userDataStr = prefs.getString(Constants.userDataKey);

    if (token != null && userDataStr != null) {
      _token = token;
      _currentUser = json.decode(userDataStr);
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _currentUser = data['data'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(Constants.userDataKey, json.encode(_currentUser));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }
  }
}
