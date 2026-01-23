import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class MatchingDetailScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const MatchingDetailScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<MatchingDetailScreen> createState() => _MatchingDetailScreenState();
}

class _MatchingDetailScreenState extends State<MatchingDetailScreen> {
  String shortageSort = 'Time';
  bool shortageDescending = true;
  String excessSort = 'Time';
  bool excessDescending = true;

  Map<String, dynamic>? selectedShortage;
  int shortageQuantityToFulfill = 0;

  // Map of excessId -> chosenQuantity
  Map<String, int> selectedExcesses = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).fetchMatchesForProduct(widget.productId),
    );
  }

  List<dynamic> getSortedList(
    List<dynamic> list,
    String criteria,
    bool isExcess,
    bool descending,
  ) {
    final sortedList = List.from(list);

    sortedList.sort((a, b) {
      int comparison;
      if (criteria == 'Time') {
        comparison = DateTime.parse(
          b['createdAt'],
        ).compareTo(DateTime.parse(a['createdAt']));
      } else if (criteria == 'Value') {
        if (isExcess) {
          comparison = (b['saleAmount'] ?? 0).compareTo(a['saleAmount'] ?? 0);
        } else {
          comparison = (b['maxSurplus'] ?? 0).compareTo(a['maxSurplus'] ?? 0);
        }
      } else if (criteria == 'Quantity') {
        if (isExcess) {
          comparison = b['remainingQuantity'].compareTo(a['remainingQuantity']);
        } else {
          comparison = (b['quantity'] - b['fulfilledQuantity']).compareTo(
            a['quantity'] - a['fulfilledQuantity'],
          );
        }
      } else {
        comparison = 0;
      }
      return descending ? comparison : -comparison;
    });

    return sortedList;
  }

  void _submitTransaction() async {
    if (selectedShortage == null || selectedExcesses.isEmpty) return;

    final totalAllocated = selectedExcesses.values.fold(0, (sum, q) => sum + q);
    if (totalAllocated == 0) return;

    final List<Map<String, dynamic>> sources = [];
    selectedExcesses.forEach((id, q) {
      if (q > 0) {
        sources.add({'stockExcessId': id, 'quantity': q});
      }
    });

    final success =
        await Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).createTransaction({
          'shortageId': selectedShortage!['_id'],
          'quantityTaken': totalAllocated,
          'excessSources': sources,
        });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction created successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<TransactionProvider>(
                    context,
                    listen: false,
                  ).errorMessage ??
                  'Error',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TransactionProvider>(context);
    final shortages = getSortedList(
      tp.currentMatches['shortages'] ?? [],
      shortageSort,
      false,
      shortageDescending,
    );
    final excesses = getSortedList(
      tp.currentMatches['excesses'] ?? [],
      excessSort,
      true,
      excessDescending,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Match: ${widget.productName}')),
      body: tp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Shortages Column
                      Expanded(
                        child: _buildColumn(
                          title: 'Shortages',
                          color: Colors.red[50]!,
                          items: shortages,
                          currentSort: shortageSort,
                          onSortChanged: (v) =>
                              setState(() => shortageSort = v!),
                          isExcess: false,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      // Excesses Column
                      Expanded(
                        child: _buildColumn(
                          title: 'Excesses',
                          color: Colors.green[50]!,
                          items: excesses,
                          currentSort: excessSort,
                          onSortChanged: (v) => setState(() => excessSort = v!),
                          isExcess: true,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedShortage != null) _buildSummaryBar(),
              ],
            ),
    );
  }

  Widget _buildColumn({
    required String title,
    required Color color,
    required List<dynamic> items,
    required String currentSort,
    required Function(String?) onSortChanged,
    required bool isExcess,
  }) {
    return Container(
      color: color,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentSort,
                        isDense: true,
                        items: ['Time', 'Value', 'Quantity']
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: onSortChanged,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isExcess
                              ? (excessDescending
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward)
                              : (shortageDescending
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward),
                          size: 14,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isExcess) {
                              excessDescending = !excessDescending;
                            } else {
                              shortageDescending = !shortageDescending;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = isExcess
                    ? selectedExcesses.containsKey(item['_id'])
                    : selectedShortage?['_id'] == item['_id'];

                return _buildItemCard(item, isExcess, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item, bool isExcess, bool isSelected) {
    final remainingQty = item['remainingQuantity'] ?? 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExcess) {
            if (selectedShortage == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a shortage first')),
              );
              return;
            }
            if (selectedExcesses.containsKey(item['_id'])) {
              selectedExcesses.remove(item['_id']);
            } else {
              // Calculate how much we still need
              int totalAllocated = selectedExcesses.values.fold(
                0,
                (sum, q) => sum + q,
              );
              int stillNeeded = shortageQuantityToFulfill - totalAllocated;
              if (stillNeeded <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shortage quantity already fulfilled'),
                  ),
                );
                return;
              }
              int toTake = stillNeeded < remainingQty
                  ? stillNeeded
                  : remainingQty;
              selectedExcesses[item['_id']] = toTake;
            }
          } else {
            if (selectedShortage?['_id'] == item['_id']) {
              selectedShortage = null;
              selectedExcesses.clear();
            } else {
              selectedShortage = item;
              shortageQuantityToFulfill = remainingQty;
              selectedExcesses.clear();
            }
          }
        });
      },
      child: Card(
        color: isSelected
            ? (isExcess ? Colors.green[200] : Colors.red[200])
            : Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['pharmacy']['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                'Vol: ${item['volume']['name']}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                isExcess ? 'Qty: $remainingQty' : 'Needed: $remainingQty',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (!isExcess)
                Text(
                  'Max Surplus: ${item['maxSurplus'] ?? 0}',
                  style: const TextStyle(fontSize: 11),
                ),
              if (isExcess)
                Text(
                  'Price: ${item['selectedPrice']}',
                  style: const TextStyle(fontSize: 11),
                ),
              Text(
                DateFormat(
                  'MM-dd HH:mm',
                ).format(DateTime.parse(item['createdAt'])),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              if (isSelected) ...[
                const Divider(),
                Row(
                  children: [
                    const Text('Qty: ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: TextFormField(
                        initialValue: isExcess
                            ? selectedExcesses[item['_id']].toString()
                            : shortageQuantityToFulfill.toString(),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.all(4),
                        ),
                        onChanged: (v) {
                          final val = int.tryParse(v) ?? 0;
                          setState(() {
                            if (isExcess) {
                              if (val > remainingQty) {
                                selectedExcesses[item['_id']] = remainingQty;
                              } else {
                                selectedExcesses[item['_id']] = val;
                              }
                            } else {
                              if (val > remainingQty) {
                                shortageQuantityToFulfill = remainingQty;
                              } else {
                                shortageQuantityToFulfill = val;
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final totalAllocated = selectedExcesses.values.fold(0, (sum, q) => sum + q);
    final isReady =
        totalAllocated > 0 && totalAllocated == shortageQuantityToFulfill;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Allocated: $totalAllocated / $shortageQuantityToFulfill'),
              if (totalAllocated > shortageQuantityToFulfill)
                const Text(
                  'OVER LIMIT!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: isReady ? _submitTransaction : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            child: const Text('SUBMIT TRANSACTION'),
          ),
        ],
      ),
    );
  }
}
