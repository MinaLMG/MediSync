import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/search_utils.dart';

class AdminPharmaciesScreen extends StatefulWidget {
  const AdminPharmaciesScreen({super.key});

  @override
  State<AdminPharmaciesScreen> createState() => _AdminPharmaciesScreenState();
}

class _AdminPharmaciesScreenState extends State<AdminPharmaciesScreen> {
  bool _isLoading = false;
  List<dynamic> _pharmacies = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPharmacies();
  }

  Future<void> _fetchPharmacies() async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/admin/pharmacies'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() => _pharmacies = data['data']);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPharmacies = _pharmacies.where((ph) {
      return SearchUtils.matches(ph['name'], _searchQuery) ||
          SearchUtils.matches(ph['email'], _searchQuery) ||
          SearchUtils.matches(ph['phone'], _searchQuery) ||
          SearchUtils.matches(ph['address'], _searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('All Pharmacies')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search pharmacies (* for wildcard)...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPharmacies.isEmpty
                ? const Center(child: Text('No pharmacies found.'))
                : ListView.builder(
                    itemCount: filteredPharmacies.length,
                    itemBuilder: (context, index) {
                      final ph = filteredPharmacies[index];
                      final owner = ph['owner'];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ExpansionTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.local_pharmacy),
                          ),
                          title: Text(ph['name']),
                          subtitle: Text(ph['address'] ?? 'No Address info'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _detailRow('Owner Name', ph['ownerName']),
                                  _detailRow('Email', ph['email']),
                                  _detailRow('Phone', ph['phone']),
                                  _detailRow(
                                    'Balance',
                                    '${ph['balance'] ?? 0} EGP',
                                  ),
                                  const Divider(),
                                  const Text(
                                    'Linked User Account',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  _detailRow(
                                    'User Name',
                                    owner?['name'] ?? 'N/A',
                                  ),
                                  _detailRow(
                                    'User Email',
                                    owner?['email'] ?? 'N/A',
                                  ),
                                  _detailRow(
                                    'Account Status',
                                    ph['status']?.toUpperCase() ?? 'UNKNOWN',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
