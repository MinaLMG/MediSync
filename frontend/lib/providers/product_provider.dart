import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ProductProvider with ChangeNotifier {
  List<dynamic> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      if (token == null) {
        _errorMessage = 'Authentication error';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _products = data['data'];
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch products';
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
