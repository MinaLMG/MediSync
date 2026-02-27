import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/excess_provider.dart';
import '../providers/shortage_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/search_utils.dart';

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
    final productId = item['product']['_id'];
    final volumeId = item['volume']['_id'];

    final List<dynamic> priceOptions = (item['prices'] as List<dynamic>?) ?? [];

    // Flatten all combinations: each (price, expiry, sale) becomes a separate option
    final List<Map<String, dynamic>> allCombinations = [];

    for (var priceGroup in priceOptions) {
      final price = (priceGroup['price'] as num).toDouble();
      final items = (priceGroup['items'] as List<dynamic>?) ?? [];

      for (var itemDetail in items) {
        allCombinations.add({
          'price': price,
          'expiryDate': itemDetail['expiryDate'] as String? ?? '',
          'salePercentage': (itemDetail['salePercentage'] as num? ?? 0)
              .toDouble(),
          'originalSalePercentage':
              (itemDetail['originalSalePercentage'] as num? ??
                      itemDetail['salePercentage'] as num? ??
                      0)
                  .toDouble(),
          'userSale': (itemDetail['userSale'] as num? ?? 0).toDouble(),
          'quantity': (itemDetail['quantity'] as num? ?? 0).toInt(),
        });
      }
    }

    // Sort combinations: 1) price (low→high), 2) expiry (nearest→farthest), 3) sale (low→high)
    allCombinations.sort((a, b) {
      // First by price
      final priceCompare = a['price'].compareTo(b['price']);
      if (priceCompare != 0) return priceCompare;

      // Then by expiry date (parse MM/YY format)
      final expiryA = a['expiryDate'] as String;
      final expiryB = b['expiryDate'] as String;

      if (expiryA.isNotEmpty && expiryB.isNotEmpty) {
        try {
          final partsA = expiryA.split('/');
          final partsB = expiryB.split('/');
          if (partsA.length == 2 && partsB.length == 2) {
            final dateA = int.parse(
              '20${partsA[1]}${partsA[0].padLeft(2, '0')}',
            );
            final dateB = int.parse(
              '20${partsB[1]}${partsB[0].padLeft(2, '0')}',
            );
            final dateCompare = dateA.compareTo(dateB);
            if (dateCompare != 0) return dateCompare;
          }
        } catch (e) {}
      } else if (expiryA.isEmpty && expiryB.isNotEmpty) {
        return 1; // Empty expiry goes last
      } else if (expiryA.isNotEmpty && expiryB.isEmpty) {
        return -1;
      }

      // Finally by sale percentage
      return a['salePercentage'].compareTo(b['salePercentage']);
    });

    showDialog(
      context: context,
      builder: (ctx) {
        // Cart key format: "productId_volumeId_price_expiry_sale"
        final Map<String, int> combinationQuantities = {};

        // Initialize with existing cart values
        for (var combo in allCombinations) {
          final key =
              '${productId}_${volumeId}_${combo['price']}_${combo['expiryDate']}_${combo['salePercentage']}';
          combinationQuantities[key] = _cart[key]?['quantity'] ?? 0;
        }

        return StatefulBuilder(
          builder: (context, setState) {
            int totalQuantity = 0;
            double totalCost = 0;

            for (var i = 0; i < allCombinations.length; i++) {
              final combo = allCombinations[i];
              final key =
                  '${productId}_${volumeId}_${combo['price']}_${combo['expiryDate']}_${combo['salePercentage']}';
              final qty = combinationQuantities[key] ?? 0;
              totalQuantity += qty;
              totalCost +=
                  (combo['price'] as double) *
                  (1 - (combo['userSale'] as double) / 100) *
                  qty;
            }

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
                    ...allCombinations.map((combo) {
                      final price = combo['price'] as double;
                      final expiry = combo['expiryDate'] as String;
                      final userSale = combo['userSale'] as double;
                      final maxQty = combo['quantity'] as int;

                      final key =
                          '${productId}_${volumeId}_${price}_${expiry}_${combo['salePercentage']}';
                      final currentQty = combinationQuantities[key] ?? 0;

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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.priceCoins(price.toString()),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        if (expiry.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              '${l10n.labelExpiry}: $expiry',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        if (userSale > 0)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              '${l10n.labelSale} ${userSale.toStringAsFixed(0)}%',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
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
                                            () => combinationQuantities[key] =
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
                                            () => combinationQuantities[key] =
                                                newQty,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: currentQty < maxQty
                                        ? () => setState(
                                            () => combinationQuantities[key] =
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
                                      (price *
                                              (1 - userSale / 100) *
                                              currentQty)
                                          .toStringAsFixed(2),
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
                      // Update cart for each combination
                      for (var combo in allCombinations) {
                        final key =
                            '${productId}_${volumeId}_${combo['price']}_${combo['expiryDate']}_${combo['salePercentage']}';
                        final qty = combinationQuantities[key] ?? 0;

                        if (qty > 0) {
                          _cart[key] = {
                            'item': {
                              ...item,
                              'selectedPrice': combo['price'],
                              'selectedExpiry': combo['expiryDate'],
                              'selectedSale': combo['salePercentage'],
                              'selectedOriginalSale':
                                  combo['originalSalePercentage'],
                              'selectedUserSale': combo['userSale'],
                            },
                            'quantity': qty,
                          };
                        } else {
                          _cart.remove(key);
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
      final quantity = (cartItem['quantity'] as num? ?? 0).toDouble();
      final price = (item['selectedPrice'] as num? ?? 0.0).toDouble();
      final sale = (item['selectedSale'] as num? ?? 0.0).toDouble();
      final unitPrice = price * (1 - (sale / 100));
      return sum + (unitPrice * quantity);
    });
  }

  Future<void> _submitOrder() async {
    final l10n = AppLocalizations.of(context)!;
    // _isSubmitting is already set to true in onPressed
    try {
      if (_cart.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.msgCartEmpty),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.actionDone),
                ),
              ],
            ),
          );
        }
        return;
      }
      // Convert cart to order items
      final items = _cart.values.map((cartItem) {
        final item = cartItem['item'];
        final quantity = cartItem['quantity'];

        return {
          'product': item['product']['_id'],
          'volume': item['volume']['_id'],
          'quantity': quantity,
          'targetPrice': item['selectedPrice'],
          'expiryDate': item['selectedExpiry'],
          'salePercentage': item['selectedSale'],
          'originalSalePercentage': item['selectedOriginalSale'],
          'notes': '',
        };
      }).toList();

      final orderData = {'items': items, 'notes': _notesController.text};

      final success = await Provider.of<ShortageProvider>(
        context,
        listen: false,
      ).createOrder(orderData);

      if (success && mounted) {
        // Clear cart and notes after successful order
        setState(() {
          _cart.clear();
          _notesController.clear();
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.msgOrderPlaced)));

        // Remove cart modal
        Navigator.pop(context);

        // DO NOT POP MAIN SCREEN - RELOAD DATA INSTEAD
        await _fetchMarketItems();
      } else if (mounted) {
        final error = Provider.of<ShortageProvider>(
          context,
          listen: false,
        ).errorMessage;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.msgOrderFailed),
            content: Text(error ?? l10n.msgGenericError),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.actionDone),
              ),
            ],
          ),
        );
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
                                '${item['volume']['name']} • ${l10n.priceCoins(((item['selectedPrice'] ?? 0) * (1 - (item['selectedSale'] ?? 0) / 100)).toStringAsFixed(2))} × $quantity',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.priceCoins(
                                      ((item['selectedPrice'] ?? 0) *
                                              (1 -
                                                  (item['selectedSale'] ?? 0) /
                                                      100) *
                                              quantity)
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
                      '${l10n.labelTotalCost} ',
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
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              // Update UI immediately in modal
                              setModalState(() {});
                              // Update parent state for logic
                              setState(() => _isSubmitting = true);

                              // Perform order submission
                              await _submitOrder();

                              // Refresh modal state if still mounted (e.g. on error)
                              if (context.mounted) {
                                setModalState(() {});
                              }
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
                      // Explicitly use different styles for different states
                      style: _isSubmitting
                          ? ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey,
                              disabledForegroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            )
                          : ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                              disabledBackgroundColor: Colors.grey[400],
                              disabledForegroundColor: Colors.white,
                            ),
                    );
                  },
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

    // Data is already grouped by product/volume from the API
    final filteredItems = _searchQuery.isEmpty
        ? excesses
        : excesses.where((item) {
            final productName = item['product']['name'].toString();
            return SearchUtils.matches(productName, _searchQuery);
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
                          mainAxisExtent: 260, // Fixed height for all cards
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

                      // Calculate aggregates from 'prices' array
                      final prices = (item['prices'] as List<dynamic>?) ?? [];

                      double minPrice = 0;
                      double maxPrice = 0;
                      num totalQuantity = 0;
                      double maxSale = 0; // Maximum user sale percentage

                      if (prices.isNotEmpty) {
                        minPrice = double.infinity;
                        for (var p in prices) {
                          final priceVal = (p['price'] as num).toDouble();
                          if (priceVal < minPrice) minPrice = priceVal;
                          if (priceVal > maxPrice) maxPrice = priceVal;

                          // Sum quantity from items in this price group
                          final items = (p['items'] as List<dynamic>?) ?? [];
                          for (var i in items) {
                            totalQuantity += (i['quantity'] as num? ?? 0);

                            // Track maximum user sale
                            final userSale = (i['userSale'] as num? ?? 0)
                                .toDouble();
                            if (userSale > maxSale) maxSale = userSale;
                          }
                        }
                      } else {
                        // Fallback if no prices (shouldn't happen)
                        minPrice = (item['minPrice'] as num? ?? 0).toDouble();
                        maxPrice = minPrice;
                      }

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
                                // Sale Badge (if applicable)
                                if (maxSale > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${l10n.labelSaleUpTo} ${maxSale.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (maxSale > 0) const SizedBox(height: 4),

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
                                Flexible(
                                  child: Text(
                                    item['product']['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                                        totalQuantity.toInt(),
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
                                            prices.length > 1
                                                ? l10n.labelPriceRange(
                                                    minPrice.toStringAsFixed(0),
                                                    maxPrice.toStringAsFixed(0),
                                                    l10n.labelCoins,
                                                  )
                                                : '${minPrice.toStringAsFixed(0)} ${l10n.labelCoins}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          if (prices.length > 1)
                                            Text(
                                              l10n.labelPriceOptions(
                                                prices.length,
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
              label: Text(l10n.labelCartWithCount(_cart.length)),
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
