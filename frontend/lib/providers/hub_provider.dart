import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart';

class HubProvider with ChangeNotifier {
  final String? token;
  bool _isLoading = false;

  List<dynamic> _owners = [];
  List<dynamic> _ownerPayments = [];
  List<dynamic> _purchaseInvoices = [];
  List<dynamic> _salesInvoices = [];
  List<dynamic> _pharmaciesList = [];
  List<dynamic> _selectedPharmacyExcesses = [];
  Map<String, dynamic>? _hubCashSummary;
  Map<String, dynamic>? _hubSystemSummary;
  Map<String, dynamic>? _adminSummary;

  HubProvider(this.token);

  bool get isLoading => _isLoading;
  List<dynamic> get owners => _owners;
  List<dynamic> get ownerPayments => _ownerPayments;
  List<dynamic> get purchaseInvoices => _purchaseInvoices;
  List<dynamic> get salesInvoices => _salesInvoices;
  Map<String, dynamic>? get hubCashSummary => _hubCashSummary;
  Map<String, dynamic>? get hubSystemSummary => _hubSystemSummary;
  Map<String, dynamic>? get adminSummary => _adminSummary;
  List<dynamic> get pharmaciesList => _pharmaciesList;
  List<dynamic> get selectedPharmacyExcesses => _selectedPharmacyExcesses;

  // --- Owners ---
  Future<void> fetchOwners() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/owners'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        _owners = data['data'];
      }
    } catch (e) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createOwner(String name) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/owners'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': name}),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        await fetchOwners();
        return true;
      }
    } catch (e) {}
    return false;
  }

  Future<bool> updateOwner(String id, String name) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/owners/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': name}),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        await fetchOwners();
        return true;
      }
    } catch (e) {}
    return false;
  }

  // --- Payments ---
  Future<void> fetchOwnerPayments() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/owner-payments'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        _ownerPayments = data['data'];
      }
    } catch (e) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createOwnerPayment(
    String ownerId,
    double value, {
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/owner-payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'ownerId': ownerId, 'value': value, 'notes': notes}),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        await fetchOwnerPayments();
        await fetchHubSummary();
        return true;
      }
    } catch (e) {}
    return false;
  }

  Future<bool> updateOwnerPayment(
    String id,
    double value, {
    String? notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/owner-payments/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'value': value, 'notes': notes}),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        await fetchOwnerPayments();
        await fetchHubSummary();
        return true;
      }
    } catch (e) {}
    return false;
  }

  Future<bool> deleteOwnerPayment(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/owner-payments/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        await fetchOwnerPayments();
        await fetchHubSummary();
        return true;
      }
    } catch (e) {}
    return false;
  }

  // --- Invoices ---
  Future<void> fetchPurchaseInvoices() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/purchase-invoices'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        _purchaseInvoices = data['data'];
      }
    } catch (e) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> createPurchaseInvoice(
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/purchase-invoices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(invoiceData),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        await fetchPurchaseInvoices();
        await fetchHubSummary();
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updatePurchaseInvoice(
    String id,
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/purchase-invoices/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(invoiceData),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        await fetchPurchaseInvoices();
        await fetchHubSummary();
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deletePurchaseInvoice(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/purchase-invoices/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        await fetchPurchaseInvoices();
        await fetchHubSummary();
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> fetchSalesInvoices() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/sales-invoices'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        _salesInvoices = data['data'];
      }
    } catch (e) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> createSalesInvoice(
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/sales-invoices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(invoiceData),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        await fetchSalesInvoices();
        await fetchHubSummary();
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateSalesInvoice(
    String id,
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/sales-invoices/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(invoiceData),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        await fetchSalesInvoices();
        await fetchHubSummary();
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteSalesInvoice(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/sales-invoices/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        await fetchSalesInvoices();
        await fetchHubSummary();
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Summaries ---
  Future<void> fetchHubCashSummary() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/payment/hub-cash'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        _hubCashSummary = data['data'];
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<void> fetchHubSystemSummary() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/excess/hub-system'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        _hubSystemSummary = data['data'];
        notifyListeners();
      }
    } catch (e) {}
  }

  @Deprecated('Use fetchHubCashSummary or fetchHubSystemSummary')
  Future<void> fetchHubSummary() async {
    await fetchHubCashSummary();
    await fetchHubSystemSummary();
  }

  Future<void> fetchAdminSummary({String? startDate, String? endDate}) async {
    _isLoading = true;
    notifyListeners();
    try {
      String query = '';
      if (startDate != null) query += 'startDate=$startDate&';
      if (endDate != null) query += 'endDate=$endDate';

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/summaries/admin?$query'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        _adminSummary = data['data'];
      }
    } catch (e) {}
    _isLoading = false;
    notifyListeners();
  }

  // --- Calculations Helper Endpoints ---
  Future<void> fetchPharmaciesList() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/summaries/pharmacies-list'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        _pharmaciesList = data['data'];
      }
    } catch (e) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPharmacyExcesses(String pharmacyId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/excess/pharmacy/$pharmacyId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        _selectedPharmacyExcesses = data['data'];
      }
    } catch (e) {}
    _isLoading = false;
    notifyListeners();
  }
}
