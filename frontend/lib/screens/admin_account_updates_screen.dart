import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/app_suggestion_provider.dart';
import '../utils/config.dart';
import '../utils/ui_utils.dart';

class AdminAccountUpdatesScreen extends StatefulWidget {
  const AdminAccountUpdatesScreen({super.key});

  @override
  State<AdminAccountUpdatesScreen> createState() =>
      _AdminAccountUpdatesScreenState();
}

class _AdminAccountUpdatesScreenState extends State<AdminAccountUpdatesScreen> {
  bool _isLoading = false;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingUpdates();
  }

  Future<void> _fetchPendingUpdates() async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/admin/pending-updates'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data != null && data['success']) {
        setState(() => _users = data['data']);
      }
    } catch (e) {
      debugPrint('Error fetching updates: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reviewUpdate(String userId, String action) async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/admin/review-update/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'action': action}),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Update ${action == 'approve' ? 'applied' : 'rejected'}',
              ),
            ),
          );
        }
        _fetchPendingUpdates();
        if (mounted) {
          Provider.of<AppSuggestionProvider>(
            context,
            listen: false,
          ).fetchPendingCounts();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Update Requests'),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingUpdates,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(child: Text('No pending updates found.'))
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final updates = user['pendingUpdate'];
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(child: Icon(Icons.person)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  user['email'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        const Text(
                          'Requested Changes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (updates['name'] != null &&
                            updates['name'] != user['name'])
                          _buildDiffItem('Name', user['name'], updates['name']),

                        if (updates['email'] != null &&
                            updates['email'] != user['email'])
                          _buildDiffItem(
                            'Email',
                            user['email'],
                            updates['email'],
                          ),

                        if (updates['phone'] != null &&
                            updates['phone'] != user['phone'])
                          _buildDiffItem(
                            'Phone',
                            user['phone'],
                            updates['phone'],
                          ),

                        if (updates['pharmacy'] != null &&
                            user['pharmacy'] != null) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Pharmacy Changes:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          if (updates['pharmacy']['name'] != null &&
                              updates['pharmacy']['name'] !=
                                  user['pharmacy']['name'])
                            _buildDiffItem(
                              'Ph. Name',
                              user['pharmacy']['name'],
                              updates['pharmacy']['name'],
                              onTap: () => UIUtils.showPharmacyInfo(
                                context,
                                user['pharmacy'],
                              ),
                            ),
                          if (updates['pharmacy']['phone'] != null &&
                              updates['pharmacy']['phone'] !=
                                  user['pharmacy']['phone'])
                            _buildDiffItem(
                              'Ph. Phone',
                              user['pharmacy']['phone'],
                              updates['pharmacy']['phone'],
                            ),
                          if (updates['pharmacy']['address'] != null &&
                              updates['pharmacy']['address'] !=
                                  user['pharmacy']['address'])
                            _buildDiffItem(
                              'Ph. Address',
                              user['pharmacy']['address'],
                              updates['pharmacy']['address'],
                            ),
                        ],

                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () =>
                                          _reviewUpdate(user['_id'], 'reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                child: const Text('Reject Update'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () =>
                                          _reviewUpdate(user['_id'], 'approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Approve Update'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDiffItem(
    String label,
    String oldVal,
    String newVal, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  oldVal,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward, size: 16),
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Text(
                    newVal,
                    style: TextStyle(
                      fontSize: 14,
                      color: onTap != null ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
