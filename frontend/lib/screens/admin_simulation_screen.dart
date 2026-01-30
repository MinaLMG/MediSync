import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../utils/config.dart';
import 'package:intl/intl.dart';

class AdminSimulationScreen extends StatefulWidget {
  final String pharmacyId;
  final String pharmacyName;

  const AdminSimulationScreen({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
  });

  @override
  State<AdminSimulationScreen> createState() => _AdminSimulationScreenState();
}

class _AdminSimulationScreenState extends State<AdminSimulationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _pharmacy;
  List<dynamic> _requests = [];
  List<dynamic> _ledger = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final headers = {'Authorization': 'Bearer $token'};

    try {
      // 1. Fetch Details
      final phRes = await http.get(
        Uri.parse('${Constants.baseUrl}/admin/pharmacies/${widget.pharmacyId}'),
        headers: headers,
      );

      // 2. Fetch Requests (Excesses/Shortages)
      final ordRes = await http.get(
        Uri.parse(
          '${Constants.baseUrl}/admin/pharmacies/${widget.pharmacyId}/orders',
        ),
        headers: headers,
      );

      // 3. Fetch Ledger
      final ledRes = await http.get(
        Uri.parse(
          '${Constants.baseUrl}/admin/pharmacies/${widget.pharmacyId}/balance-history',
        ),
        headers: headers,
      );

      if (mounted) {
        setState(() {
          _pharmacy = json.decode(phRes.body)['data'];
          _requests = json.decode(ordRes.body)['data'];
          _ledger = json.decode(ledRes.body)['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simulating: ${widget.pharmacyName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.info_outline)),
            Tab(text: 'Requests', icon: Icon(Icons.swap_horiz)),
            Tab(text: 'Ledger', icon: Icon(Icons.account_balance_wallet)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildOverview(), _buildRequests(), _buildLedger()],
            ),
    );
  }

  Widget _buildOverview() {
    if (_pharmacy == null)
      return const Center(child: Text('Failed to load details'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text('Current Balance', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  '${(_pharmacy!['balance'] ?? 0).toStringAsFixed(2)} coins',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionHeader('Pharmacy Information'),
        _infoTile('Full Name', _pharmacy!['name']),
        _infoTile('Address', _pharmacy!['address'] ?? 'N/A'),
        _infoTile('Phone', _pharmacy!['phone'] ?? 'N/A'),
        _infoTile('Email', _pharmacy!['email'] ?? 'N/A'),
        const Divider(),
        _sectionHeader('Owner Information'),
        _infoTile('Name', _pharmacy!['owner']?['name'] ?? 'N/A'),
        _infoTile('User Email', _pharmacy!['owner']?['email'] ?? 'N/A'),
        _infoTile('User Phone', _pharmacy!['owner']?['phone'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildRequests() {
    if (_requests.isEmpty)
      return const Center(child: Text('No request history found.'));
    return ListView.builder(
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final item = _requests[index];
        final bool isExcess = item['type'] == 'excess';
        final color = isExcess ? Colors.green : Colors.orange;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(
                isExcess ? Icons.arrow_upward : Icons.arrow_downward,
                color: color,
              ),
            ),
            title: Text(item['product']?['name'] ?? 'Unknown Product'),
            subtitle: Text(
              '${item['remainingQuantity']}/${item['originalQuantity'] ?? item['quantity']} - ${item['displayStatus']}',
            ),
            trailing: Text(
              DateFormat('MMM dd').format(DateTime.parse(item['createdAt'])),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLedger() {
    if (_ledger.isEmpty)
      return const Center(child: Text('No financial history found.'));
    return ListView.builder(
      itemCount: _ledger.length,
      itemBuilder: (context, index) {
        final entry = _ledger[index];
        final double amount = (entry['amount'] ?? 0).toDouble();
        final bool isPositive = amount > 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(entry['description'] ?? 'Transaction'),
            subtitle: Text(
              DateFormat(
                'MMM dd, yyyy HH:mm',
              ).format(DateTime.parse(entry['createdAt'])),
            ),
            trailing: Text(
              '${isPositive ? "+" : ""}${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
