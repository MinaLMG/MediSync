import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balance_history_provider.dart';
import 'package:intl/intl.dart';

class BalanceHistoryScreen extends StatefulWidget {
  final String? pharmacyId; // null for self
  const BalanceHistoryScreen({super.key, this.pharmacyId});

  @override
  State<BalanceHistoryScreen> createState() => _BalanceHistoryScreenState();
}

class _BalanceHistoryScreenState extends State<BalanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (widget.pharmacyId != null) {
        Provider.of<BalanceHistoryProvider>(
          context,
          listen: false,
        ).fetchPharmacyHistory(widget.pharmacyId!);
      } else {
        Provider.of<BalanceHistoryProvider>(
          context,
          listen: false,
        ).fetchMyHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance History'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Consumer<BalanceHistoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }

          if (provider.history.isEmpty) {
            return const Center(child: Text('No balance history found.'));
          }

          return ListView.builder(
            itemCount: provider.history.length,
            itemBuilder: (context, index) {
              final item = provider.history[index];
              return _buildHistoryItem(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final amount = item['amount'] ?? 0.0;
    final isNegative = amount < 0;
    final date = DateTime.parse(item['createdAt']).toLocal();
    final formattedDate = DateFormat('MMM dd, yyyy HH:mm').format(date);

    IconData icon;
    Color color;

    switch (item['type']) {
      case 'transaction_revenue':
        icon = Icons.add_circle_outline;
        color = Colors.green;
        break;
      case 'transaction_payment':
        icon = Icons.remove_circle_outline;
        color = Colors.red;
        break;
      case 'expenses':
        icon = Icons.money_off;
        color = Colors.orange;
        break;
      default:
        icon = Icons.account_balance_wallet;
        color = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          item['description'] ?? 'Balance Update',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formattedDate),
            const SizedBox(height: 4),
            Text(
              'Balance: ${item['previousBalance'].toStringAsFixed(2)} → ${item['newBalance'].toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          '${isNegative ? "" : "+"}${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isNegative ? Colors.red : Colors.green,
          ),
        ),
        onTap: () {
          _showDetailsDialog(item);
        },
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        final details = item['details'] as Map<String, dynamic>? ?? {};

        return AlertDialog(
          title: const Text('Entry Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Description', item['description']),
                _detailRow(
                  'Type',
                  item['type'].toString().replaceAll('_', ' ').toUpperCase(),
                ),
                _detailRow(
                  'Date',
                  DateFormat(
                    'yyyy-MM-dd HH:mm:ss',
                  ).format(DateTime.parse(item['createdAt']).toLocal()),
                ),
                const Divider(),
                _detailRow('Amount', item['amount'].toStringAsFixed(2)),
                _detailRow(
                  'Prev Balance',
                  item['previousBalance'].toStringAsFixed(2),
                ),
                _detailRow(
                  'New Balance',
                  item['newBalance'].toStringAsFixed(2),
                ),
                if (details.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Breakdown:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...details.entries.map(
                    (e) => _detailRow(
                      e.key
                          .replaceAllMapped(
                            RegExp(r'([a-z])([A-Z])'),
                            (Match m) => '${m[1]} ${m[2]}',
                          )
                          .capitalize(),
                      e.value.toString(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A', style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return "";
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
