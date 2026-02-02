import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../utils/config.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.actionSimulate}: ${widget.pharmacyName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.tabOverview, icon: const Icon(Icons.info_outline)),
            Tab(text: l10n.tabRequests, icon: const Icon(Icons.swap_horiz)),
            Tab(
              text: l10n.tabLedger,
              icon: const Icon(Icons.account_balance_wallet),
            ),
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
    final l10n = AppLocalizations.of(context)!;
    if (_pharmacy == null)
      return Center(child: Text(l10n.msgFailedToLoadDetails));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  l10n.labelCurrentBalance,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_pharmacy!['balance'] ?? 0).toStringAsFixed(2)} ${l10n.coinsSuffix}',
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
        _sectionHeader(l10n.labelPharmacyInformation),
        _infoTile(l10n.labelName, _pharmacy!['name']),
        _infoTile(
          l10n.labelAddress,
          _pharmacy!['address'] ?? l10n.labelNotAvailable,
        ),
        _infoTile(
          l10n.labelPhone,
          _pharmacy!['phone'] ?? l10n.labelNotAvailable,
        ),
        _infoTile(
          l10n.labelEmail,
          _pharmacy!['email'] ?? l10n.labelNotAvailable,
        ),
        const Divider(),
        _sectionHeader(l10n.labelOwnerInformation),
        _infoTile(
          l10n.labelName,
          _pharmacy!['owner']?['name'] ?? l10n.labelNotAvailable,
        ),
        _infoTile(
          l10n.labelEmail,
          _pharmacy!['owner']?['email'] ?? l10n.labelNotAvailable,
        ),
        _infoTile(
          l10n.labelPhone,
          _pharmacy!['owner']?['phone'] ?? l10n.labelNotAvailable,
        ),
      ],
    );
  }

  Widget _buildRequests() {
    final l10n = AppLocalizations.of(context)!;
    if (_requests.isEmpty)
      return Center(child: Text(l10n.msgNoRequestHistoryFound));
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
    final l10n = AppLocalizations.of(context)!;
    if (_ledger.isEmpty)
      return Center(child: Text(l10n.msgNoFinancialHistoryFound));
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
