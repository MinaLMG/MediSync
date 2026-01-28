import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import 'auth_provider.dart';

class OrderProvider with ChangeNotifier {
  AuthProvider _authProvider;
  List<dynamic> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  OrderProvider(this._authProvider);

  List<dynamic> get orders => _orders;
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

  // Fetch Orders (Admin)
  Future<void> fetchOrders({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    try {
      String url = '${Constants.baseUrl}/shortage/orders';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _orders = data['data'];
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch orders';
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // Fulfill Item (Create Transaction)
  Future<bool> fulfillItem(Map<String, dynamic> transactionData) async {
    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/transaction/fulfill'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(transactionData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to fulfill item';
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
}
