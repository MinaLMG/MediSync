import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/generated/app_localizations.dart';

class HubInvoiceItemViewWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSales;

  const HubInvoiceItemViewWidget({
    super.key,
    required this.item,
    this.isSales = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(
      symbol: 'EGP ',
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Item Details",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    l10n.labelName,
                    item['product_name'] ?? 'Unknown',
                    Icons.inventory_2_outlined,
                  ),
                  _buildDetailRow(
                    context,
                    l10n.labelVolume,
                    item['volume_name'] ?? 'N/A',
                    Icons.straighten_outlined,
                  ),
                  _buildDetailRow(
                    context,
                    l10n.labelQuantity,
                    item['quantity'].toString(),
                    Icons.numbers_outlined,
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Only relevant for purchase/internal view usually
                  _buildDetailRow(
                    context,
                    "Buying Price",
                    currencyFormat.format(item['buyingPrice'] ?? 0),
                    Icons.shopping_cart_outlined,
                    valueColor: Colors.green[700],
                  ),
                  _buildDetailRow(
                    context,
                    isSales ? l10n.labelSellingPrice : "Target Selling Price",
                    currencyFormat.format(item['sellingPrice'] ?? 0),
                    Icons.sell_outlined,
                    valueColor: Colors.blue[700],
                  ),
                  if (item['salePercentage'] != null)
                    _buildDetailRow(
                      context,
                      l10n.labelPercentageValue,
                      "${(item['salePercentage'] ?? 0).toStringAsFixed(1)}%",
                      Icons.percent_outlined,
                      valueColor: Colors.orange[700],
                    ),
                  if (item['expiryDate'] != null)
                    _buildDetailRow(
                      context,
                      l10n.labelExpiry,
                      item['expiryDate'],
                      Icons.calendar_today_outlined,
                    ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Line Value",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormat.format(item['total'] ?? 0),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
