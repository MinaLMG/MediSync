import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import 'auth_provider.dart';

class TransactionProvider with ChangeNotifier {
  AuthProvider authProvider;
  List<dynamic> matchableProducts = [];
  Map<String, dynamic> currentMatches = {'shortages': [], 'excesses': []};
  List<dynamic> transactions = [];
  bool isLoading = false;
  String? errorMessage;

  void update(AuthProvider auth) {
    authProvider = auth;
  }

  TransactionProvider(this.authProvider);

  String get _token => authProvider.token ?? '';

  // Get products with potential matches
  Future<void> fetchMatchableProducts({String search = ''}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/transaction/matchable?search=$search'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        matchableProducts = data['data'];
      } else {
        errorMessage = data['message'] ?? 'Failed to fetch matchable products';
      }
    } catch (e) {
      errorMessage = 'Network error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Get details for a specific product matching
  Future<Map<String, dynamic>> fetchMatchesForProduct(
    String productId, {
    double? price,
    bool excludeShortageFulfillment = false,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      String url = '${Constants.baseUrl}/transaction/matches/$productId';
      List<String> queryParams = [];
      if (price != null) {
        queryParams.add('price=$price');
      }
      if (excludeShortageFulfillment) {
        queryParams.add('excludeShortageFulfillment=true');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        currentMatches = data['data'];
        return data['data'];
      } else {
        errorMessage = data['message'] ?? 'Failed to fetch matches';
        return {'shortages': [], 'excesses': []};
      }
    } catch (e) {
      errorMessage = 'Network error: $e';
      return {'shortages': [], 'excesses': []};
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Create Transaction
  Future<bool> createTransaction(Map<String, dynamic> transactionData) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/transaction'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(transactionData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return true;
      } else {
        errorMessage = data['message'] ?? 'Failed to create transaction';
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

  // Fetch Transactions with filter
  Future<void> fetchTransactions({String? status}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      String url = '${Constants.baseUrl}/transaction';
      if (status != null) url += '?status=$status';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        transactions = data['data'];
      } else {
        errorMessage = data['message'] ?? 'Failed to fetch transactions';
      }
    } catch (e) {
      errorMessage = 'Network error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Update Transaction Status
  Future<bool> updateTransactionStatus(String id, String status) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http
          .put(
            Uri.parse('${Constants.baseUrl}/transaction/$id/status'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: json.encode({'status': status}),
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return true;
      } else {
        errorMessage = data['message'] ?? 'Failed to update status';
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

  // Assign Delivery User to Transaction
  Future<bool> assignTransaction(String id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http
          .put(
            Uri.parse('${Constants.baseUrl}/transaction/$id/assign'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final updatedTx = data['data'];
        // Update local list for instant UI response
        final index = transactions.indexWhere((t) => t['_id'] == id);
        if (index != -1) {
          transactions[index] = updatedTx;
          notifyListeners();
        }
        return true;
      } else {
        errorMessage = data['message'] ?? 'Failed to assign transaction';
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

  // Unassign Delivery User from Transaction
  Future<bool> unassignTransaction(String id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/transaction/$id/unassign'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return true;
      } else {
        errorMessage = data['message'] ?? 'Failed to unassign transaction';
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

  // Revert a completed transaction
  Future<bool> revertTransaction(
    String id,
    Map<String, dynamic> reversalTicket,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('${Constants.baseUrl}/transaction/$id/revert'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: json.encode(reversalTicket),
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return true;
      } else {
        errorMessage = data['message'] ?? 'Failed to revert transaction';
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

  // Update an existing reversal ticket
  Future<bool> updateReversalTicket(
    String ticketId,
    Map<String, dynamic> ticketData,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http
          .put(
            Uri.parse('${Constants.baseUrl}/transaction/reversal/$ticketId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: json.encode(ticketData),
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return true;
      } else {
        errorMessage = data['message'] ?? 'Failed to update ticket';
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

  // Update transaction ratios
  Future<bool> updateTransactionRatios(
    String id,
    Map<String, dynamic> ratioData,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/transaction/$id/ratios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(ratioData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return true;
      } else {
        errorMessage = data['message'] ?? 'Failed to update ratios';
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

  // Update an existing transaction (modify quantities and resources)
  Future<bool> updateTransaction(
    String id,
    Map<String, dynamic> transactionData,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http
          .put(
            Uri.parse('${Constants.baseUrl}/transaction/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: json.encode(transactionData),
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return true;
      } else {
        errorMessage = data['message'] ?? 'Failed to update transaction';
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
}
