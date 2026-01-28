import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import 'auth_provider.dart';

class RequestsHistoryProvider with ChangeNotifier {
  AuthProvider _authProvider;
  List<dynamic> _history = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  RequestsHistoryProvider(this._authProvider);

  List<dynamic> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void update(AuthProvider auth) {
    _authProvider = auth;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Fetch Requests History (Pharmacy's Excesses & Shortages)
  Future<void> fetchRequestsHistory() async {
    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/requests-history/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _history = data['data'];
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch history';
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
