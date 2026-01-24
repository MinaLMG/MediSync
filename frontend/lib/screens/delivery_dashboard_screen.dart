import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/delivery_request_provider.dart';
import 'login_screen.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TransactionProvider>(context, listen: false).fetchTransactions();
      Provider.of<DeliveryRequestProvider>(context, listen: false).fetchMyRequests();
    });
  }

  void _showPharmacyInfo(BuildContext context, dynamic pharmacy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pharmacy['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(pharmacy['address'] ?? 'No address provided')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(pharmacy['phone'] ?? 'No phone provided'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _requestAction(BuildContext context, String transactionId, String type) async {
    final success = await Provider.of<DeliveryRequestProvider>(context, listen: false)
        .createRequest(transactionId, type);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request for ${type == 'accept' ? 'Acceptance' : 'Completion'} sent!')),
        );
      } else {
        final error = Provider.of<DeliveryRequestProvider>(context, listen: false).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to send request')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Dashboard'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, DeliveryRequestProvider>(
        builder: (context, transProvider, dripProvider, _) {
          if (transProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = transProvider.transactions
              .where((t) => t['status'] == 'pending' || t['status'] == 'accepted')
              .toList();

          if (transactions.isEmpty) {
            return const Center(child: Text('No pending or accepted transactions.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await transProvider.fetchTransactions();
              await dripProvider.fetchMyRequests();
            },
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final status = tx['status'];
                final shortagePh = tx['stockShortage']['shortage']['pharmacy'];
                final excessPhs = (tx['stockExcessSources'] as List)
                    .map((s) => s['stockExcess']['pharmacy'])
                    .toList();
                
                final hasPendingRequest = dripProvider.myRequests.any(
                  (r) => r['transaction'] == tx['_id'] && r['status'] == 'pending'
                );

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Transaction #${tx['_id'].toString().substring(tx['_id'].toString().length - 6)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const Divider(),
                        const Text('Shortage Pharmacy:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(shortagePh['name']),
                          subtitle: Text(shortagePh['address'] ?? ''),
                          trailing: const Icon(Icons.info_outline, color: Colors.blue),
                          onTap: () => _showPharmacyInfo(context, shortagePh),
                        ),
                        const Text('Excess Pharmacy:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ...excessPhs.map((eph) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(eph['name']),
                          subtitle: Text(eph['address'] ?? ''),
                          trailing: const Icon(Icons.info_outline, color: Colors.blue),
                          onTap: () => _showPharmacyInfo(context, eph),
                        )),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!hasPendingRequest) ...[
                              if (status == 'pending')
                                ElevatedButton.icon(
                                  onPressed: () => _requestAction(context, tx['_id'], 'accept'),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Request Acceptance'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                ),
                              if (status == 'accepted')
                                ElevatedButton.icon(
                                  onPressed: () => _requestAction(context, tx['_id'], 'complete'),
                                  icon: const Icon(Icons.done_all),
                                  label: const Text('Request Completion'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                ),
                            ] else
                              const Chip(
                                label: Text('Request Pending...'),
                                backgroundColor: Colors.amber,
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
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'pending') color = Colors.orange;
    if (status == 'accepted') color = Colors.blue;
    if (status == 'completed') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
