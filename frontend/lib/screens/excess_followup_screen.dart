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

        return RefreshIndicator(
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
            itemCount: provider.fulfilledExcesses.length,
            itemBuilder: (context, index) {
              final item = provider.fulfilledExcesses[index];
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
                        '${AppLocalizations.of(context)!.labelQuantityFulfilled}: ${item['originalQuantity']}',
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
              // Highlighting Logic
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
                        item['product']['name'] ?? 'Unknown Product',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            UIUtils.showPharmacyInfo(context, item['pharmacy']),
                        child: Text(
                          '${item['pharmacy']['name']}',
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

                      // Always show percentage (default if not provided)
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
                            onPressed: () {
                              final int total = item['originalQuantity'] ?? 0;
                              final int remaining =
                                  item['remainingQuantity'] ?? 0;
                              if (total - remaining > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        provider.deleteExcess(item['_id']);
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
                            onPressed: () {
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
                            onPressed: () {
                              final reasonController = TextEditingController();
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
                                      onPressed: () {
                                        if (reasonController.text
                                            .trim()
                                            .isEmpty)
                                          return;
                                        Navigator.pop(ctx);
                                        provider.rejectExcess(
                                          item['_id'],
                                          reasonController.text.trim(),
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
                            child: Text(
                              AppLocalizations.of(context)!.actionReject,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
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
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        provider.approveExcess(item['_id']);
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
                            child: Text(
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
            itemCount: provider.availableExcesses.length,
            itemBuilder: (context, index) {
              final item = provider.availableExcesses[index];
              // Highlighting Logic
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
                              item['product']['name'] ?? 'Unknown Product',
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
                          '${item['pharmacy']['name']}',
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

                      // Always show percentage (default if not provided)
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
                          TextButton(
                            onPressed: () {
                              final int total = item['originalQuantity'] ?? 0;
                              final int remaining =
                                  item['remainingQuantity'] ?? 0;
                              if (total - remaining > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                                    )!.msgConfirmDeleteExcessAvailable,
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
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        provider.deleteExcess(item['_id']);
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
                            onPressed: () {
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
}
