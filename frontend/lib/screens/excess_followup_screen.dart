import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/excess_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/notification_provider.dart';
import 'add_excess_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/ui_utils.dart';

class ExcessFollowUpScreen extends StatefulWidget {
  const ExcessFollowUpScreen({super.key});

  @override
  State<ExcessFollowUpScreen> createState() => _ExcessFollowUpScreenState();
}

class _ExcessFollowUpScreenState extends State<ExcessFollowUpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Available Tab State
  String _availableSearchQuery = '';
  String _availableSortField = 'createdAt'; // 'createdAt', 'pharmacy', 'salePercentage'
  bool _availableSortAsc = false;
  String? _availablePharmacyFilter;
  double _availableSaleMin = 0.0;
  double _availableSaleMax = 100.0;

  // Fulfilled Tab State
  String _fulfilledSearchQuery = '';
  String _fulfilledSortField = 'createdAt';
  bool _fulfilledSortAsc = false;
  String? _fulfilledPharmacyFilter;
  double _fulfilledSaleMin = 0.0;
  double _fulfilledSaleMax = 100.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Fetch data
    Future.microtask(() {
      final provider = Provider.of<ExcessProvider>(context, listen: false);
      provider.fetchPendingExcesses();
      provider.fetchAvailableExcesses();
      provider.fetchFulfilledExcesses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isNearExpiry(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      DateTime expiry;
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 2) {
          final month = int.parse(parts[0]);
          final year = 2000 + int.parse(parts[1]);
          // Use last day of the month
          expiry = DateTime(year, month + 1, 0);
        } else {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          expiry = DateTime(year, month, day);
        }
      } else if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = parts.length > 2 ? int.parse(parts[2]) : 1;
        expiry = DateTime(year, month, day);
      } else {
        return false;
      }

      final now = DateTime.now();
      // Near expiry if within 6 months (180 days)
      return expiry.difference(now).inDays < 180;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.titleExcessFollowUp),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<ExcessProvider>(
                context,
                listen: false,
              );
              provider.fetchPendingExcesses();
              provider.fetchAvailableExcesses();
              provider.fetchFulfilledExcesses();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.tabPending),
            Tab(text: AppLocalizations.of(context)!.tabAvailable),
            Tab(text: AppLocalizations.of(context)!.tabFulfilled),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingList(),
          _buildAvailableList(),
          _buildFulfilledList(),
        ],
      ),
    );
  }

  void _showHubSelectionDialog(Map<String, dynamic> item) {
    final provider = Provider.of<ExcessProvider>(context, listen: false);
    String? selectedHubId;
    final qtyController = TextEditingController(
      text: item['remainingQuantity'].toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.titleAddToHub),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.labelSelectHub,
                  ),
                  value: selectedHubId,
                  items: provider.hubs.map((hub) {
                    return DropdownMenuItem<String>(
                      value: hub['_id'],
                      child: Text(hub['name']),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedHubId = val),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.labelHubQuantity,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
            ElevatedButton(
              onPressed:
                  provider.isLoading ||
                      selectedHubId == null ||
                      qtyController.text.isEmpty
                  ? null
                  : () async {
                      final qty = int.tryParse(qtyController.text);
                      if (qty == null ||
                          qty <= 0 ||
                          qty > item['remainingQuantity']) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.msgInvalidQuantity,
                            ),
                          ),
                        );
                        return;
                      }

                      final success = await provider.addToHub(
                        item['_id'],
                        selectedHubId!,
                        qty,
                      );

                      if (success && mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.msgMoveToHubSuccess,
                            ),
                          ),
                        );
                      }
                    },
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(AppLocalizations.of(context)!.actionConfirm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterHeader({
    required String searchQuery,
    required String sortField,
    required bool sortAsc,
    required String? pharmacyFilter,
    required double saleMin,
    required double saleMax,
    required Function(String) onSearchChanged,
    required Function(String, bool) onSortChanged,
    required Function(String?, double, double) onFilterChanged,
    required List<dynamic> items,
  }) {
    // Extract unique pharmacies for the filter dropdown
    final pharmacies = items
        .where((e) => e['pharmacy'] != null)
        .map((e) => e['pharmacy']['name'] as String)
        .toSet()
        .toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Product',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  String? tempPharmacy = pharmacyFilter;
                  double tempMin = saleMin;
                  double tempMax = saleMax;

                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setModalState) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(labelText: 'Pharmacy'),
                                  value: tempPharmacy,
                                  items: [
                                    const DropdownMenuItem<String>(value: null, child: Text('All Pharmacies')),
                                    ...pharmacies.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                                  ],
                                  onChanged: (val) => setModalState(() => tempPharmacy = val),
                                ),
                                const SizedBox(height: 16),
                                Text('Sale % Range: ${tempMin.toInt()}% - ${tempMax.toInt()}%'),
                                RangeSlider(
                                  values: RangeValues(tempMin, tempMax),
                                  min: 0,
                                  max: 100,
                                  divisions: 100,
                                  labels: RangeLabels('${tempMin.toInt()}%', '${tempMax.toInt()}%'),
                                  onChanged: (RangeValues values) {
                                    setModalState(() {
                                      tempMin = values.start;
                                      tempMax = values.end;
                                    });
                                  },
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    onFilterChanged(tempPharmacy, tempMin, tempMax);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Apply Filters'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Sort by: '),
              DropdownButton<String>(
                value: sortField,
                items: const [
                  DropdownMenuItem(value: 'createdAt', child: Text('Date')),
                  DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacy')),
                  DropdownMenuItem(value: 'salePercentage', child: Text('Sale %')),
                ],
                onChanged: (val) {
                  if (val != null) onSortChanged(val, sortAsc);
                },
              ),
              IconButton(
                icon: Icon(sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () => onSortChanged(sortField, !sortAsc),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterAndSortItems(
    List<dynamic> items,
    String searchQuery,
    String sortField,
    bool sortAsc,
    String? pharmacyFilter,
    double saleMin,
    double saleMax,
  ) {
    if (items.isEmpty) return [];

    // Filter
    var filtered = items.where((item) {
      // Search Product Name
      final productName = (item['product']?['name'] ?? '').toString().toLowerCase();
      if (searchQuery.isNotEmpty && !productName.contains(searchQuery.toLowerCase())) {
        return false;
      }
      
      // Filter Pharmacy
      final pharmacyName = (item['pharmacy']?['name'] ?? '').toString();
      if (pharmacyFilter != null && pharmacyFilter.isNotEmpty && pharmacyName != pharmacyFilter) {
        return false;
      }

      // Filter Sale %
      final salePercentage = (item['salePercentage'] as num?)?.toDouble() ?? 0.0;
      if (salePercentage < saleMin || salePercentage > saleMax) {
        return false;
      }

      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      if (sortField == 'pharmacy') {
        final pharA = (a['pharmacy']?['name'] ?? '').toString();
        final pharB = (b['pharmacy']?['name'] ?? '').toString();
        comparison = pharA.compareTo(pharB);
      } else if (sortField == 'salePercentage') {
        final saleA = (a['salePercentage'] as num?)?.toDouble() ?? 0.0;
        final saleB = (b['salePercentage'] as num?)?.toDouble() ?? 0.0;
        comparison = saleA.compareTo(saleB);
      } else {
        // Default createdAt
        final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
        comparison = dateA.compareTo(dateB);
      }
      return sortAsc ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _buildFulfilledList() {
    return Consumer<ExcessProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.fulfilledExcesses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.fulfilledExcesses.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.msgNoFulfilledExcesses),
          );
        }

        var processedList = _filterAndSortItems(
          provider.fulfilledExcesses,
          _fulfilledSearchQuery,
          _fulfilledSortField,
          _fulfilledSortAsc,
          _fulfilledPharmacyFilter,
          _fulfilledSaleMin,
          _fulfilledSaleMax,
        );

        return Column(
          children: [
            _buildFilterHeader(
              searchQuery: _fulfilledSearchQuery,
              sortField: _fulfilledSortField,
              sortAsc: _fulfilledSortAsc,
              pharmacyFilter: _fulfilledPharmacyFilter,
              saleMin: _fulfilledSaleMin,
              saleMax: _fulfilledSaleMax,
              items: provider.fulfilledExcesses,
              onSearchChanged: (val) => setState(() => _fulfilledSearchQuery = val),
              onSortChanged: (field, asc) => setState(() {
                _fulfilledSortField = field;
                _fulfilledSortAsc = asc;
              }),
              onFilterChanged: (phar, min, max) => setState(() {
                _fulfilledPharmacyFilter = phar;
                _fulfilledSaleMin = min;
                _fulfilledSaleMax = max;
              }),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    provider.fetchPendingExcesses(),
                    provider.fetchAvailableExcesses(),
                    provider.fetchFulfilledExcesses(),
                    Provider.of<NotificationProvider>(
                      context,
                      listen: false,
                    ).fetchNotifications(),
                  ]);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: processedList.length,
                  itemBuilder: (context, index) {
                    final item = processedList[index];
                    final expiryStr = item['expiryDate'];

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      color: Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['product']?['name'] ?? 'Unknown Product',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    AppLocalizations.of(context)!.statusFulfilled,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  avatar: const Icon(
                                    Icons.check_circle,
                                    color: Colors.blueGrey,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () =>
                                  UIUtils.showPharmacyInfo(context, item['pharmacy']),
                              child: Text(
                                '${item['pharmacy']?['name']}',
                                style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${AppLocalizations.of(context)!.labelPrice}: ${item['selectedPrice']} ${AppLocalizations.of(context)!.coinsSuffix}',
                            ),
                            Text(
                              AppLocalizations.of(context)!.labelQuantityFulfilled(item['originalQuantity'] ?? 0),
                            ),
                            Text(
                              '${AppLocalizations.of(context)!.labelExpiry}: $expiryStr',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const Divider(),
                            Text(
                              AppLocalizations.of(context)!.msgActionCompletedLocked,
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPendingList() {
    return Consumer<ExcessProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.pendingExcesses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.pendingExcesses.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.msgNoPendingExcesses),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              provider.fetchPendingExcesses(),
              provider.fetchAvailableExcesses(),
              Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).fetchNotifications(),
            ]);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: provider.pendingExcesses.length,
            itemBuilder: (context, index) {
              final item = provider.pendingExcesses[index];
              final expiryStr = item['expiryDate'];
              final isNewPrice = item['isNewPrice'] == true;
              final isShortageFulfillment =
                  item['shortage_fulfillment'] == true;
              final isRejected = item['status'] == 'rejected';

              Color cardColor = Colors.white;
              if (isRejected) {
                cardColor = Colors.red[50]!;
              } else if (isNewPrice) {
                cardColor = Colors.blue[50]!;
              } else if (isShortageFulfillment) {
                cardColor = Colors.purple[50]!;
              }

              return Card(
                color: cardColor,
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['product']?['name'] ?? 'Unknown Product',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            UIUtils.showPharmacyInfo(context, item['pharmacy']),
                        child: Text(
                          '${item['pharmacy']?['name']}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (isNewPrice)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'New Price',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          if (isShortageFulfillment)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Shortage Fulfillment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Builder(
                        builder: (context) {
                          final settings = Provider.of<SettingsProvider>(
                            context,
                          );
                          final effectiveSale =
                              item['salePercentage'] ??
                              (item['shortage_fulfillment'] == true
                                  ? settings.shortageCommission
                                  : settings.minimumCommission);
                          return Text(
                            '${effectiveSale.toStringAsFixed(1)}% ${AppLocalizations.of(context)!.labelOff}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      Text(
                        '${AppLocalizations.of(context)!.labelPrice}: ${item['selectedPrice']} ${AppLocalizations.of(context)!.coinsSuffix}',
                      ),
                      Text(
                        '${AppLocalizations.of(context)!.labelQuantity}: ${item['originalQuantity']}',
                      ),
                      Text(
                        '${AppLocalizations.of(context)!.labelExpiry}: $expiryStr',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isNearExpiry(expiryStr) ? Colors.red : null,
                        ),
                      ),
                      if (isRejected && item['rejectionReason'] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${AppLocalizations.of(context)!.labelRejectionReason} ${item['rejectionReason']}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: provider.isLoading
                                ? null
                                : () {
                                    final int total =
                                        item['originalQuantity'] ?? 0;
                                    final int remaining =
                                        item['remainingQuantity'] ?? 0;
                                    if (total - remaining > 0) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.msgCannotDeleteTakenExcess,
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.labelConfirmDelete,
                                        ),
                                        content: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.msgConfirmDeleteExcess,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.actionCancel,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: provider.isLoading
                                                ? null
                                                : () {
                                                    Navigator.pop(ctx);
                                                    provider.deleteExcess(
                                                      item['_id'],
                                                    );
                                                  },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.actionDelete,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.actionDelete,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: provider.isLoading
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddExcessScreen(initialData: item),
                                      ),
                                    ).then((_) {
                                      if (mounted) {
                                        provider.fetchPendingExcesses();
                                        provider.fetchAvailableExcesses();
                                      }
                                    });
                                  },
                            child: Text(
                              AppLocalizations.of(context)!.actionEdit,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: provider.isLoading
                                ? null
                                : () {
                                    final reasonController =
                                        TextEditingController();
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.labelRejectExcessOffer,
                                        ),
                                        content: TextField(
                                          controller: reasonController,
                                          decoration: InputDecoration(
                                            labelText: AppLocalizations.of(
                                              context,
                                            )!.labelRejectionReason,
                                            hintText: AppLocalizations.of(
                                              context,
                                            )!.hintRejectionReason,
                                          ),
                                          maxLines: 2,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.actionCancel,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: provider.isLoading
                                                ? null
                                                : () {
                                                    if (reasonController.text
                                                        .trim()
                                                        .isEmpty)
                                                      return;
                                                    Navigator.pop(ctx);
                                                    provider.rejectExcess(
                                                      item['_id'],
                                                      reasonController.text
                                                          .trim(),
                                                    );
                                                  },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.actionReject,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context)!.actionReject,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: provider.isLoading
                                ? null
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.labelConfirmApproval,
                                        ),
                                        content: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.msgConfirmApproveExcess,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.actionCancel,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: provider.isLoading
                                                ? null
                                                : () {
                                                    Navigator.pop(ctx);
                                                    provider.approveExcess(
                                                      item['_id'],
                                                    );
                                                  },
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.actionApprove,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context)!.actionApprove,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAvailableList() {
    return Consumer<ExcessProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.availableExcesses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.availableExcesses.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.msgNoAvailableExcesses),
          );
        }

        var processedList = _filterAndSortItems(
          provider.availableExcesses,
          _availableSearchQuery,
          _availableSortField,
          _availableSortAsc,
          _availablePharmacyFilter,
          _availableSaleMin,
          _availableSaleMax,
        );

        return Column(
          children: [
            _buildFilterHeader(
              searchQuery: _availableSearchQuery,
              sortField: _availableSortField,
              sortAsc: _availableSortAsc,
              pharmacyFilter: _availablePharmacyFilter,
              saleMin: _availableSaleMin,
              saleMax: _availableSaleMax,
              items: provider.availableExcesses,
              onSearchChanged: (val) => setState(() => _availableSearchQuery = val),
              onSortChanged: (field, asc) => setState(() {
                _availableSortField = field;
                _availableSortAsc = asc;
              }),
              onFilterChanged: (phar, min, max) => setState(() {
                _availablePharmacyFilter = phar;
                _availableSaleMin = min;
                _availableSaleMax = max;
              }),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    provider.fetchPendingExcesses(),
                    provider.fetchAvailableExcesses(),
                    Provider.of<NotificationProvider>(
                      context,
                      listen: false,
                    ).fetchNotifications(),
                  ]);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: processedList.length,
                  itemBuilder: (context, index) {
                    final item = processedList[index];
                    final expiryStr = item['expiryDate'];
                    final isShortageFulfillment =
                        item['shortage_fulfillment'] == true;

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['product']?['name'] ?? 'Unknown Product',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    item['status'] == 'partially_fulfilled'
                                        ? AppLocalizations.of(
                                            context,
                                          )!.statusPartiallyFulfilled
                                        : AppLocalizations.of(
                                            context,
                                          )!.statusAvailable,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor:
                                      item['status'] == 'partially_fulfilled'
                                      ? Colors.orange[100]
                                      : Colors.green[100],
                                  padding: EdgeInsets.zero,
                                  avatar: Icon(
                                    item['status'] == 'partially_fulfilled'
                                        ? Icons.pending_actions
                                        : Icons.check_circle,
                                    color: item['status'] == 'partially_fulfilled'
                                        ? Colors.orange
                                        : Colors.green,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () =>
                                  UIUtils.showPharmacyInfo(context, item['pharmacy']),
                              child: Text(
                                '${item['pharmacy']?['name']}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (isShortageFulfillment)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Shortage Fulfillment',
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            Builder(
                              builder: (context) {
                                final settings = Provider.of<SettingsProvider>(
                                  context,
                                );
                                final effectiveSale =
                                    item['salePercentage'] ??
                                    (item['shortage_fulfillment'] == true
                                        ? settings.shortageCommission
                                        : settings.minimumCommission);
                                return Text(
                                  '${effectiveSale.toStringAsFixed(1)}% ${AppLocalizations.of(context)!.labelOff}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            Text(
                              '${AppLocalizations.of(context)!.labelPrice}: ${item['selectedPrice']} ${AppLocalizations.of(context)!.coinsSuffix}',
                            ),
                            Text(
                              '${AppLocalizations.of(context)!.labelRemaining}: ${item['remainingQuantity']}/${item['originalQuantity']}',
                            ),
                            Text(
                              '${AppLocalizations.of(context)!.labelExpiry}: $expiryStr',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isNearExpiry(expiryStr) ? Colors.red : null,
                              ),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (item['pharmacy']?['isHub'] != true)
                                  TextButton(
                                    onPressed: provider.isLoading
                                        ? null
                                        : () {
                                            final int total =
                                                item['originalQuantity'] ?? 0;
                                            final int remaining =
                                                item['remainingQuantity'] ?? 0;
                                            if (total - remaining > 0) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.msgCannotDeleteTakenExcess,
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (ctx) {
                                                bool isDeleting = false;
                                                return StatefulBuilder(
                                                  builder: (ctx, setStateDialog) {
                                                    return AlertDialog(
                                                      title: Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.labelConfirmDelete,
                                                      ),
                                                      content: Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.msgConfirmDeleteExcessAvailable,
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: isDeleting
                                                              ? null
                                                              : () => Navigator.pop(ctx),
                                                          child: Text(
                                                            AppLocalizations.of(
                                                              context,
                                                            )!.actionCancel,
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: isDeleting
                                                              ? null
                                                              : () async {
                                                                  setStateDialog(() => isDeleting = true);
                                                                  final success = await provider.deleteExcess(
                                                                    item['_id'],
                                                                  );
                                                                  if (!ctx.mounted) return;
                                                                  Navigator.pop(ctx);
                                                                  if (success) {
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      const SnackBar(
                                                                        content: Text('Excess deleted successfully'),
                                                                      ),
                                                                    );
                                                                    provider.fetchPendingExcesses();
                                                                    provider.fetchAvailableExcesses();
                                                                  } else {
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      SnackBar(
                                                                        content: Text(provider.errorMessage ?? 'Error deleting excess'),
                                                                      ),
                                                                    );
                                                                  }
                                                                },
                                                          style: TextButton.styleFrom(
                                                            foregroundColor: Colors.red,
                                                          ),
                                                          child: isDeleting
                                                              ? const SizedBox(
                                                                  width: 20,
                                                                  height: 20,
                                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                                )
                                                              : Text(
                                                                  AppLocalizations.of(
                                                                    context,
                                                                  )!.actionDelete,
                                                                ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.actionDelete,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: provider.isLoading
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddExcessScreen(initialData: item),
                                            ),
                                          ).then((_) {
                                            if (mounted) {
                                              provider.fetchPendingExcesses();
                                              provider.fetchAvailableExcesses();
                                            }
                                          });
                                        },
                                  child: Text(
                                    AppLocalizations.of(context)!.actionEdit,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (item['pharmacy']?['isHub'] != true)
                                  ElevatedButton(
                                    onPressed: provider.isLoading
                                        ? null
                                        : () {
                                            provider.fetchHubs().then((_) {
                                              if (mounted) {
                                                _showHubSelectionDialog(item);
                                              }
                                            });
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: provider.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.actionAddToHub,
                                          ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
