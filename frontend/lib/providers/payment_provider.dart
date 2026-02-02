import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class PaymentProvider with ChangeNotifier {
  List<dynamic> _payments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPayments({String? status, String? type}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> query = {};
      if (status != null) query['status'] = status;
      if (type != null) query['type'] = type;

      final response = await ApiService.getRequest('/payment', query);
      if (response['success']) {
        _payments = response['data'];
      } else {
        _errorMessage = response['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPayment(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.postRequest('/payment', data);
      if (response['success']) {
        _payments.insert(0, response['data']);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'];
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

  Future<bool> reviewPayment(String id, String action, {String? note}) async {
    try {
      final response = await ApiService.putRequest('/payment/$id/review', {
        'action': action,
        'adminNote': note,
      });

      if (response['success']) {
        final index = _payments.indexWhere((p) => p['_id'] == id);
        if (index != -1) {
          _payments[index] = response['data'];
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response['message'];
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
