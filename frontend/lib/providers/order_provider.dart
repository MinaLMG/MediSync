import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_provider.dart';

class OrderProvider with ChangeNotifier {
  AuthProvider authProvider;
  List<dynamic> orders = [];
  bool isLoading = false;
  String? errorMessage;

  void update(AuthProvider auth) {
    authProvider = auth;
  }

  OrderProvider(this.authProvider);

  String get _token => authProvider.token ?? '';

  Future<void> fetchMyOrders() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/orders/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        orders = data['data'];
      } else {
        errorMessage = data['message'] ?? 'Failed to fetch orders';
        orders = [];
      }
    } catch (e) {
      errorMessage = 'Network error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
