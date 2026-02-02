import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/excess_provider.dart';
import '../providers/shortage_provider.dart';
import '../l10n/generated/app_localizations.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final Map<String, Map<String, dynamic>> _cart =
      {}; // key: excessId, value: {item, quantity}
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMarketItems();
    });
  }

  Future<void> _fetchMarketItems() async {
    setState(() => _isLoading = true);
    await Provider.of<ExcessProvider>(
      context,
      listen: false,
    ).fetchMarketExcesses();
    setState(() => _isLoading = false);
  }

  void _addToCart(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    // Get all price options for this product/volume
    final productId = item['product']['_id'];
    final volumeId = item['volume']['_id'];

    final excesses = Provider.of<ExcessProvider>(
      context,
      listen: false,
    ).marketExcesses;
    final priceOptions = excesses
        .where(
          (e) =>
              e['product']['_id'] == productId &&
              e['volume']['_id'] == volumeId,
        )
        .toList();

    // Sort by price
    priceOptions.sort(
      (a, b) => (a['price'] as num).compareTo(b['price'] as num),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        // Map to track quantities for each price: Map<price, quantity>
        final Map<double, int> priceQuantities = {};

        // Initialize with existing cart values
        for (var option in priceOptions) {
          final price = (option['price'] as num).toDouble();
          final key = '${productId}_${volumeId}_$price';
          priceQuantities[price] = _cart[key]?['quantity'] ?? 0;
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final totalQuantity = priceQuantities.values.fold(
              0,
              (sum, qty) => sum + qty,
            );
            final totalCost = priceQuantities.entries.fold(
              0.0,
              (sum, entry) => sum + (entry.key * entry.value),
            );

            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['product']['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    item['volume']['name'],
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.labelSelectQuantitiesByPrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...priceOptions.map((option) {
                      final price = (option['price'] as num).toDouble();
                      final maxQty = option['totalQuantity'];
                      final currentQty = priceQuantities[price] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.priceCoins(price.toString()),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text(
                                    l10n.labelAvailableCount(maxQty),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: currentQty > 0
                                        ? () => setState(
                                            () => priceQuantities[price] =
                                                currentQty - 1,
                                          )
                                        : null,
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: TextField(
                                      controller:
                                          TextEditingController(
                                              text: '$currentQty',
                                            )
                                            ..selection =
                                                TextSelection.fromPosition(
                                                  TextPosition(
                                                    offset:
                                                        '$currentQty'.length,
                                                  ),
                                                ),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                      ),
                                      onChanged: (value) {
                                        final newQty = int.tryParse(value);
                                        if (newQty != null &&
                                            newQty >= 0 &&
                                            newQty <= maxQty) {
                                          setState(
                                            () =>
                                                priceQuantities[price] = newQty,
                                          );
                                        } else if (newQty != null &&
                                            newQty > maxQty) {
                                          setState(
                                            () =>
                                                priceQuantities[price] = maxQty,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: currentQty < maxQty
                                        ? () => setState(
                                            () => priceQuantities[price] =
                                                currentQty + 1,
                                          )
                                        : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                              if (currentQty > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    l10n.labelSubtotalAmount(
                                      (price * currentQty).toStringAsFixed(2),
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.labelTotalQuantity,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l10n.labelUnitsCount(totalQuantity),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.labelTotalCost,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l10n.priceCoins(totalCost.toStringAsFixed(2)),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
                  onPressed: () {
                    this.setState(() {
                      // Update cart for each price option
                      for (var option in priceOptions) {
                        final price = (option['price'] as num).toDouble();
                        final key = '${productId}_${volumeId}_$price';
                        final qty = priceQuantities[price] ?? 0;

                        if (qty == 0) {
                          _cart.remove(key);
                        } else {
                          _cart[key] = {'item': option, 'quantity': qty};
                        }
                      }
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          totalQuantity == 0
                              ? l10n.msgRemovedFromCart
                              : l10n.msgCartUpdated,
                        ),
                      ),
                    );
                  },
                  child: Text(l10n.actionUpdateCart),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeFromCart(String key) {
    setState(() {
      _cart.remove(key);
    });
  }

  double _calculateTotal() {
    return _cart.values.fold(0.0, (sum, cartItem) {
      final item = cartItem['item'];
      final quantity = cartItem['quantity'];
      return sum + (item['price'] * quantity);
    });
  }

  Future<void> _submitOrder() async {
    final l10n = AppLocalizations.of(context)!;
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.msgCartEmpty)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Convert cart to order items
      final items = _cart.values.map((cartItem) {
        final item = cartItem['item'];
        final quantity = cartItem['quantity'];

        return {
          'product': item['product']['_id'],
          'volume': item['volume']['_id'],
          'quantity': quantity,
          'targetPrice': item['price'],
          'notes': '',
        };
      }).toList();

      final orderData = {'items': items, 'notes': _notesController.text};

      final success = await Provider.of<ShortageProvider>(
        context,
        listen: false,
      ).createOrder(orderData);

      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.msgOrderPlaced)));
        Navigator.pop(context);
      } else if (mounted) {
        final error = Provider.of<ShortageProvider>(
          context,
          listen: false,
        ).errorMessage;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error ?? l10n.msgOrderFailed)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _viewCart() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.titleShoppingCart,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _cart.isEmpty
                    ? Center(child: Text(l10n.msgCartEmpty))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final key = _cart.keys.elementAt(index);
                          final cartItem = _cart[key]!;
                          final item = cartItem['item'];
                          final quantity = cartItem['quantity'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(item['product']['name']),
                              subtitle: Text(
                                '${item['volume']['name']} • ${l10n.priceCoins(item['price'].toString())} × $quantity',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.priceCoins(
                                      (item['price'] * quantity)
                                          .toStringAsFixed(2),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() => _removeFromCart(key));
                                      Navigator.pop(ctx);
                                      _viewCart();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.labelTotalCost.replaceAll(':', '')}:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.priceCoins(_calculateTotal().toStringAsFixed(2)),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.labelOrderNotesOptional,
                  border: const OutlineInputBorder(),
                  hintText: l10n.hintAddSpecialInstructions,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _submitOrder();
                        },
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.shopping_bag),
                  label: Text(
                    _isSubmitting
                        ? l10n.msgPlacingOrder
                        : l10n.actionPlaceOrder,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final excesses = Provider.of<ExcessProvider>(context).marketExcesses;
    final l10n = AppLocalizations.of(context)!;

    // Group excesses by product/volume
    final Map<String, Map<String, dynamic>> groupedItems = {};
    for (var excess in excesses) {
      final key = '${excess['product']['_id']}_${excess['volume']['_id']}';
      final price = (excess['price'] as num).toDouble();

      if (!groupedItems.containsKey(key)) {
        // Store first occurrence with aggregated data
        groupedItems[key] = {
          'product': excess['product'],
          'volume': excess['volume'],
          'totalQuantity': excess['totalQuantity'],
          'minPrice': price,
          'maxPrice': price,
          'priceCount': 1,
        };
      } else {
        // Update aggregated data
        groupedItems[key]!['totalQuantity'] += excess['totalQuantity'];
        if (price < groupedItems[key]!['minPrice']) {
          groupedItems[key]!['minPrice'] = price;
        }
        if (price > groupedItems[key]!['maxPrice']) {
          groupedItems[key]!['maxPrice'] = price;
        }
        groupedItems[key]!['priceCount']++;
      }
    }

    final groupedList = groupedItems.values.toList();

    final filteredItems = _searchQuery.isEmpty
        ? groupedList
        : groupedList.where((item) {
            final productName = item['product']['name']
                .toString()
                .toLowerCase();
            return productName.contains(_searchQuery.toLowerCase());
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleShoppingTour),
        actions: [
          if (_cart.isNotEmpty)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: _viewCart,
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${_cart.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMarketItems,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.hintSearchProducts,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Market Items Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? l10n.msgNoMarketItems
                              : l10n.msgNoSearchMatches,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final productId = item['product']['_id'];
                      final volumeId = item['volume']['_id'];

                      // Check if any price option is in cart
                      final inCart = _cart.keys.any(
                        (key) => key.startsWith('${productId}_${volumeId}_'),
                      );

                      final minPrice = item['minPrice'];
                      final maxPrice = item['maxPrice'];
                      final priceCount = item['priceCount'];

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _addToCart(item),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Icon
                                Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.medication,
                                    size: 40,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Product Name
                                Text(
                                  item['product']['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                // Volume
                                Text(
                                  item['volume']['name'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const Spacer(),

                                // Stock
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.labelAvailableUnits(
                                        item['totalQuantity'],
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Price and Add Button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            priceCount > 1
                                                ? '$minPrice - $maxPrice'
                                                : '$minPrice',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          if (priceCount > 1)
                                            Text(
                                              l10n.labelPriceOptions(
                                                priceCount,
                                              ),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: inCart
                                            ? Colors.green
                                            : Colors.blue[800],
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          inCart
                                              ? Icons.check
                                              : Icons.add_shopping_cart,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: () => _addToCart(item),
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _viewCart,
              backgroundColor: Colors.blue[800],
              icon: const Icon(Icons.shopping_cart),
              label: Text('Cart (${_cart.length})'),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
