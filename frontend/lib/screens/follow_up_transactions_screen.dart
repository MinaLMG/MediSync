import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';

class FollowUpTransactionsScreen extends StatefulWidget {
  final String? initialStatus;

  const FollowUpTransactionsScreen({super.key, this.initialStatus});

  @override
  State<FollowUpTransactionsScreen> createState() =>
      _FollowUpTransactionsScreenState();
}

class _FollowUpTransactionsScreenState
    extends State<FollowUpTransactionsScreen> {
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialStatus;
    Future.microtask(
      () => Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).fetchTransactions(status: selectedStatus),
    );
  }

  void _updateStatus(String id, String newStatus) async {
    final success = await Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).updateTransactionStatus(id, newStatus);
    if (mounted && success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      // Refresh with current filter
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).fetchTransactions(status: selectedStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Follow-up Transactions')),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: tp.isLoading
                ? const Center(child: CircularProgressIndicator())
                : tp.transactions.isEmpty
                ? const Center(child: Text('No transactions found.'))
                : ListView.builder(
                    itemCount: tp.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = tp.transactions[index];
                      return _buildTransactionCard(tx);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip(null, 'All'),
          _filterChip('pending', 'Pending'),
          _filterChip('accepted', 'Accepted'),
          _filterChip('completed', 'Completed'),
          _filterChip('cancelled', 'Cancelled'),
          _filterChip('rejected', 'Rejected'),
        ],
      ),
    );
  }

  Widget _filterChip(String? status, String label) {
    final isSelected = selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          setState(() => selectedStatus = status);
          Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).fetchTransactions(status: status);
        },
      ),
    );
  }

  Widget _buildTransactionCard(dynamic tx) {
    final shortage = tx['stockShortage']['shortage'];
    final product = shortage['product']['name'];
    final buyer = shortage['pharmacy']['name'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _statusBadge(tx['status']),
              ],
            ),
            const SizedBox(height: 8),
            Text('Buyer: $buyer', style: const TextStyle(color: Colors.blue)),
            Text('Total Qty: ${tx['totalQuantity']}'),
            Text('Total Value: ${tx['totalAmount']} EGP'),
            if (tx['delivery'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.delivery_dining,
                    size: 14,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Delivery: ${tx['delivery']['name']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(),
            const Text(
              'Sellers:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            ...(tx['stockExcessSources'] as List).map(
              (s) => Text(
                '- ${s['stockExcess']['pharmacy']['name']} (${s['quantity']} units)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            if (tx['status'] != 'completed' && tx['status'] != 'cancelled')
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (tx['status'] == 'pending')
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Accept'),
                                content: const Text(
                                  'Are you sure you want to accept this transaction?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _updateStatus(tx['_id'], 'accepted');
                                    },
                                    child: const Text('Yes, Accept'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Accept'),
                        ),
                      if (tx['status'] == 'accepted')
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Complete'),
                                content: const Text(
                                  'Are you sure you want to mark this transaction as completed?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _updateStatus(tx['_id'], 'completed');
                                    },
                                    child: const Text('Yes, Complete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Complete'),
                        ),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Cancel'),
                              content: const Text(
                                'Are you sure you want to cancel this transaction? All quantities will be returned to their respective pharmacies.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _updateStatus(tx['_id'], 'cancelled');
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Yes, Cancel'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                  if (Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).userRole ==
                          'admin' &&
                      tx['delivery'] != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Detach Delivery'),
                              content: const Text(
                                'This will remove the assigned delivery person. The transaction will become available for assignment again.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Close'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final success =
                                        await Provider.of<TransactionProvider>(
                                          context,
                                          listen: false,
                                        ).unassignTransaction(tx['_id']);
                                    if (mounted && success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Delivery person detached',
                                          ),
                                        ),
                                      );
                                      // Refresh with current filter
                                      Provider.of<TransactionProvider>(
                                        context,
                                        listen: false,
                                      ).fetchTransactions(
                                        status: selectedStatus,
                                      );
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                  ),
                                  child: const Text('Detach'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_remove, size: 16),
                        label: const Text('Detach Delivery'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
            Text(
              'Created: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(tx['createdAt']))}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'accepted':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
