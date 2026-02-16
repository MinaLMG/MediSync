import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hub_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class CashBalanceHistoryScreen extends StatefulWidget {
  const CashBalanceHistoryScreen({super.key});

  @override
  State<CashBalanceHistoryScreen> createState() =>
      _CashBalanceHistoryScreenState();
}

class _CashBalanceHistoryScreenState extends State<CashBalanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<HubProvider>(context, listen: false).fetchHubCashSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cashBalance),
        backgroundColor: Colors.green,
      ),
      body: Consumer<HubProvider>(
        builder: (context, hubProvider, _) {
          final summary = hubProvider.hubCashSummary;
          final cashBalance = summary?['cashBalance'] ?? 0;
          final history = summary?['history'] as List<dynamic>? ?? [];

          return RefreshIndicator(
            onRefresh: () => hubProvider.fetchHubCashSummary(),
            child: Column(
              children: [
                // Cash Balance Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.cashBalance,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(
                          symbol: 'EGP ',
                          decimalDigits: 2,
                        ).format(cashBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // History List
                Expanded(
                  child: history.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noDataAvailable,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final record = history[index];
                            final type = record['type'] ?? '';
                            final amount = record['amount'] ?? 0;
                            final description = record['description'] ?? '';
                            final createdAt = record['createdAt'] ?? '';

                            Color typeColor = Colors.grey;
                            IconData typeIcon = Icons.swap_horiz;

                            if (type == 'deposit' ||
                                type == 'transaction_payment') {
                              typeColor = Colors.green;
                              typeIcon = Icons.arrow_downward;
                            } else if (type == 'withdrawal' ||
                                type == 'transaction_revenue') {
                              typeColor = Colors.red;
                              typeIcon = Icons.arrow_upward;
                            } else if (type == 'correction') {
                              typeColor = Colors.orange;
                              typeIcon = Icons.edit;
                            } else if (type == 'compensation') {
                              typeColor = Colors.teal;
                              typeIcon = Icons.card_giftcard;
                            } else if (type == 'expenses') {
                              typeColor = Colors.redAccent;
                              typeIcon = Icons.money_off;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: typeColor.withOpacity(0.2),
                                  child: Icon(typeIcon, color: typeColor),
                                ),
                                title: Text(
                                  description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat(
                                    'yyyy-MM-dd HH:mm',
                                  ).format(DateTime.parse(createdAt)),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Text(
                                  NumberFormat.currency(
                                    symbol: 'EGP ',
                                    decimalDigits: 2,
                                  ).format(amount),
                                  style: TextStyle(
                                    color: typeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
