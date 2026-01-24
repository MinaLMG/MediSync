import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/medisync.png'),
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
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: const AdminHomeTab(),
    );
  }
}

class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Start Transactions',
        'icon': Icons.swap_horiz,
        'color': Colors.blue,
      },
      {
        'title': 'View Transactions',
        'icon': Icons.track_changes,
        'color': Colors.deepOrange,
      },
      {
        'title': 'Follow-up Excesses',
        'icon': Icons.trending_up,
        'color': Colors.green,
      },
      {
        'title': 'Follow-up Shortages',
        'icon': Icons.trending_down,
        'color': Colors.red,
      },
      {
        'title': 'Delivery Requests',
        'icon': Icons.local_shipping,
        'color': Colors.blueGrey,
      },
      {
        'title': 'Manage Products',
        'icon': Icons.inventory_2,
        'color': Colors.orange,
      },
      {
        'title': 'Product Suggestions',
        'icon': Icons.lightbulb,
        'color': Colors.amber,
      },
      {
        'title': 'Manage Pharmacies',
        'icon': Icons.local_pharmacy,
        'color': Colors.teal,
      },
      {'title': 'Manage Users', 'icon': Icons.people, 'color': Colors.purple},
      {
        'title': 'App Suggestions',
        'icon': Icons.feedback,
        'color': Colors.indigo,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Consumer<AppSuggestionProvider>(
        builder: (context, suggestionProvider, _) {
          return GridView.builder(
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
              if (item['title'] == 'Follow-up Excesses') {
                badgeCount = suggestionProvider.pendingExcessCount;
              } else if (item['title'] == 'Product Suggestions') {
                badgeCount = suggestionProvider.pendingProductSuggestionsCount;
              } else if (item['title'] == 'Manage Users') {
                badgeCount = suggestionProvider.waitingUsersCount;
              } else if (item['title'] == 'App Suggestions') {
                badgeCount = suggestionProvider.appSuggestionsCount;
              } else if (item['title'] == 'Delivery Requests') {
                badgeCount = suggestionProvider.deliveryRequestsCount;
              }

              return _buildMenuCard(
                context,
                item['title'],
                item['icon'],
                item['color'],
                badgeCount: badgeCount,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    int badgeCount = 0,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (title == 'Start Transactions') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminMatchableProductsScreen(),
              ),
            );
          } else if (title == 'View Transactions') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FollowUpTransactionsScreen(),
              ),
            );
          } else if (title == 'Follow-up Excesses') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ExcessFollowUpScreen(),
              ),
            );
          } else if (title == 'Follow-up Shortages') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ShortageFollowUpScreen(),
              ),
            );
          } else if (title == 'Manage Users') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminManageUsersScreen(),
              ),
            );
          } else if (title == 'Manage Pharmacies') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminPharmaciesScreen(),
              ),
            );
          } else if (title == 'Manage Products') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminProductListScreen(),
              ),
            );
          } else if (title == 'Product Suggestions') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageSuggestionsScreen(),
              ),
            );
          } else if (title == 'App Suggestions') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminViewSuggestionsScreen(),
              ),
            );
          } else if (title == 'Delivery Requests') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDeliveryRequestsScreen(),
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
