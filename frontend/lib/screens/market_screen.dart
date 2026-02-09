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

  void _showProductDetails(dynamic productData) {
    // final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            MarketProductDetailScreen(productData: productData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final excesses = Provider.of<ExcessProvider>(context).marketExcesses;

    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: excesses.length,
              itemBuilder: (ctx, i) {
                final item = excesses[i];
                // Item structure: { product: {name}, volume: {name}, minPrice, maxSale, prices: [...] }
                final hasSale = (item['maxSale'] ?? 0) > 0;

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      '${item['product']['name']} (${item['volume']['name']})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.labelStartsFrom} ${item['minPrice']} ${l10n.labelCoins}',
                        ),
                        if (hasSale)
                          Text(
                            '${l10n.labelSaleUpTo} ${item['maxSale'].toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showProductDetails(item),
                  ),
                );
              },
            ),
    );
  }
}

class MarketProductDetailScreen extends StatelessWidget {
  final dynamic productData;

  const MarketProductDetailScreen({super.key, required this.productData});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prices = productData['prices'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${productData['product']['name']} (${productData['volume']['name']})',
        ),
      ),
      body: ListView.builder(
        itemCount: prices.length,
        itemBuilder: (ctx, i) {
          final priceGroup = prices[i];
          final hasSale = (priceGroup['maxSale'] ?? 0) > 0;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExpansionTile(
              title: Text(
                '${priceGroup['price']} ${l10n.labelCoins}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: hasSale
                  ? Text(
                      '${l10n.labelSaleUpTo} ${priceGroup['maxSale'].toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.red),
                    )
                  : null,
              children: [
                ...(priceGroup['items'] as List<dynamic>).map((item) {
                  return ListTile(
                    title: Text('${l10n.labelExpiry}: ${item['expiryDate']}'),
                    subtitle: item['userSale'] > 0
                        ? Text(
                            '${l10n.labelSale}: ${item['userSale'].toStringAsFixed(1)}%',
                            style: const TextStyle(color: Colors.red),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${l10n.labelQty}: ${item['quantity']}'),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // _buyItem logic (Quantity Selection Dialog)
                            // Since this is a stateless widget, we might need a Stateful wrapper or
                            // call a function passed from parent.
                            // Or just show dialog here.
                            _showBuyDialog(
                              context,
                              productData,
                              priceGroup,
                              item,
                            );
                          },
                          child: Text(l10n.actionBuy),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBuyDialog(
    BuildContext context,
    dynamic product,
    dynamic priceGroup,
    dynamic item,
  ) {
    // Implement Buy Dialog (Same as before but with specific item details)
    int quantity = 1;
    final maxQty = item['quantity'];
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            l10n.titleBuyProduct(
              product['product']['name'],
              product['volume']['name'],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.labelPrice}: ${priceGroup['price']}'),
              Text('${l10n.labelExpiry}: ${item['expiryDate']}'),
              if (item['userSale'] > 0)
                Text(
                  '${l10n.labelSale}: ${item['userSale'].toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.red),
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
                  Text('$quantity', style: const TextStyle(fontSize: 20)),
                  IconButton(
                    onPressed: quantity < maxQty
                        ? () => setState(() => quantity++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),

              // Show Total Price (Adjusted for Sale?)
              // Wait, "Buyer Pays: Price - Discount".
              // backend `userSale` IS the discount % the user sees.
              // So displayed price should be `Price * (1 - userSale/100)`.
              Text(
                l10n.labelTotalCoins(
                  (quantity *
                          priceGroup['price'] *
                          (1 - (item['userSale'] / 100)))
                      .toStringAsFixed(2),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.actionCancel),
            ),
            ElevatedButton(
              onPressed: () {
                // Add to Cart / Buy
                // Need to verify backend `buy` endpoint supports this specific item?
                // Actually `buyFromMarket` likely takes `excessId`?
                // But we AGREGRATED. We don't have `excessId` in the `items` array directly?
                // Wait, I forgot to include `excessIds` in the aggregation!
                // The aggregation grouped by Expiry/Sale.
                // But multiple excesses could match that group.
                // Ideally we pick ONE excessId or valid IDs?
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Purchase logic pending excess ID"),
                  ),
                );
              },
              child: const Text('Add to Order'),
            ),
          ],
        ),
      ),
    );
  }
}
