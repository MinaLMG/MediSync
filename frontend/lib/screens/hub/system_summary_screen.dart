import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hub_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class SystemSummaryScreen extends StatefulWidget {
  const SystemSummaryScreen({super.key});

  @override
  State<SystemSummaryScreen> createState() => _SystemSummaryScreenState();
}

class _SystemSummaryScreenState extends State<SystemSummaryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<HubProvider>(context, listen: false).fetchHubSystemSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.optimisticValue),
        backgroundColor: Colors.blue,
      ),
      body: Consumer<HubProvider>(
        builder: (context, hubProvider, _) {
          final summary = hubProvider.hubSystemSummary;
          final totalValue = summary?['totalOptimisticValue'] ?? 0;
          final items = summary?['items'] as List<dynamic>? ?? [];

          return RefreshIndicator(
            onRefresh: () => hubProvider.fetchHubSystemSummary(),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.optimisticValue,
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
                        ).format(totalValue),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Non-Hub Summary
                if (summary?['totalNonHubOptimisticValue'] != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Total Market Potential (Non-Hub)",
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          NumberFormat.currency(
                            symbol: 'EGP ',
                            decimalDigits: 2,
                          ).format(summary!['totalNonHubOptimisticValue']),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Items List
                Expanded(
                  child: items.isEmpty
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
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final productName =
                                item['product']?['name'] ?? 'Unknown';
                            final volumeName = item['volume']?['name'] ?? '';
                            final quantity = item['remainingQuantity'] ?? 0;
                            final optimisticValue =
                                item['optimisticValue'] ?? 0;
                            final agreedSale = item['agreedSale'] ?? 0;
                            final selectedPrice = item['selectedPrice'] ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$productName ${volumeName.isNotEmpty ? "($volumeName)" : ""}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            NumberFormat.currency(
                                              symbol: 'EGP ',
                                              decimalDigits: 2,
                                            ).format(optimisticValue),
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildInfoChip(
                                          l10n.quantity,
                                          quantity.toString(),
                                          Colors.grey,
                                        ),
                                        _buildInfoChip(
                                          l10n.price,
                                          NumberFormat.currency(
                                            symbol: 'EGP ',
                                            decimalDigits: 2,
                                          ).format(selectedPrice),
                                          Colors.green,
                                        ),
                                        _buildInfoChip(
                                          l10n.salePercentage,
                                          '${agreedSale.toStringAsFixed(1)}%',
                                          Colors.orange,
                                        ),
                                      ],
                                    ),
                                  ],
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

  Widget _buildInfoChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
