import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _waitingUsers = [];
  List<dynamic> _activeUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) _fetchUsers();
    });
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final url = _tabController.index == 0
        ? '${Constants.baseUrl}/admin/waiting-users'
        : '${Constants.baseUrl}/admin/active-users';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          if (_tabController.index == 0)
            _waitingUsers = data['data'];
          else
            _activeUsers = data['data'];
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New Requests'),
            Tab(text: 'Active Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(_waitingUsers, isWaiting: true),
          _buildUserList(_activeUsers, isWaiting: false),
        ],
      ),
    );
  }

  Widget _buildUserList(List<dynamic> users, {required bool isWaiting}) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (users.isEmpty) return const Center(child: Text('No users found.'));

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final pharmacy = user['pharmacy'];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(user['name']),
            subtitle: Text(
              '${user['email']}\n${pharmacy?['name'] ?? 'No Pharmacy Linked'}',
            ),
            isThreeLine: true,
            trailing: isWaiting
                ? const Icon(Icons.pending_actions, color: Colors.orange)
                : const Icon(Icons.check_circle, color: Colors.green),
            onTap: () => _showUserDetails(user, isWaiting),
          ),
        );
      },
    );
  }

  void _showUserDetails(dynamic user, bool isWaiting) {
    final pharmacy = user['pharmacy'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'User Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ListTile(title: const Text('Name'), subtitle: Text(user['name'])),
            ListTile(title: const Text('Phone'), subtitle: Text(user['phone'])),
            if (pharmacy != null) ...[
              const Divider(),
              Text(
                'Pharmacy Documentation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ListTile(
                title: const Text('Pharmacy Name'),
                subtitle: Text(pharmacy['name']),
              ),
              ListTile(
                title: const Text('Owner Name'),
                subtitle: Text(pharmacy['ownerName']),
              ),
              ListTile(
                title: const Text('National ID'),
                subtitle: Text(pharmacy['nationalId']),
              ),
              _buildImageSection('Pharmacist Card', pharmacy['pharmacistCard']),
              _buildImageSection(
                'Commercial Registry',
                pharmacy['commercialRegistry'],
              ),
              _buildImageSection('Tax Card', pharmacy['taxCard']),
              _buildImageSection('License', pharmacy['pharmacyLicense']),
            ],
            if (isWaiting) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _reviewUser(user['_id'], 'rejected'),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _reviewUser(user['_id'], 'active'),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(String label, String? url) {
    String? fullUrl = url;
    if (url != null && !url.startsWith('http')) {
      final cleanPath = url.replaceAll('\\', '/');
      fullUrl = '${Constants.baseUrl.replaceAll('/api', '')}/$cleanPath';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: fullUrl != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImage(imageUrl: fullUrl!),
                    ),
                  );
                }
              : null,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: fullUrl != null && fullUrl.startsWith('http')
                ? Hero(
                    tag: fullUrl,
                    child: Image.network(
                      fullUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Text('Error loading image')),
                    ),
                  )
                : const Center(
                    child: Text(
                      'No Image',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _reviewUser(String id, String status) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/admin/review-user/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': status}),
    );
    if (json.decode(response.body)['success']) {
      Navigator.pop(context);
      _fetchUsers();
    }
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ),
    );
  }
}
