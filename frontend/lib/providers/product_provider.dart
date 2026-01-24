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

  List<dynamic> _suggestions = [];
  List<dynamic> get suggestions => _suggestions;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.tokenKey);
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Auth Token Missing');

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
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch products';
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> suggestProduct(Map<String, dynamic> suggestionData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/products/suggest'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(suggestionData),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to suggest product';
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

  Future<void> fetchSuggestions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/products/suggestions'),
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

  Future<bool> updateSuggestionStatus(
    String id,
    String status, {
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/products/suggestions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status, 'adminNotes': notes}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        fetchSuggestions(); // Refresh list
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to update suggestion';
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

  // Admin Methods
  Future<bool> updateProductPrice(
    String hasVolumeId,
    double price,
    bool isAdd, {
    int? index,
  }) async {
    try {
      final token = await _getToken();
      final url = '${Constants.baseUrl}/products/volume/$hasVolumeId/price';
      final response = isAdd
          ? await http.post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode({'price': price}),
            )
          : await http.delete(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode({'priceIndex': index}),
            );

      if (response.statusCode == 200) {
        fetchProducts(); // Refresh
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addVolumeToProduct(
    String productId,
    Map<String, dynamic> volumeData,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/products/$productId/volume'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(volumeData),
      );

      if (response.statusCode == 201) {
        fetchProducts(); // Refresh
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> updateData) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/products/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        fetchProducts(); // Refresh
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
