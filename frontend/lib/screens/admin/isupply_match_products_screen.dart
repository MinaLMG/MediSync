import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/config.dart';

class ISupplyMatchProductsScreen extends StatefulWidget {
  const ISupplyMatchProductsScreen({super.key});

  @override
  State<ISupplyMatchProductsScreen> createState() =>
      _ISupplyMatchProductsScreenState();
}

class _ISupplyMatchProductsScreenState
    extends State<ISupplyMatchProductsScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _matchData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRandomUnmatchedProduct();
  }

  Future<void> _fetchRandomUnmatchedProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _matchData = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey) ?? '';

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/admin/isupply/random-unmatched'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _matchData = json.decode(response.body);
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch data: ${json.decode(response.body)['message'] ?? response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _matchProduct(Map<String, dynamic> choice, int index) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey) ?? '';
      final response = await http.patch(
        Uri.parse('${Constants.baseUrl}/admin/isupply/match'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'product_id': _matchData!['product']['_id'],
          'choice': choice,
          'index': index,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product Matched Successfully!')),
        );
        _fetchRandomUnmatchedProduct();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to match: ${json.decode(response.body)['message']}',
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rejectChoice() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey) ?? '';
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/admin/isupply/reject-choice'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'product_id': _matchData!['product']['_id']}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Search cache cleared for this product.'),
          ),
        );
        _fetchRandomUnmatchedProduct();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to clear cache.')));
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match iSupply Products'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: _isLoading ? null : _fetchRandomUnmatchedProduct,
            tooltip: 'Skip this product',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchRandomUnmatchedProduct,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : _matchData == null
          ? const Center(child: Text('No data found.'))
          : _buildMatchView(),
    );
  }

  Widget _buildMatchView() {
    final product = _matchData!['product'];
    final searchTerm = _matchData!['searchTerm'];
    final List matches = _matchData!['matches'] ?? [];

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.blue[50],
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Our Medisync Product:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product['name'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text('Search Term Used: $searchTerm'),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: matches.isEmpty
              ? const Center(
                  child: Text(
                    'No cached choices found for this product.\nRun the background script to populate.',
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final choice = matches[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(
                                choice['title'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Price: ${choice['price']} EGP',
                                style: const TextStyle(color: Colors.green),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[900],
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _matchProduct(choice, index),
                                child: const Text('Match'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _rejectChoice,
                          icon: const Icon(
                            Icons.delete_sweep,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'None of these products match (Clear Cache)',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
