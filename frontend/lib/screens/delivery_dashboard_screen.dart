import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/delivery_request_provider.dart';
import 'login_screen.dart';

import '../providers/notification_provider.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    Future.microtask(() => _fetchInitialData());
  }

  void _fetchInitialData() {
    Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).fetchTransactions();
    Provider.of<DeliveryRequestProvider>(
      context,
      listen: false,
    ).fetchMyRequests();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      // Refresh when user clicks a tab
      _fetchInitialData();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _showPharmacyInfo(BuildContext context, dynamic pharmacy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pharmacy['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(pharmacy['address'] ?? 'No address provided'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(pharmacy['phone'] ?? 'No phone provided'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _requestAction(
    BuildContext context,
    String transactionId,
    String type,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final dripProvider = Provider.of<DeliveryRequestProvider>(
      context,
      listen: false,
    );
    final transProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    final success = await dripProvider.createRequest(transactionId, type);

    if (!context.mounted) return;

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Request for ${type == 'accept' ? 'Acceptance' : 'Completion'} sent!',
          ),
        ),
      );
      transProvider.fetchTransactions();
    } else {
      final error = dripProvider.errorMessage;
      messenger.showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to send request')),
      );
    }
  }

  void _assignAction(String transactionId) async {
    final messenger = ScaffoldMessenger.of(context);
    final transProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    print('[DEBUG] _assignAction triggered for $transactionId');

    // 1. Show persistent indicator
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            Text('Assigning to you...'),
          ],
        ),
        duration: Duration(minutes: 1),
      ),
    );

    try {
      // 2. Perform assignment
      final success = await transProvider.assignTransaction(transactionId);
      print('[DEBUG] assignTransaction result: $success');

      if (!mounted) {
        print('[DEBUG] State no longer mounted');
        return;
      }

      // Important: hide loading before showing next message
      messenger.hideCurrentSnackBar();

      if (success) {
        print('[DEBUG] Hiding loading snackbar and showing success');
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Success! Transaction #${transactionId.substring(transactionId.length - 6)} assigned.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        print('[DEBUG] Animating to My Tasks tab');
        _tabController.animateTo(1);
        transProvider.fetchTransactions();
      } else {
        print('[DEBUG] Assignment failed, showing error and reloading');

        // Await refresh so the list is updated while the snackbar shows
        await transProvider.fetchTransactions();

        if (!mounted) return;

        final error = transProvider.errorMessage;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              error ?? 'Assignment failed. Check if it\'s still available.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('[DEBUG] _assignAction error: $e');
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      print('[DEBUG] _assignAction finally block');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Dashboard'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/medisync.png'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blue[100],
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'AVAILABLE'),
            Tab(icon: Icon(Icons.my_library_books), text: 'MY TASKS'),
            Tab(icon: Icon(Icons.history), text: 'HISTORY'),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      left: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationProvider.unreadCount.toString(),
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
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, DeliveryRequestProvider>(
        builder: (context, transProvider, dripProvider, _) {
          if (transProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeTransactions = transProvider.transactions
              .where(
                (t) => t['status'] == 'pending' || t['status'] == 'accepted',
              )
              .toList();

          final availableTransactions = activeTransactions
              .where((t) => t['delivery'] == null)
              .toList();

          final myTransactions = activeTransactions
              .where(
                (t) =>
                    t['delivery'] != null &&
                    t['delivery']['_id'] == currentUser?['_id'],
              )
              .toList();

          final historyTransactions = transProvider.transactions
              .where(
                (t) =>
                    (t['status'] == 'completed' ||
                        t['status'] == 'cancelled' ||
                        t['status'] == 'rejected') &&
                    t['delivery'] != null &&
                    t['delivery']['_id'] == currentUser?['_id'],
              )
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionList(
                context,
                availableTransactions,
                dripProvider,
                transProvider,
                isAvailableTab: true,
              ),
              _buildTransactionList(
                context,
                myTransactions,
                dripProvider,
                transProvider,
                isAvailableTab: false,
              ),
              _buildTransactionList(
                context,
                historyTransactions,
                dripProvider,
                transProvider,
                isAvailableTab: false,
                isHistoryTab: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<dynamic> transactions,
    DeliveryRequestProvider dripProvider,
    TransactionProvider transProvider, {
    required bool isAvailableTab,
    bool isHistoryTab = false,
  }) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          isAvailableTab
              ? 'No available transactions.'
              : (isHistoryTab
                    ? 'No history found.'
                    : 'No tasks assigned to you.'),
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await transProvider.fetchTransactions();
        await dripProvider.fetchMyRequests();
      },
      child: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final status = tx['status'];
          final shortagePh =
              tx['stockShortage']?['shortage']?['pharmacy'] ?? {};
          final excessPhs = (tx['stockExcessSources'] ?? [])
              .map((s) => s['stockExcess']?['pharmacy'] ?? {})
              .toList();

          final hasPendingRequest = dripProvider.myRequests.any(
            (r) => r['transaction'] == tx['_id'] && r['status'] == 'pending',
          );

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaction #${tx['serial'] ?? tx['_id'].toString().substring(tx['_id'].toString().length - 6)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const Divider(),
                  // Product Info Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.medication_outlined,
                        size: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx['stockShortage']?['shortage']?['product']?['name'] ??
                                  'Unknown Product',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Volume: ${tx['stockShortage']['shortage']['volume']?['name'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              tx['totalQuantity'].toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                            Text(
                              'UNITS',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const Text(
                    'Shortage Pharmacy:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(shortagePh['name'] ?? 'Unknown Pharmacy'),
                    subtitle: Text(shortagePh['address'] ?? 'No address'),
                    trailing: const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                    ),
                    onTap: () => _showPharmacyInfo(context, shortagePh),
                  ),
                  const Text(
                    'Excess Pharmacy:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  ...excessPhs.map(
                    (eph) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(eph['name']),
                      subtitle: Text(eph['address'] ?? ''),
                      trailing: const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                      ),
                      onTap: () => _showPharmacyInfo(context, eph),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isAvailableTab)
                        ElevatedButton.icon(
                          onPressed: () => _assignAction(tx['_id']),
                          icon: const Icon(Icons.add_task),
                          label: const Text('Assign to Me'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      if (!isAvailableTab &&
                          !isHistoryTab &&
                          !hasPendingRequest &&
                          status == 'pending')
                        ElevatedButton.icon(
                          onPressed: () =>
                              _requestAction(context, tx['_id'], 'accept'),
                          icon: const Icon(Icons.check),
                          label: const Text('Request Acceptance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      if (!isAvailableTab &&
                          !isHistoryTab &&
                          !hasPendingRequest &&
                          status == 'accepted')
                        ElevatedButton.icon(
                          onPressed: () =>
                              _requestAction(context, tx['_id'], 'complete'),
                          icon: const Icon(Icons.done_all),
                          label: const Text('Request Completion'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      if (!isAvailableTab && !isHistoryTab && hasPendingRequest)
                        const Chip(
                          label: Text('Request Pending...'),
                          backgroundColor: Colors.amber,
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
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'pending') color = Colors.orange;
    if (status == 'accepted') color = Colors.blue;
    if (status == 'completed') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
