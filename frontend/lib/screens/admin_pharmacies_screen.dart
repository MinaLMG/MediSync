import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../utils/config.dart';
import '../utils/search_utils.dart';
import 'admin_simulation_screen.dart';

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
      appBar: AppBar(
        title: const Text('All Pharmacies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPharmacies,
          ),
        ],
      ),
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
                                    '${ph['balance'] ?? 0} coins',
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
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AdminSimulationScreen(
                                                  pharmacyId: ph['_id'],
                                                  pharmacyName: ph['name'],
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.visibility),
                                      label: const Text(
                                        'Simulate This Account',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[800],
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _showCompensationDialog(
                                                context,
                                                ph['_id'],
                                                ph['name'],
                                              ),
                                          icon: const Icon(
                                            Icons.monetization_on,
                                          ),
                                          label: const Text('Add'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[700],
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _showCompensationHistory(
                                                context,
                                                ph['_id'],
                                                ph['name'],
                                              ),
                                          icon: const Icon(Icons.history),
                                          label: const Text('History'),
                                        ),
                                      ),
                                    ],
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

  void _showCompensationDialog(
    BuildContext context,
    String pharmacyId,
    String pharmacyName, {
    Map<String, dynamic>? compensation,
  }) {
    final amountController = TextEditingController(
      text: compensation != null ? compensation['amount'].toString() : '',
    );
    final descriptionController = TextEditingController(
      text: compensation != null ? compensation['description'] : '',
    );
    bool isSubmitting = false;
    final isEdit = compensation != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              isEdit
                  ? 'Edit Compensation'
                  : 'Add Compensation to $pharmacyName',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (Coins)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description / Reason',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final amount = double.tryParse(amountController.text);
                        final description = descriptionController.text.trim();

                        if (amount == null ||
                            amount <= 0 ||
                            description.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter valid amount and description',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        try {
                          final token = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).token;

                          final url = isEdit
                              ? '${Constants.baseUrl}/compensation/${compensation!['_id']}'
                              : '${Constants.baseUrl}/compensation';

                          final method = isEdit ? http.put : http.post;

                          final response = await method(
                            Uri.parse(url),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                            },
                            body: json.encode({
                              if (!isEdit) 'pharmacyId': pharmacyId,
                              'amount': amount,
                              'description': description,
                            }),
                          );

                          final data = json.decode(response.body);

                          if ((response.statusCode == 200 ||
                                  response.statusCode == 201) &&
                              data['success']) {
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEdit
                                        ? 'Compensation updated successfully'
                                        : 'Compensation added successfully',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _fetchPharmacies(); // Refresh list to show new balance
                            }
                          } else {
                            throw Exception(
                              data['message'] ??
                                  'Failed to ${isEdit ? 'update' : 'add'} compensation',
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Update' : 'Add Amount'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCompensationHistory(
    BuildContext context,
    String pharmacyId,
    String pharmacyName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => FutureBuilder(
          future: _fetchCompensations(context, pharmacyId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final compensations = snapshot.data as List<dynamic>? ?? [];

            return Column(
              children: [
                AppBar(
                  title: Text('$pharmacyName History'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                if (compensations.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No compensation history found.'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: compensations.length,
                      itemBuilder: (context, index) {
                        final comp = compensations[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: const Icon(
                              Icons.attach_money,
                              color: Colors.green,
                            ),
                          ),
                          title: Text('${comp['amount']} Coin(s)'),
                          subtitle: Text(comp['description'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  Navigator.pop(context); // Close sheet
                                  _showCompensationDialog(
                                    context,
                                    pharmacyId,
                                    pharmacyName,
                                    compensation: comp,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  _confirmDelete(
                                    context,
                                    comp['_id'],
                                    pharmacyId,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<dynamic>> _fetchCompensations(
    BuildContext context,
    String pharmacyId,
  ) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/compensation/$pharmacyId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        return data['data'];
      }
    } catch (e) {
      print('Error fetching compensations: $e');
    }
    return [];
  }

  void _confirmDelete(
    BuildContext context,
    String compensationId,
    String pharmacyId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure? This will REVERT the balance amount from the pharmacy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close sheet
              await _deleteCompensation(context, compensationId);
              _fetchPharmacies(); // Refresh balance
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete & Revert'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCompensation(
    BuildContext context,
    String compensationId,
  ) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/compensation/$compensationId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Variable deleted and balance reverted'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
