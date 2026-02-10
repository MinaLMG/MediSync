import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balance_history_provider.dart';
import 'package:intl/intl.dart';
import '../l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.menuBalanceHistory),
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
            return Center(child: Text(l10n.msgNoBalanceHistory));
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
    final l10n = AppLocalizations.of(context)!;
    final amount = (item['amount'] is int)
        ? (item['amount'] as int).toDouble()
        : (item['amount'] as double? ?? 0.0);
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
          (Localizations.localeOf(context).languageCode == 'ar' &&
                  item['description_ar'] != null)
              ? item['description_ar']
              : (item['description'] ?? l10n.labelBalanceUpdate),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formattedDate),
            const SizedBox(height: 4),
            Text(
              '${l10n.labelBalance}: ${item['previousBalance']?.toStringAsFixed(2)} → ${item['newBalance']?.toStringAsFixed(2)}',
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        final details = item['details'] as Map<String, dynamic>? ?? {};

        return AlertDialog(
          title: Text(
            l10n.ticketTitle(item['_id']?.toString().substring(0, 6) ?? '...'),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(
                  l10n.labelName,
                  (Localizations.localeOf(context).languageCode == 'ar' &&
                          item['description_ar'] != null)
                      ? item['description_ar']
                      : item['description'],
                ),
                _detailRow(
                  l10n.labelType,
                  item['type'].toString().replaceAll('_', ' ').toUpperCase(),
                ),
                _detailRow(
                  l10n.labelDate,
                  DateFormat(
                    'yyyy-MM-dd HH:mm:ss',
                  ).format(DateTime.parse(item['createdAt']).toLocal()),
                ),
                const Divider(),
                _detailRow(
                  l10n.amountLabel,
                  item['amount']?.toStringAsFixed(2),
                ),
                _detailRow(
                  l10n.labelPrevBalance,
                  item['previousBalance']?.toStringAsFixed(2),
                ),
                _detailRow(
                  l10n.labelNewBalance,
                  item['newBalance']?.toStringAsFixed(2),
                ),
                if (details.isNotEmpty) ...[
                  const Divider(),
                  if (details['sources'] != null && details['sources'] is List)
                    ...(details['sources'] as List).map((source) {
                      final s = source as Map<String, dynamic>;
                      final base = (s['baseAmount'] as num?)?.toDouble() ?? 0.0;
                      final ratio =
                          (s['saleRatio'] as num? ??
                                  s['commissionRatio'] as num? ??
                                  0.0)
                              .toDouble();

                      final baseAmountStr = base.toStringAsFixed(2);
                      final ratioStr = (ratio * 100).toStringAsFixed(0);
                      final ratioValueStr = (base * ratio).toStringAsFixed(2);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.labelBreakdown} (Source ${details['sources'].indexOf(source) + 1})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _detailRow('Base Amount', '\$$baseAmountStr'),
                            _detailRow('Ratio', '$ratioStr%'),
                            _detailRow('Ratio Value', '\$$ratioValueStr'),
                          ],
                        ),
                      );
                    }).toList(),

                  // Show other internal details excluding noise and source breakdown
                  ...details.entries
                      .where(
                        (e) => ![
                          'systemMinComm',
                          'offeredRatio',
                          'commission_at_creation',
                          'bonus_at_creation',
                          'totalBuyerEffect',
                          'sources',
                        ].contains(e.key),
                      )
                      .map(
                        (e) =>
                            _detailRow(e.key.capitalize(), e.value.toString()),
                      ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.actionDone),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
