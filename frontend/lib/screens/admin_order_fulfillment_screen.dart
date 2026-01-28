import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/order_provider.dart';

class AdminOrderFulfillmentScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const AdminOrderFulfillmentScreen({super.key, required this.order});

  @override
  State<AdminOrderFulfillmentScreen> createState() =>
      _AdminOrderFulfillmentScreenState();
}

class _AdminOrderFulfillmentScreenState
    extends State<AdminOrderFulfillmentScreen> {
  List<dynamic> _items = [];
  bool _isLoading = false;

  // Cache for matches per item: Map<itemId, List<excess>>
  final Map<String, List<dynamic>> _matchCache = {};

  // Selected quantities: Map<itemId, Map<excessId, quantity>>
  final Map<String, Map<String, int>> _selections = {};

  @override
  void initState() {
    super.initState();
    _items = widget.order['items'] ?? [];

    // Initialize selections for each item
    for (var item in _items) {
      _selections[item['_id']] = {};
    }

    // Fetch matches for all items
    Future.microtask(() => _fetchAllMatches());
  }

  Future<void> _fetchAllMatches() async {
    setState(() => _isLoading = true);

    for (var item in _items) {
      await _fetchMatchesForItem(item);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchMatchesForItem(Map<String, dynamic> item) async {
    final itemId = item['_id'];
    final productId = item['product']['_id'];
    final targetPrice = item['targetPrice'] != null
        ? (item['targetPrice'] as num).toDouble()
        : null;

    try {
      final matches =
          await Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).fetchMatchesForProduct(
            productId,
            price: targetPrice,
            excludeShortageFulfillment: true,
          );

      final requiredVolumeId = item['volume']['_id'];
      final filteredMatches = (matches['excesses'] as List).where((excess) {
        try {
          final excessVolumeId = excess['volume']['_id'];
          return excessVolumeId == requiredVolumeId;
        } catch (e) {
          return false;
        }
      }).toList();

      _matchCache[itemId] = filteredMatches;
    } catch (e) {
      _matchCache[itemId] = [];
    }
  }

  int _getTotalSelectedForItem(String itemId) {
    return _selections[itemId]?.values.fold<int>(0, (sum, qty) => sum + qty) ??
        0;
  }

  int _getTotalSelectedOverall() {
    int total = 0;
    for (var itemSelections in _selections.values) {
      total += itemSelections.values.fold(0, (sum, qty) => sum + qty);
    }
    return total;
  }

  Future<void> _submitAllFulfillments() async {
    // Validate that at least one item has selections
    bool hasSelections = false;
    for (var itemSelections in _selections.values) {
      if (itemSelections.isNotEmpty) {
        hasSelections = true;
        break;
      }
    }

    if (!hasSelections) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one excess to fulfill'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int successCount = 0;
      int failCount = 0;

      // Create transactions for each item that has selections
      for (var item in _items) {
        final itemId = item['_id'];
        final itemSelections = _selections[itemId];

        if (itemSelections == null || itemSelections.isEmpty) {
          continue; // Skip items with no selections
        }

        final totalSelected = _getTotalSelectedForItem(itemId);

        // Validate quantity
        if (totalSelected > item['remainingQuantity']) {
          failCount++;
          continue;
        }

        // Build excess sources
        final excessSources = itemSelections.entries.map((entry) {
          return {'stockExcessId': entry.key, 'quantity': entry.value};
        }).toList();

        final requestData = {
          'shortageId': itemId,
          'quantityTaken': totalSelected,
          'excessSources': excessSources,
        };

        debugPrint('=== Fulfilling Item: ${item['product']['name']} ===');
        debugPrint('Shortage ID: $itemId');
        debugPrint('Quantity: $totalSelected');

        final success = await Provider.of<OrderProvider>(
          context,
          listen: false,
        ).fulfillItem(requestData);

        if (success) {
          successCount++;
          // Update local state
          item['remainingQuantity'] -= totalSelected;
          if (item['remainingQuantity'] <= 0) {
            item['status'] = 'fulfilled';
          } else {
            item['status'] = 'partially_fulfilled';
          }
        } else {
          failCount++;
        }
      }

      if (mounted) {
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully fulfilled $successCount item(s)${failCount > 0 ? ', $failCount failed' : ''}',
              ),
              backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
            ),
          );

          // Clear selections and refresh
          setState(() {
            for (var itemId in _selections.keys) {
              _selections[itemId]?.clear();
            }
          });

          // Refresh matches
          await _fetchAllMatches();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All fulfillments failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Exception during fulfillment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order['serial']}'),
        actions: [
          if (_getTotalSelectedOverall() > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Selected: ${_getTotalSelectedOverall()} units',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading && _matchCache.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Order Summary Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_items.length} Items',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Status: ${widget.order['status']}'),
                    ],
                  ),
                ),

                // Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final itemId = item['_id'];
                      final matches = _matchCache[itemId] ?? [];
                      final itemSelections = _selections[itemId] ?? {};

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Item Header
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
                                          '${index + 1}. ${item['product']['name']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Volume: ${item['volume']['name']} | Price: ${item['targetPrice']} EGP',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Need: ${item['remainingQuantity']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      if (_getTotalSelectedForItem(itemId) > 0)
                                        Text(
                                          'Selected: ${_getTotalSelectedForItem(itemId)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),

                              const Divider(height: 24),

                              // Available Excesses
                              if (matches.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'No matching excesses available',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              else
                                ...matches.map<Widget>((excess) {
                                  final excessId = excess['_id'];
                                  final selectedQty =
                                      itemSelections[excessId] ?? 0;
                                  final maxQty =
                                      excess['remainingQuantity'] as int;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: selectedQty > 0
                                          ? Colors.green[50]
                                          : Colors.grey[50],
                                      border: Border.all(
                                        color: selectedQty > 0
                                            ? Colors.green
                                            : Colors.grey[300]!,
                                        width: selectedQty > 0 ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                excess['pharmacy']['name'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Available: $maxQty units',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: selectedQty > 0
                                                  ? () {
                                                      setState(() {
                                                        itemSelections[excessId] =
                                                            selectedQty - 1;
                                                        if (itemSelections[excessId] ==
                                                            0) {
                                                          itemSelections.remove(
                                                            excessId,
                                                          );
                                                        }
                                                      });
                                                    }
                                                  : null,
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              iconSize: 20,
                                            ),
                                            Container(
                                              width: 60,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: selectedQty > 0
                                                      ? Colors.green
                                                      : Colors.grey,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '$selectedQty',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: selectedQty > 0
                                                      ? Colors.green
                                                      : Colors.black,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed:
                                                  selectedQty < maxQty &&
                                                      _getTotalSelectedForItem(
                                                            itemId,
                                                          ) <
                                                          item['remainingQuantity']
                                                  ? () {
                                                      setState(() {
                                                        itemSelections[excessId] =
                                                            selectedQty + 1;
                                                      });
                                                    }
                                                  : null,
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                              iconSize: 20,
                                            ),
                                            SizedBox(
                                              width: 50,
                                              child: TextButton(
                                                onPressed:
                                                    selectedQty < maxQty &&
                                                        _getTotalSelectedForItem(
                                                              itemId,
                                                            ) <
                                                            item['remainingQuantity']
                                                    ? () {
                                                        setState(() {
                                                          final otherSelections =
                                                              itemSelections
                                                                  .entries
                                                                  .where(
                                                                    (e) =>
                                                                        e.key !=
                                                                        excessId,
                                                                  )
                                                                  .fold(
                                                                    0,
                                                                    (sum, e) =>
                                                                        sum +
                                                                        e.value,
                                                                  );
                                                          final remaining =
                                                              item['remainingQuantity'] -
                                                              otherSelections;
                                                          final canTake =
                                                              maxQty < remaining
                                                              ? maxQty
                                                              : remaining;
                                                          itemSelections[excessId] =
                                                              canTake;
                                                        });
                                                      }
                                                    : null,
                                                child: const Text(
                                                  'Max',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Submit Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || _getTotalSelectedOverall() == 0
                          ? null
                          : _submitAllFulfillments,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        _isLoading
                            ? 'Processing...'
                            : 'Submit Order Fulfillment (${_getTotalSelectedOverall()} units)',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
