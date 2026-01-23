import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'add_excess_screen.dart';
import 'add_shortage_screen.dart';
import '../providers/excess_provider.dart';
import '../providers/shortage_provider.dart';
import '../providers/order_provider.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<OrderProvider>(context, listen: false).fetchMyOrders(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'available':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'sold':
        return Colors.grey;
      case 'fulfilled':
        return Colors.grey;
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders History')),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.orders.isEmpty) {
            return const Center(child: Text('No history found'));
          }

          return ListView.builder(
            itemCount: provider.orders.length,
            itemBuilder: (context, index) {
              final item = provider.orders[index];
              final isExcess = item['type'] == 'excess';
              final date = DateTime.parse(item['createdAt']);
              final status = item['displayStatus'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    // TODO: Navigate to Details Screen
                    _showDetailsDialog(context, item);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon Type
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isExcess ? Colors.green[50] : Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isExcess ? Icons.add_circle : Icons.remove_circle,
                            color: isExcess ? Colors.green : Colors.red,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['product']['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isExcess ? 'Excess' : 'Shortage',
                                style: TextStyle(
                                  color: isExcess
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy').format(date),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(status).withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    final bool isExcess = item['type'] == 'excess';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Column(
          children: [
            Icon(
              isExcess ? Icons.add_circle : Icons.remove_circle,
              color: isExcess ? Colors.green : Colors.red,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              item['product']['name'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Type', isExcess ? 'Excess' : 'Shortage'),
              _detailRow('Volume', item['volume']['name']),
              _detailRow(
                'Total Quantity',
                (isExcess ? item['originalQuantity'] : item['quantity'])
                    .toString(),
              ),
              _detailRow(
                'Remaining',
                item['remainingQuantity'].toString(),
                color: Colors.blue[800],
                isBold: true,
              ),
              if (isExcess) ...[
                _detailRow('Price', '${item['selectedPrice']} EGP'),
                _detailRow(
                  'Expiry Date',
                  DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.parse(item['expiryDate'])),
                ),
                if (item['salePercentage'] != null) ...[
                  const Divider(),
                  const Text(
                    'Sale Offer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _detailRow('Discount', '${item['salePercentage']}%'),
                  _detailRow('Discount Amount', '${item['saleAmount']} EGP'),
                  _detailRow(
                    'Final Price',
                    '${(item['selectedPrice'] - (item['saleAmount'] ?? 0)).toStringAsFixed(2)} EGP',
                    color: Colors.green[700],
                    isBold: true,
                  ),
                ],
              ],
              if (!isExcess && item['maxSurplus'] != null)
                _detailRow('Max Surplus', '${item['maxSurplus']} EGP'),

              const Divider(),
              _detailRow(
                'Status',
                item['displayStatus'].toString().toUpperCase(),
                color: _getStatusColor(item['displayStatus']),
                isBold: true,
              ),

              if (item['notes'] != null &&
                  item['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(item['notes']),
              ],

              const SizedBox(height: 8),
              Text(
                'Created: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(item['createdAt']))}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (item['displayStatus'] == 'pending' ||
              item['displayStatus'] == 'active' ||
              item['displayStatus'] == 'available') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => isExcess
                        ? AddExcessScreen(initialData: item)
                        : AddShortageScreen(initialData: item),
                  ),
                ).then((_) {
                  if (context.mounted) {
                    Provider.of<OrderProvider>(
                      context,
                      listen: false,
                    ).fetchMyOrders();
                  }
                });
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () => _confirmDelete(context, item),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = item['type'] == 'excess'
                  ? await Provider.of<ExcessProvider>(
                      context,
                      listen: false,
                    ).deleteExcess(item['_id'])
                  : await Provider.of<ShortageProvider>(
                      context,
                      listen: false,
                    ).deleteShortage(item['_id']);

              if (success) {
                Provider.of<OrderProvider>(
                  context,
                  listen: false,
                ).fetchMyOrders();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleted successfully')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
