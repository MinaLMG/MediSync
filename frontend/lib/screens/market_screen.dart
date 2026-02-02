import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/excess_provider.dart';
import '../l10n/generated/app_localizations.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMarketItems();
  }

  Future<void> _fetchMarketItems() async {
    setState(() => _isLoading = true);
    await Provider.of<ExcessProvider>(
      context,
      listen: false,
    ).fetchMarketExcesses();
    setState(() => _isLoading = false);
  }

  void _buyItem(dynamic item) {
    // Show dialog to select quantity
    int quantity = 1;
    final maxQty = item['totalQuantity'];

    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.titleBuyProduct(
            item['product']['name'] ?? '',
            item['volume']['name'] ?? '',
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.labelPrice}: ${item['price']} ${l10n.labelCoins}'),
              Text(
                '${l10n.labelAvailableOriginal} ${item['totalQuantity']} ${l10n.labelUnitsShort}',
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: quantity > 1
                        ? () => setState(() => quantity--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: quantity < maxQty
                        ? () => setState(() => quantity++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              Text(
                l10n.labelTotalCoins(
                  (quantity * item['price']).toStringAsFixed(2),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Call createOrder immediately for direct buy?
              // Or add to cart? User said "i choose the quantities i need for each"
              // The backend `buyFromMarket` buys *one item* (excessId).
              // But our `getMarketExcesses` is Aggregated.
              // So we don't have a specific `excessId` here. We have a group.
              // We need to fetch specific excesses for this group (drill down) OR
              // Update `buyFromMarket` to accept Product/Volume/Price and auto-match.

              // Let's implement auto-match on backend or drill down.
              // Given "don't show many items for the sam product and price", aggregation is correct.
              // So when buying, the BACKEND should pick the excesses that match.
              // `buyFromMarket` exposed `excessId`. We should change it to accept product/volume/price details if we use aggregation.
              // OR, we list the individual items inside the "Buy" dialog?
              // "i choose the quantities i need for each" implies simple selection.

              // Let's assume for now we need a new backend endpoint `buyFromMarketAggregated`?
              // Or update `buyFromMarket`.

              // Actually, the user request "for an order created by a pharamce to be a collection of shortages"
              // This market screen is for "Buying".
              // The "Order" flow allows specifying what they WANT (Shortage).

              // Let's stick to the user's "Order" flow first:
              // "i choose the quantities i need for each" -> This might mean adding to a "Order List" (Cart)
              // Then submitting the whole list as an Order.

              // So, "Add to Order" button.
            },
            child: const Text('Add to Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final excesses = Provider.of<ExcessProvider>(context).marketExcesses;

    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: excesses.length,
              itemBuilder: (ctx, i) {
                final item = excesses[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      '${item['product']['name']} (${item['volume']['name']})',
                    ),
                    subtitle: Text(
                      'Price: \$${item['price']}  |  Stock: ${item['totalQuantity']}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _buyItem(item),
                      child: const Text('Select'),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Go to Cart / Review Order
        },
        label: const Text('Review Order'),
        icon: const Icon(Icons.shopping_cart),
      ),
    );
  }
}
