import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_provider.dart';

class ShortageProvider with ChangeNotifier {
  final AuthProvider authProvider;
  List<dynamic> activeShortages = [];
  List<dynamic> myShortages = [];
  bool isLoading = false;
  String? errorMessage;

  ShortageProvider(this.authProvider);

  String get _token => authProvider.token ?? '';

  // Admin: Get all active shortages
  Future<void> fetchActiveShortages() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/shortage/active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        activeShortages = data['data'];
      } else {
        errorMessage = data['message'] ?? 'Failed to fetch shortages';
      }
    } catch (e) {
      errorMessage = 'Network error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Manager: Get my shortages
  Future<void> fetchMyShortages() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/shortage/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        myShortages = data['data'];
      } else {
        errorMessage = data['message'] ?? 'Failed to fetch my shortages';
      }
    } catch (e) {
      errorMessage = 'Network error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Manager: Add Shortage
  Future<bool> addShortage(Map<String, dynamic> shortageData) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/shortage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(shortageData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        // Refresh local lists if needed
        return true;
      } else {
        errorMessage = data['message'] ?? 'Failed to add shortage';
        return false;
      }
    } catch (e) {
      errorMessage = 'Network error: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Manager: Update Shortage
  Future<bool> updateShortage(
    String id,
    Map<String, dynamic> updateData,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/shortage/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(updateData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return true;
      } else {
        errorMessage = data['message'] ?? 'Failed to update shortage';
        return false;
      }
    } catch (e) {
      errorMessage = 'Network error: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Admin/Manager: Delete Shortage
  Future<bool> deleteShortage(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/shortage/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        activeShortages.removeWhere((item) => item['_id'] == id);
        myShortages.removeWhere((item) => item['_id'] == id);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
