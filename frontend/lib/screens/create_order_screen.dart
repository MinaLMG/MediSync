import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/excess_provider.dart';
import '../providers/shortage_provider.dart';

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

  void _addToCart(Map<String, dynamic> item) {
    final key =
        '${item['product']['_id']}_${item['volume']['_id']}_${item['price']}';

    showDialog(
      context: context,
      builder: (ctx) {
        int quantity = _cart[key]?['quantity'] ?? 1;
        final maxQty = item['totalQuantity'];

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add to Cart'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product']['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text('Volume: ${item['volume']['name']}'),
                Text('Price: ${item['price']} coins'),
                Text('Available: $maxQty units'),
                const SizedBox(height: 16),
                const Text(
                  'Quantity:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: quantity > 0
                          ? () => setState(() => quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: TextEditingController(text: '$quantity')
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: '$quantity'.length),
                          ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          final newQty = int.tryParse(value);
                          if (newQty != null &&
                              newQty >= 0 &&
                              newQty <= maxQty) {
                            setState(() => quantity = newQty);
                          } else if (newQty != null && newQty > maxQty) {
                            setState(() => quantity = maxQty);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: quantity < maxQty
                          ? () => setState(() => quantity++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                Text(
                  'Max: $maxQty units',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${(quantity * item['price']).toStringAsFixed(2)} coins',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  this.setState(() {
                    if (quantity == 0) {
                      _cart.remove(key);
                    } else {
                      _cart[key] = {'item': item, 'quantity': quantity};
                    }
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        quantity == 0 ? 'Removed from cart' : 'Added to cart!',
                      ),
                    ),
                  );
                },
                child: Text(quantity == 0 ? 'Update Cart' : 'Add to Cart'),
              ),
            ],
          ),
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
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        final error = Provider.of<ShortageProvider>(
          context,
          listen: false,
        ).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to place order')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _viewCart() {
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
                  const Text(
                    'Shopping Cart',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    ? const Center(child: Text('Your cart is empty'))
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
                                '${item['volume']['name']} • ${item['price']} coins × $quantity',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(item['price'] * quantity).toStringAsFixed(2)} coins',
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
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_calculateTotal().toStringAsFixed(2)} coins',
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
                decoration: const InputDecoration(
                  labelText: 'Order Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Add special instructions...',
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
                    _isSubmitting ? 'Placing Order...' : 'Place Order',
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

    final filteredExcesses = _searchQuery.isEmpty
        ? excesses
        : excesses.where((item) {
            final productName = item['product']['name']
                .toString()
                .toLowerCase();
            return productName.contains(_searchQuery.toLowerCase());
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Tour'),
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
                hintText: 'Search products...',
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
                : filteredExcesses.isEmpty
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
                              ? 'No items available in the market'
                              : 'No items match your search',
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
                    itemCount: filteredExcesses.length,
                    itemBuilder: (context, index) {
                      final item = filteredExcesses[index];
                      final key =
                          '${item['product']['_id']}_${item['volume']['_id']}_${item['price']}';
                      final inCart = _cart.containsKey(key);

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
                                      '${item['totalQuantity']} available',
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
                                    Text(
                                      '${item['price']} coins',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue,
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
