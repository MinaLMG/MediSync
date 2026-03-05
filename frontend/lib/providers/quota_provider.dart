import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class QuotaProvider with ChangeNotifier {
  List<dynamic> _quotas = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get quotas => _quotas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setErrorMessage(dynamic response) {
    if (response != null && response['message'] != null) {
      _errorMessage = response['message'].toString();
    } else {
      _errorMessage = 'An unexpected error occurred';
    }
  }

  Future<void> fetchQuotas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiService.getRequest('/quotas');
      if (response['success']) {
        _quotas = response['data'];
      } else {
        _setErrorMessage(response);
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching quotas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createQuota({
    required String productId,
    required String volumeId,
    required double price,
    required String expiryDate,
    required double salePercentage,
    required int maxQuantity,
  }) async {
    _errorMessage = null;
    try {
      final response = await ApiService.postRequest('/quotas', {
        'product': productId,
        'volume': volumeId,
        'price': price,
        'expiryDate': expiryDate,
        'salePercentage': salePercentage,
        'maxQuantity': maxQuantity,
      });
      if (response['success']) {
        await fetchQuotas();
        return true;
      } else {
        _setErrorMessage(response);
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error creating quota: $e');
    }
    notifyListeners();
    return false;
  }

  Future<bool> updateQuota(String id, int maxQuantity) async {
    _errorMessage = null;
    try {
      final response = await ApiService.putRequest('/quotas/$id', {
        'maxQuantity': maxQuantity,
      });
      if (response['success']) {
        await fetchQuotas();
        return true;
      } else {
        _setErrorMessage(response);
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating quota: $e');
    }
    notifyListeners();
    return false;
  }

  Future<bool> deleteQuota(String id) async {
    _errorMessage = null;
    try {
      final response = await ApiService.deleteRequest('/quotas/$id');
      if (response['success']) {
        await fetchQuotas();
        return true;
      } else {
        _setErrorMessage(response);
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting quota: $e');
    }
    notifyListeners();
    return false;
  }
}
