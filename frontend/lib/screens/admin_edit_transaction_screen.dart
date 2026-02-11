import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../l10n/generated/app_localizations.dart';

class AdminEditTransactionScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const AdminEditTransactionScreen({super.key, required this.transaction});

  @override
  State<AdminEditTransactionScreen> createState() =>
      _AdminEditTransactionScreenState();
}

class _AdminEditTransactionScreenState
    extends State<AdminEditTransactionScreen> {
  bool _isLoading = false;
  List<dynamic> _matches = [];
  final Map<String, int> _selections = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Current sources in this transaction
    final sources = widget.transaction['stockExcessSources'] as List;
    for (var source in sources) {
      _selections[source['stockExcess']['_id']] = source['quantity'];
    }

    // Fetch matching excesses from market
    Future.microtask(() => _fetchMatches());
  }

  Future<void> _fetchMatches() async {
    setState(() => _isLoading = true);
    try {
      final shortage = widget.transaction['stockShortage']['shortage'];
      final productId = shortage['product']['_id'];
      final volumeId = shortage['volume']['_id'];
      final targetPrice = shortage['targetPrice'];

      // If the transaction relates to an order, exclude shortage fulfillment excesses
      final bool isOrder = shortage['order'] != null;

      final results =
          await Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).fetchMatchesForProduct(
            productId,
            price: targetPrice?.toDouble(),
            excludeShortageFulfillment: isOrder,
          );

      final excesses = results['excesses'] as List;
      // Filter by volume
      final filtered = excesses
          .where((e) => e['volume']['_id'] == volumeId)
          .toList();

      setState(() {
        _matches = filtered;
      });
    } catch (e) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _getTotalSelected() {
    return _selections.values.fold(0, (sum, val) => sum + val);
  }

  Future<void> _saveChanges() async {
    final totalSelected = _getTotalSelected();
    if (totalSelected == 0) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.msgTotalQtyCannotBeZero)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final excessSources = _selections.entries.map((e) {
        return {'stockExcessId': e.key, 'quantity': e.value};
      }).toList();

      final data = {
        'quantityTaken': totalSelected,
        'excessSources': excessSources,
      };

      final success = await Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).updateTransaction(widget.transaction['_id'], data);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.msgTransactionUpdated,
              ),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<TransactionProvider>(
                      context,
                      listen: false,
                    ).errorMessage ??
                    AppLocalizations.of(context)!.msgFailedUpdateTransaction,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortage = widget.transaction['stockShortage']['shortage'];
    final product = shortage['product']['name'];
    final volume = shortage['volume']['name'];
    final bool isOrder = shortage['order'] != null;

    // Original available = remaining + current portion in this tx
    final l10n = AppLocalizations.of(context)!;
    final int currentTxQty =
        widget.transaction['stockShortage']['quantityTaken'];
    final int remainingNeeded = shortage['remainingQuantity'] ?? 0;
    final int maxAllowed = currentTxQty + remainingNeeded;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.titleEditTransaction(
            widget.transaction['serial']?.toString() ?? '',
          ),
        ),
      ),
      body: _isLoading && _matches.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header: Shortage Info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text('Volume: $volume'),
                              ],
                            ),
                          ),
                          if (isOrder)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.labelOrderBadge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              l10n.labelTotalOriginalNeeded,
                              '${shortage['quantity']} ${l10n.labelUnitsShort}',
                            ),
                            _buildInfoRow(
                              l10n.labelAvailableOriginal,
                              '$maxAllowed ${l10n.labelUnitsShort}',
                            ),
                            const Divider(),
                            _buildInfoRow(
                              l10n.labelTotalDistribution,
                              '${_getTotalSelected()} ${l10n.labelUnitsShort}',
                              valueColor: _getTotalSelected() > maxAllowed
                                  ? Colors.red
                                  : Colors.green,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Matches List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _matches.length,
                    itemBuilder: (context, index) {
                      final excess = _matches[index];
                      final excessId = excess['_id'];
                      final int currentSelected = _selections[excessId] ?? 0;

                      // Calculate "Original Available" in this specific excess:
                      // Available = excess.remainingQuantity + (original portion provided by this transaction to this excess)
                      int originalPortionInTx = 0;
                      final txSources =
                          widget.transaction['stockExcessSources'] as List;
                      for (var src in txSources) {
                        if (src['stockExcess']['_id'] == excessId) {
                          originalPortionInTx = src['quantity'];
                          break;
                        }
                      }

                      final int totalAvailableFromExcess =
                          (excess['remainingQuantity'] as int) +
                          originalPortionInTx;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                          '${l10n.labelAvailableOriginal} $totalAvailableFromExcess ${l10n.labelUnitsShort}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${l10n.labelPrice}: ${excess['selectedPrice']} ${l10n.labelCoins}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: currentSelected > 0
                                            ? () => setState(() {
                                                _selections[excessId] =
                                                    currentSelected - 1;
                                                if (_selections[excessId] == 0)
                                                  _selections.remove(excessId);
                                              })
                                            : null,
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '$currentSelected',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed:
                                            currentSelected <
                                                    totalAvailableFromExcess &&
                                                _getTotalSelected() < maxAllowed
                                            ? () => setState(() {
                                                _selections[excessId] =
                                                    currentSelected + 1;
                                              })
                                            : null,
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (originalPortionInTx > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.bookmark,
                                        size: 12,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.labelPortionInTx(
                                          originalPortionInTx,
                                        ),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLoading ||
                              _getTotalSelected() > maxAllowed ||
                              _getTotalSelected() == 0
                          ? null
                          : _saveChanges,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isLoading
                            ? l10n.msgExecuting
                            : l10n.actionUpdateTransaction,
                      ),
                      style: _isLoading
                          ? ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey,
                              disabledForegroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            )
                          : ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
