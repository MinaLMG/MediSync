import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/delivery_request_provider.dart';
import '../providers/app_suggestion_provider.dart';

class AdminDeliveryRequestsScreen extends StatefulWidget {
  const AdminDeliveryRequestsScreen({super.key});

  @override
  State<AdminDeliveryRequestsScreen> createState() =>
      _AdminDeliveryRequestsScreenState();
}

class _AdminDeliveryRequestsScreenState
    extends State<AdminDeliveryRequestsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<DeliveryRequestProvider>(
        context,
        listen: false,
      ).fetchPendingRequests();
    });
  }

  void _reviewRequest(String requestId, String status) async {
    final success = await Provider.of<DeliveryRequestProvider>(
      context,
      listen: false,
    ).reviewRequest(requestId, status);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request ${status == 'approved' ? 'Approved' : 'Rejected'}',
            ),
          ),
        );
        // Refresh counts for badges
        Provider.of<AppSuggestionProvider>(
          context,
          listen: false,
        ).fetchPendingCounts();
      } else {
        final error = Provider.of<DeliveryRequestProvider>(
          context,
          listen: false,
        ).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to review request')),
        );
      }
    }
  }

  void _cleanup() async {
    final success = await Provider.of<DeliveryRequestProvider>(
      context,
      listen: false,
    ).cleanupRequests();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Old requests cleaned up (older than 1 month)'),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cleanup failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Cleanup old requests',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cleanup'),
                  content: const Text(
                    'Delete all approved/rejected requests older than 1 month?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _cleanup();
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<DeliveryRequestProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.pendingRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.pendingRequests.isEmpty) {
            return const Center(child: Text('No pending delivery requests.'));
          }

          return RefreshIndicator(
            onRefresh: provider.fetchPendingRequests,
            child: ListView.builder(
              itemCount: provider.pendingRequests.length,
              itemBuilder: (context, index) {
                final request = provider.pendingRequests[index];
                final delivery = request['delivery'];
                final tx = request['transaction'];
                final date = DateTime.parse(request['createdAt']).toLocal();

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              delivery['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, HH:mm').format(date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Phone: ${delivery['phone']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transaction: ${tx['_id'].toString().substring(tx['_id'].toString().length - 6)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Requested Status: ${request['requestType'].toUpperCase()}',
                                style: TextStyle(
                                  color: request['requestType'] == 'accept'
                                      ? Colors.blue
                                      : Colors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _confirmAction(
                                title: 'Reject Request',
                                message:
                                    'Are you sure you want to reject this delivery request?',
                                onConfirm: () =>
                                    _reviewRequest(request['_id'], 'rejected'),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _confirmAction(
                                title: 'Approve Request',
                                message:
                                    'Are you sure you want to approve this delivery request?',
                                onConfirm: () =>
                                    _reviewRequest(request['_id'], 'approved'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
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

  void _confirmAction({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
