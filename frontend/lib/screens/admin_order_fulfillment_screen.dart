import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/order_provider.dart';
import '../utils/ui_utils.dart';
import '../l10n/generated/app_localizations.dart';

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
            expiryDate: item['expiryDate'],
            salePercentage: (item['originalSalePercentage'] as num?)
                ?.toDouble(),
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

      // Sort matches by nearest expiry
      filteredMatches.sort((a, b) {
        final dateA = _parseExpiryDate(a['expiryDate']);
        final dateB = _parseExpiryDate(b['expiryDate']);
        return dateA.compareTo(dateB);
      });

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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.msgSelectExcessToFulfill)));
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
        final l10n = AppLocalizations.of(context)!;
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                failCount > 0
                    ? l10n.msgFulfillPartialFail(successCount, failCount)
                    : l10n.msgFulfillSuccess(successCount),
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
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.msgAllFulfillmentsFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.labelOrderHash}${widget.order['serial']}'),
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
                    l10n.labelSelectedUnits(_getTotalSelectedOverall()),
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
                  decoration: BoxDecoration(color: Colors.blue[50]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.labelItemsCount(_items.length),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${l10n.labelStatus}: ${_getLocalizedStatus(context, widget.order['status'])}',
                      ),
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
                                          '${l10n.labelVolumePrefix} ${item['volume']['name']} | ${l10n.labelPricePrefix} ${item['targetPrice']} ${l10n.coinsSuffix}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (item['expiryDate'] != null ||
                                            item['originalSalePercentage'] !=
                                                null ||
                                            item['salePercentage'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2.0,
                                            ),
                                            child: Text(
                                              '${item['expiryDate'] != null ? "${l10n.labelExpiryPrefix} ${item['expiryDate']}" : ""} ${(item['originalSalePercentage'] ?? item['salePercentage']) != null ? "| Sale: ${item['originalSalePercentage'] ?? item['salePercentage']}%" : ""}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue[800],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        l10n.labelNeed(
                                          item['remainingQuantity'],
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      if (_getTotalSelectedForItem(itemId) > 0)
                                        Text(
                                          l10n.labelSelectedUnitsShort(
                                            _getTotalSelectedForItem(itemId),
                                          ),
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
                                    l10n.msgNoMatchingExcesses,
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
                                              InkWell(
                                                onTap: () =>
                                                    UIUtils.showPharmacyInfo(
                                                      context,
                                                      excess['pharmacy'],
                                                    ),
                                                child: Text(
                                                  excess['pharmacy']['name'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${l10n.labelAvailableUnitsPrefix} $maxQty ${l10n.labelUnitsSuffix}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Builder(
                                                builder: (context) {
                                                  final settings =
                                                      Provider.of<
                                                        SettingsProvider
                                                      >(context);
                                                  final effectiveSale =
                                                      excess['salePercentage'] ??
                                                      (excess['shortage_fulfillment'] ==
                                                              true
                                                          ? settings
                                                                .shortageCommission
                                                          : settings
                                                                .minimumCommission);
                                                  return Text(
                                                    '${l10n.labelSaleRatioPrefix} ${effectiveSale}%',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green[700],
                                                    ),
                                                  );
                                                },
                                              ),
                                              if (excess['expiryDate'] != null)
                                                Text(
                                                  '${l10n.labelExpiryPrefix} ${excess['expiryDate']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        _isNearExpiry(
                                                          excess['expiryDate'],
                                                        )
                                                        ? Colors.red
                                                        : Colors.grey[600],
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
                                                child: Text(
                                                  l10n.actionMax,
                                                  style: const TextStyle(
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
                            ? l10n.msgProcessing
                            : l10n.actionSubmitFulfillment(
                                _getTotalSelectedOverall(),
                              ),
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

  DateTime _parseExpiryDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime(2099, 12, 31);
    try {
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = parts.length > 2 ? int.parse(parts[2]) : 1;
        return DateTime(year, month, day);
      } else if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 2) {
          final month = int.parse(parts[0]);
          final yearStr = parts[1];
          int year;
          if (yearStr.length == 2) {
            year = 2000 + int.parse(yearStr);
          } else {
            year = int.parse(yearStr);
          }
          return DateTime(year, month, 1);
        } else {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      debugPrint('Error parsing date: $dateStr');
    }
    return DateTime(2099, 12, 31);
  }

  bool _isNearExpiry(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    final expiry = _parseExpiryDate(dateStr);
    final now = DateTime.now();
    final difference = expiry.difference(now).inDays;
    return difference < (6 * 30);
  }

  String _getLocalizedStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.statusPending;
      case 'available':
        return l10n.statusAvailable;
      case 'active':
        return l10n.statusActive;
      case 'fulfilled':
        return l10n.statusFulfilled;
      case 'partially_fulfilled':
        return l10n.statusPartiallyFulfilled;
      case 'sold':
        return l10n.statusSold;
      case 'expired':
        return l10n.statusExpired;
      case 'cancelled':
        return l10n.statusCancelled;
      case 'rejected':
        return l10n.statusRejected;
      default:
        return status.toUpperCase();
    }
  }
}
