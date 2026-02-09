import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/ui_utils.dart';
import '../l10n/generated/app_localizations.dart';

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

  final TextEditingController _commissionController = TextEditingController();
  final TextEditingController _buyerCommController = TextEditingController();
  final TextEditingController _sellerRewardController = TextEditingController();

  bool _isInit = true;

  Map<String, dynamic>? selectedShortage;
  int shortageQuantityToFulfill = 0;

  // Map of excessId -> chosenQuantity
  Map<String, int> selectedExcesses = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (settings.minimumCommission != 0) {
        _commissionController.text = settings.minimumCommission.toString();
        _buyerCommController.text = settings.shortageCommission.toString();
        _sellerRewardController.text = settings.shortageSellerReward.toString();
        _isInit = false;
      }
    }
  }

  @override
  void dispose() {
    _commissionController.dispose();
    _buyerCommController.dispose();
    _sellerRewardController.dispose();
    super.dispose();
  }

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
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    sortedList.sort((a, b) {
      int comparison;
      if (criteria == 'Time') {
        comparison = DateTime.parse(
          b['createdAt'],
        ).compareTo(DateTime.parse(a['createdAt']));
      } else if (criteria == 'Quantity') {
        if (isExcess) {
          comparison = b['remainingQuantity'].compareTo(a['remainingQuantity']);
        } else {
          comparison = (b['quantity'] - b['fulfilledQuantity']).compareTo(
            a['quantity'] - a['fulfilledQuantity'],
          );
        }
      } else if (criteria == 'Balance') {
        final balA = (a['pharmacy']?['balance'] ?? 0) as num;
        final balB = (b['pharmacy']?['balance'] ?? 0) as num;
        comparison = balB.compareTo(balA);
      } else if (criteria == 'Expiry' && isExcess) {
        final dateA = _parseExpiryDate(a['expiryDate']);
        final dateB = _parseExpiryDate(b['expiryDate']);
        comparison = dateA.compareTo(dateB);
      } else if (criteria == 'Sale %' && isExcess) {
        final saleA =
            (a['salePercentage'] ??
                    (a['shortage_fulfillment'] == true
                        ? settings.shortageCommission
                        : settings.minimumCommission))
                as num;
        final saleB =
            (b['salePercentage'] ??
                    (b['shortage_fulfillment'] == true
                        ? settings.shortageCommission
                        : settings.minimumCommission))
                as num;
        comparison = saleB.compareTo(saleA);
      } else {
        comparison = 0;
      }
      return descending ? comparison : -comparison;
    });

    return sortedList;
  }

  void _submitTransaction() async {
    final l10n = AppLocalizations.of(context)!;
    if (selectedShortage == null || selectedExcesses.isEmpty) return;

    final totalAllocated = selectedExcesses.values.fold(0, (sum, q) => sum + q);
    if (totalAllocated == 0) return;

    final List<Map<String, dynamic>> sources = [];
    selectedExcesses.forEach((id, q) {
      if (q > 0) {
        sources.add({'stockExcessId': id, 'quantity': q});
      }
    });

    final excesses =
        Provider.of<TransactionProvider>(
              context,
              listen: false,
            ).currentMatches['excesses']
            as List;
    final selectedExcessData = excesses
        .where((e) => selectedExcesses.containsKey(e['_id']))
        .toList();

    final bool isAnySF = selectedExcessData.any(
      (e) => e['shortage_fulfillment'] == true,
    );

    if (isAnySF) {
      final buyerComm = double.tryParse(_buyerCommController.text) ?? 0.0;
      final sellerBonus = double.tryParse(_sellerRewardController.text) ?? 0.0;

      if (buyerComm < sellerBonus) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Buyer Commission must be greater than or equal to Seller Bonus (Reward)',
              ),
            ),
          );
        }
        return;
      }
    }

    final success =
        await Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).createTransaction({
          'shortageId': selectedShortage!['_id'],
          'quantityTaken': totalAllocated,
          'excessSources': sources,
          'shortage_fulfillment': isAnySF,
          'buyerCommissionRatio': double.tryParse(_buyerCommController.text),
          'sellerBonusRatio': double.tryParse(_sellerRewardController.text),
        });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.msgTransactionCreated)));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<TransactionProvider>(
                    context,
                    listen: false,
                  ).errorMessage ??
                  l10n.msgGenericError,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TransactionProvider>(context);
    final l10n = AppLocalizations.of(context)!;
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
      appBar: AppBar(title: Text(l10n.titleMatchProduct(widget.productName))),
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
                          title: l10n.labelShortages,
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
                          title: l10n.labelExcesses,
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
                if (selectedShortage != null) _buildSummaryBar(tp),
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
                        value: (isExcess && currentSort == 'Sale %')
                            ? 'Sale %'
                            : (currentSort == 'Time' ||
                                      currentSort == 'Quantity' ||
                                      currentSort == 'Balance' ||
                                      currentSort == 'Expiry'
                                  ? currentSort
                                  : 'Time'),
                        isDense: true,
                        items:
                            (isExcess
                                    ? [
                                        'Time',
                                        'Quantity',
                                        'Balance',
                                        'Expiry',
                                        'Sale %',
                                      ]
                                    : ['Time', 'Quantity', 'Balance'])
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      _getLocalizedSort(e),
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

  String _getLocalizedSort(String e) {
    final l10n = AppLocalizations.of(context)!;
    switch (e) {
      case 'Time':
        return l10n.labelTime;
      case 'Quantity':
        return l10n.labelQuantity;
      case 'Balance':
        return l10n.labelBalance;
      case 'Expiry':
        return l10n.labelExpiry;
      case 'Sale %':
        return l10n.labelSalePercentage;
      default:
        return e;
    }
  }

  Widget _buildItemCard(dynamic item, bool isExcess, bool isSelected) {
    final remainingQty = item['remainingQuantity'] ?? 0;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExcess) {
            if (selectedShortage == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.msgSelectShortageFirst)),
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
                  SnackBar(content: Text(l10n.msgShortageFulfilled)),
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
            : (isExcess && item['shortage_fulfillment'] == true
                  ? Colors.purple[50]
                  : Colors.white),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isExcess && item['shortage_fulfillment'] == true)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.labelShortageFulfillment,
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          UIUtils.showPharmacyInfo(context, item['pharmacy']),
                      child: Text(
                        item['pharmacy']['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.priceCoins(
                        (item['pharmacy']['balance'] ?? 0).toStringAsFixed(0),
                      ),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                l10n.labelVol(item['volume']['name']),
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                isExcess
                    ? '${l10n.labelQuantity}: $remainingQty'
                    : l10n.labelNeeded(remainingQty),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (isExcess)
                Text(
                  l10n.labelPriceWithAmount(item['selectedPrice'].toString()),
                  style: const TextStyle(fontSize: 11),
                ),
              if (isExcess)
                Builder(
                  builder: (context) {
                    final settings = Provider.of<SettingsProvider>(context);
                    final effectiveSale =
                        item['salePercentage'] ??
                        (item['shortage_fulfillment'] == true
                            ? settings.shortageCommission
                            : settings.minimumCommission);
                    return Text(
                      l10n.labelSaleRatio(effectiveSale),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    );
                  },
                ),
              if (isExcess && item['expiryDate'] != null)
                Text(
                  '${l10n.labelExpiry}: ${item['expiryDate']}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _isNearExpiry(item['expiryDate'])
                        ? Colors.red
                        : Colors.grey[600],
                  ),
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
                    Text(
                      '${l10n.labelQuantity}: ',
                      style: const TextStyle(fontSize: 12),
                    ),
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

  Widget _buildSummaryBar(TransactionProvider tp) {
    final l10n = AppLocalizations.of(context)!;
    final totalAllocated = selectedExcesses.values.fold(0, (sum, q) => sum + q);
    final isReady =
        totalAllocated > 0 && totalAllocated == shortageQuantityToFulfill;

    final excesses = tp.currentMatches['excesses'] as List? ?? [];
    final selectedExcessData = excesses
        .where((e) => selectedExcesses.containsKey(e['_id']))
        .toList();
    final bool hasSF = selectedExcessData.any(
      (e) => e['shortage_fulfillment'] == true,
    );

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
              Text(
                l10n.labelAllocated(totalAllocated, shortageQuantityToFulfill),
              ),
              if (totalAllocated > shortageQuantityToFulfill)
                Text(
                  l10n.msgOverLimit,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          if (hasSF) ...[
            const SizedBox(height: 12),
            const Divider(),
            Text(
              l10n.labelAdminOverrides,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ratioField(
                    controller: _buyerCommController,
                    label: l10n.labelBuyerComm,
                    hint: l10n.hintShFulfill,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ratioField(
                    controller: _sellerRewardController,
                    label: l10n.labelSellerRew,
                    hint: l10n.hintShFulfill,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isReady && !tp.isLoading ? _submitTransaction : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            child: tp.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(l10n.actionSubmitTransaction),
          ),
        ],
      ),
    );
  }

  Widget _ratioField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
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
    } catch (e) {}
    return DateTime(2099, 12, 31);
  }

  bool _isNearExpiry(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    final expiry = _parseExpiryDate(dateStr);
    final now = DateTime.now();
    final difference = expiry.difference(now).inDays;
    return difference < (6 * 30);
  }
}
