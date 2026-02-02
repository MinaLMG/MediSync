import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'add_excess_screen.dart';
import 'add_shortage_screen.dart';
import '../providers/excess_provider.dart';
import '../providers/shortage_provider.dart';
import '../providers/requests_history_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../l10n/generated/app_localizations.dart';

class RequestsHistoryScreen extends StatefulWidget {
  const RequestsHistoryScreen({super.key});

  @override
  State<RequestsHistoryScreen> createState() => _RequestsHistoryScreenState();
}

class _RequestsHistoryScreenState extends State<RequestsHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<RequestsHistoryProvider>(
        context,
        listen: false,
      ).fetchRequestsHistory(),
    );
  }

  bool _isNearExpiry(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      DateTime expiry;
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 2) {
          final month = int.parse(parts[0]);
          final year = 2000 + int.parse(parts[1]);
          expiry = DateTime(year, month + 1, 0);
        } else {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          expiry = DateTime(year, month, day);
        }
      } else if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = parts.length > 2 ? int.parse(parts[2]) : 1;
        expiry = DateTime(year, month, day);
      } else {
        return false;
      }
      return expiry.difference(DateTime.now()).inDays < 180;
    } catch (e) {
      return false;
    }
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

  String _getLocalizedStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.statusPending;
      case 'available':
        return l10n.statusAvailable;
      case 'active':
        return l10n.statusActive;
      case 'fulfilled':
        return l10n.statusFulfilled;
      case 'partially_fulfilled':
        return l10n.statusPartiallyFulfilled;
      case 'sold':
        return l10n.statusSold;
      case 'expired':
        return l10n.statusExpired;
      case 'cancelled':
        return l10n.statusCancelled;
      case 'rejected':
        return l10n.statusRejected;
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleRequestsHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<RequestsHistoryProvider>(
              context,
              listen: false,
            ).fetchRequestsHistory(),
          ),
        ],
      ),
      body: Consumer<RequestsHistoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.history.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.history.isEmpty) {
            return Center(child: Text(l10n.msgNoHistoryFound));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                provider.fetchRequestsHistory(),
                Provider.of<NotificationProvider>(
                  context,
                  listen: false,
                ).fetchNotifications(),
              ]);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                final item = provider.history[index];
                final isExcess = item['type'] == 'excess';
                final date = DateTime.parse(item['createdAt']);
                final status = item['displayStatus'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
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
                              color: isExcess
                                  ? Colors.green[50]
                                  : Colors.red[50],
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
                                  isExcess
                                      ? l10n.labelExcessOffer
                                      : l10n.labelShortageRequest,
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
                                    color:
                                        item['expiryDate'] != null &&
                                            _isNearExpiry(item['expiryDate'])
                                        ? Colors.red
                                        : Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight:
                                        item['expiryDate'] != null &&
                                            _isNearExpiry(item['expiryDate'])
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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
                              _getLocalizedStatus(context, status),
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
            ),
          );
        },
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    final bool isExcess = item['type'] == 'excess';
    final l10n = AppLocalizations.of(context)!;

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
              _detailRow(
                l10n.labelType,
                isExcess ? l10n.labelExcess : l10n.labelShortage,
              ),
              _detailRow(l10n.labelVolume, item['volume']['name']),
              _detailRow(
                l10n.labelTotalQuantity,
                (isExcess ? item['originalQuantity'] : item['quantity'])
                    .toString(),
              ),
              _detailRow(
                l10n.labelRemaining,
                item['remainingQuantity'].toString(),
                color: Colors.blue[800],
                isBold: true,
              ),
              if (isExcess) ...[
                _detailRow(l10n.labelPrice, '${item['selectedPrice']} coins'),
                _detailRow(l10n.labelExpiry, item['expiryDate'] ?? 'N/A'),
                if (item['salePercentage'] != null) ...[
                  const Divider(),
                  Text(
                    l10n.labelExcessOffer,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _detailRow(l10n.labelDiscount, '${item['salePercentage']}%'),
                  _detailRow(
                    l10n.labelDiscountAmount,
                    '${item['saleAmount']} coins',
                  ),
                  _detailRow(
                    l10n.labelFinalPrice,
                    '${(item['selectedPrice'] - (item['saleAmount'] ?? 0)).toStringAsFixed(2)} coins',
                    color: Colors.green[700],
                    isBold: true,
                  ),
                ],
              ],

              const Divider(),
              _detailRow(
                'Status',
                _getLocalizedStatus(context, item['displayStatus']),
                color: _getStatusColor(item['displayStatus']),
                isBold: true,
              ),

              if (item['displayStatus'] == 'rejected' &&
                  item['rejectionReason'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.labelRejectionReason,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['rejectionReason'],
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],

              if (item['notes'] != null &&
                  item['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${l10n.labelNotes}:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(item['notes']),
              ],

              const SizedBox(height: 8),
              Text(
                l10n.labelCreated(
                  DateFormat(
                    'yyyy-MM-dd HH:mm',
                  ).format(DateTime.parse(item['createdAt'])),
                ),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionClose),
          ),
          if (item['displayStatus'] == 'pending' ||
              item['displayStatus'] == 'active' ||
              item['displayStatus'] == 'available' ||
              item['displayStatus'] == 'partially_fulfilled' ||
              item['displayStatus'] == 'rejected') ...[
            if (item['displayStatus'] != 'rejected' ||
                Provider.of<AuthProvider>(context, listen: false).userRole ==
                    'admin')
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
                      Provider.of<RequestsHistoryProvider>(
                        context,
                        listen: false,
                      ).fetchRequestsHistory();
                    }
                  });
                },
                child: Text(l10n.actionEdit),
              ),
            TextButton(
              onPressed: () {
                final int total = isExcess
                    ? (item['originalQuantity'] ?? 0)
                    : (item['quantity'] ?? 0);
                final int remaining = item['remainingQuantity'] ?? 0;
                if (total - remaining > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.msgCannotDeleteFulfilledItem(
                          isExcess ? l10n.labelOffer : l10n.labelRequest,
                          isExcess ? l10n.labelTaken : l10n.labelFulfilled,
                        ),
                      ),
                    ),
                  );
                  return;
                }
                _confirmDelete(context, item);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.actionDelete),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogConfirmDelete),
        content: Text(l10n.dialogConfirmDeleteMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel),
          ),
          StatefulBuilder(
            builder: (context, setDialogState) {
              final excessProvider = Provider.of<ExcessProvider>(context);
              final shortageProvider = Provider.of<ShortageProvider>(context);
              final isLoading =
                  excessProvider.isLoading || shortageProvider.isLoading;

              return TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final success = item['type'] == 'excess'
                            ? await excessProvider.deleteExcess(item['_id'])
                            : await shortageProvider.deleteShortage(
                                item['_id'],
                              );

                        if (success) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          Provider.of<RequestsHistoryProvider>(
                            context,
                            listen: false,
                          ).fetchRequestsHistory();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.msgDeletedSuccessfully),
                            ),
                          );
                        }
                      },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.actionDelete),
              );
            },
          ),
        ],
      ),
    );
  }
}
