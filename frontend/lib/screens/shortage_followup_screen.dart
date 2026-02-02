import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shortage_provider.dart';
import '../providers/notification_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/ui_utils.dart';

class ShortageFollowUpScreen extends StatefulWidget {
  const ShortageFollowUpScreen({super.key});

  @override
  State<ShortageFollowUpScreen> createState() => _ShortageFollowUpScreenState();
}

class _ShortageFollowUpScreenState extends State<ShortageFollowUpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      final provider = Provider.of<ShortageProvider>(context, listen: false);
      provider.fetchActiveShortages();
      provider.fetchFulfilledShortages();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleShortageFollowup),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<ShortageProvider>(
                context,
                listen: false,
              );
              provider.fetchActiveShortages();
              provider.fetchFulfilledShortages();
              Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).fetchNotifications();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.tabActive),
            Tab(text: l10n.tabFulfilled),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildActiveList(), _buildFulfilledList()],
      ),
    );
  }

  Widget _buildActiveList() {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ShortageProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.activeShortages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.activeShortages.isEmpty) {
          return Center(child: Text(l10n.msgNoActiveShortages));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              provider.fetchActiveShortages(),
              provider.fetchFulfilledShortages(),
              Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).fetchNotifications(),
            ]);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: provider.activeShortages.length,
            itemBuilder: (context, index) {
              final item = provider.activeShortages[index];
              return Card(
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
                          l10n.labelPharmacy(
                            item['pharmacy']?['name'] ?? '...',
                          ),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text('${l10n.labelVolume}: ${item['volume']?['name']}'),
                      const SizedBox(height: 8),
                      Text(l10n.labelQuantityNeeded(item['quantity'] ?? 0)),
                      Text(
                        l10n.labelRemainingQuantity(
                          item['remainingQuantity'] ?? 0,
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              final int total = item['quantity'] ?? 0;
                              final int remaining =
                                  item['remainingQuantity'] ?? 0;
                              if (total - remaining > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.msgCannotDeleteFulfilledShortage,
                                    ),
                                  ),
                                );
                                return;
                              }
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n.dialogConfirmDelete),
                                  content: Text(
                                    l10n.dialogConfirmDeleteShortage,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(l10n.actionCancel),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        provider.deleteShortage(item['_id']);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: Text(l10n.actionDelete),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text(l10n.actionDelete),
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

  Widget _buildFulfilledList() {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ShortageProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.fulfilledShortages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.fulfilledShortages.isEmpty) {
          return Center(child: Text(l10n.msgNoFulfilledShortages));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              provider.fetchActiveShortages(),
              provider.fetchFulfilledShortages(),
              Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).fetchNotifications(),
            ]);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: provider.fulfilledShortages.length,
            itemBuilder: (context, index) {
              final item = provider.fulfilledShortages[index];
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
                              l10n.tabFulfilled,
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
                          l10n.labelPharmacy(
                            item['pharmacy']?['name'] ?? '...',
                          ),
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text('${l10n.labelVolume}: ${item['volume']?['name']}'),
                      const SizedBox(height: 8),
                      Text(l10n.labelQuantityFulfilled(item['quantity'] ?? 0)),
                      const Divider(),
                      Text(
                        l10n.msgShortageRequirementCompleted,
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
}
