import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'excess_followup_screen.dart';
import 'shortage_followup_screen.dart';
import 'admin_matchable_products_screen.dart';
import 'follow_up_transactions_screen.dart';
import 'admin_manage_users_screen.dart';
import 'admin_pharmacies_screen.dart';
import 'admin_product_list_screen.dart';
import 'manage_suggestions_screen.dart';
import '../providers/app_suggestion_provider.dart';
import '../providers/notification_provider.dart';
import 'notifications_screen.dart';
import 'admin_view_suggestions_screen.dart';
import 'admin_delivery_requests_screen.dart';
import 'admin_account_updates_screen.dart';
import 'admin_settings_screen.dart';
import 'profile_screen.dart';
import 'admin_order_list_screen.dart';
import 'admin/admin_transactions_summary_screen.dart';
import '../l10n/generated/app_localizations.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<AppSuggestionProvider>(
          context,
          listen: false,
        ).fetchPendingCounts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.adminDashboardTitle),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
            ),
            child: Image.asset('assets/images/medisync_full.png'),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context)!.reloadTooltip,
            onPressed: () {
              _refreshIndicatorKey.currentState?.show();
            },
          ),
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
      body: AdminHomeTab(refreshIndicatorKey: _refreshIndicatorKey),
    );
  }
}

class AdminHomeTab extends StatelessWidget {
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey;
  const AdminHomeTab({super.key, required this.refreshIndicatorKey});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'id': 'Start Transactions',
        'title': AppLocalizations.of(context)!.menuStartTransactions,
        'icon': Icons.swap_horiz,
        'color': Colors.blue,
      },
      {
        'id': 'View Transactions',
        'title': AppLocalizations.of(context)!.menuViewTransactions,
        'icon': Icons.track_changes,
        'color': Colors.deepOrange,
      },
      {
        'id': 'Follow-up Excesses',
        'title': AppLocalizations.of(context)!.menuFollowUpExcesses,
        'icon': Icons.trending_up,
        'color': Colors.green,
      },
      {
        'id': 'Follow-up Shortages',
        'title': AppLocalizations.of(context)!.menuFollowUpShortages,
        'icon': Icons.trending_down,
        'color': Colors.red,
      },
      {
        'id': 'Manage Orders',
        'title': AppLocalizations.of(context)!.menuManageOrders,
        'icon': Icons.assignment,
        'color': Colors.lime,
      },
      {
        'id': 'Delivery Requests',
        'title': AppLocalizations.of(context)!.menuDeliveryRequests,
        'icon': Icons.local_shipping,
        'color': Colors.blueGrey,
      },
      {
        'id': 'Manage Products',
        'title': AppLocalizations.of(context)!.menuManageProducts,
        'icon': Icons.inventory_2,
        'color': Colors.orange,
      },
      {
        'id': 'Product Suggestions',
        'title': AppLocalizations.of(context)!.menuProductSuggestions,
        'icon': Icons.lightbulb,
        'color': Colors.amber,
      },
      {
        'id': 'Manage Pharmacies',
        'title': AppLocalizations.of(context)!.menuManagePharmacies,
        'icon': Icons.local_pharmacy,
        'color': Colors.teal,
      },
      {
        'id': 'Manage Users',
        'title': AppLocalizations.of(context)!.menuManageUsers,
        'icon': Icons.people,
        'color': Colors.purple,
      },
      {
        'id': 'App Suggestions',
        'title': AppLocalizations.of(context)!.menuAppSuggestions,
        'icon': Icons.feedback,
        'color': Colors.indigo,
      },
      {
        'id': 'Account Updates',
        'title': AppLocalizations.of(context)!.menuAccountUpdates,
        'icon': Icons.manage_accounts,
        'color': Colors.brown,
      },
      {
        'id': 'System Settings',
        'title': AppLocalizations.of(context)!.menuSystemSettings,
        'icon': Icons.settings,
        'color': Colors.grey[700],
      },
      {
        'id': 'Transactions Summary',
        'title': AppLocalizations.of(context)!.menuAdminTransactionsSummary,
        'icon': Icons.summarize,
        'color': Colors.blue[900],
      },
    ];

    return RefreshIndicator(
      key: refreshIndicatorKey,
      onRefresh: () async {
        await Provider.of<AppSuggestionProvider>(
          context,
          listen: false,
        ).fetchPendingCounts();
        await Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).fetchNotifications();
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<AppSuggestionProvider>(
          builder: (context, suggestionProvider, _) {
            return GridView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(), // Important for pull-to-refresh
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                int badgeCount = 0;
                final id = item['id'];

                if (id == 'Follow-up Excesses') {
                  badgeCount = suggestionProvider.pendingExcessCount;
                } else if (id == 'Product Suggestions') {
                  badgeCount =
                      suggestionProvider.pendingProductSuggestionsCount;
                } else if (id == 'Manage Users') {
                  badgeCount = suggestionProvider.waitingUsersCount;
                } else if (id == 'App Suggestions') {
                  badgeCount = suggestionProvider.appSuggestionsCount;
                } else if (id == 'Delivery Requests') {
                  badgeCount = suggestionProvider.deliveryRequestsCount;
                } else if (id == 'Account Updates') {
                  badgeCount = suggestionProvider.pendingAccountUpdatesCount;
                } else if (id == 'Manage Orders') {
                  badgeCount = suggestionProvider.pendingOrdersCount;
                }

                return _buildMenuCard(
                  context,
                  item['title'],
                  item['id'],
                  item['icon'],
                  item['color'],
                  badgeCount: badgeCount,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String id,
    IconData icon,
    Color color, {
    int badgeCount = 0,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (id == 'Start Transactions') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminMatchableProductsScreen(),
              ),
            );
          } else if (id == 'View Transactions') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FollowUpTransactionsScreen(),
              ),
            );
          } else if (id == 'Follow-up Excesses') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ExcessFollowUpScreen(),
              ),
            );
          } else if (id == 'Follow-up Shortages') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ShortageFollowUpScreen(),
              ),
            );
          } else if (id == 'Manage Users') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminManageUsersScreen(),
              ),
            );
          } else if (id == 'Manage Pharmacies') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminPharmaciesScreen(),
              ),
            );
          } else if (id == 'Manage Products') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminProductListScreen(),
              ),
            );
          } else if (id == 'Product Suggestions') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageSuggestionsScreen(),
              ),
            );
          } else if (id == 'App Suggestions') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminViewSuggestionsScreen(),
              ),
            );
          } else if (id == 'Delivery Requests') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDeliveryRequestsScreen(),
              ),
            );
          } else if (id == 'Account Updates') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminAccountUpdatesScreen(),
              ),
            );
          } else if (id == 'System Settings') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminSettingsScreen(),
              ),
            );
          } else if (id == 'Manage Orders') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminOrderListScreen(),
              ),
            );
          } else if (id == 'Transactions Summary') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminTransactionsSummaryScreen(),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 32, color: color),
                  if (badgeCount > 0)
                    Positioned(
                      right: -5,
                      top: -5,
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
                          '$badgeCount',
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
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
