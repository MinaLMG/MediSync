import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shortage_provider.dart';
import '../providers/product_provider.dart';
import 'add_excess_screen.dart';
import 'add_shortage_screen.dart';
import 'requests_history_screen.dart';
import 'admin_matchable_products_screen.dart';
import 'follow_up_transactions_screen.dart';
import 'suggest_product_screen.dart';
import 'suggestions_complaints_screen.dart';
import 'admin_view_suggestions_screen.dart';
import 'admin_manage_users_screen.dart';
import '../providers/app_suggestion_provider.dart';
import '../providers/notification_provider.dart';
import 'balance_history_screen.dart';
import 'create_order_screen.dart';
import '../l10n/generated/app_localizations.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<ShortageProvider>(
        context,
        listen: false,
      ).fetchGlobalActiveShortages();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      Provider.of<AppSuggestionProvider>(
        context,
        listen: false,
      ).fetchPendingCounts();
    });
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!mounted) return;
      final provider = Provider.of<ShortageProvider>(context, listen: false);
      if (provider.globalShortages.length > 1) {
        if (_pageController.hasClients) {
          int nextPage = _currentPage + 1;
          if (nextPage >= provider.globalShortages.length) {
            nextPage = 0;
          }

          _currentPage = nextPage;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    final shortages = Provider.of<ShortageProvider>(context, listen: false);
    final products = Provider.of<ProductProvider>(context, listen: false);
    final suggestions = Provider.of<AppSuggestionProvider>(
      context,
      listen: false,
    );
    final notifications = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final auth = Provider.of<AuthProvider>(context, listen: false);

    await Future.wait([
      shortages.fetchGlobalActiveShortages(),
      products.fetchProducts(),
      suggestions.fetchPendingCounts(),
      notifications.fetchNotifications(),
      if (auth.userRole != 'admin') auth.refreshProfile(),
    ]);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final provider = Provider.of<ShortageProvider>(context);
    final isAdmin = authProvider.userRole == 'admin';
    final shortages = provider.globalShortages;

    final List<Map<String, dynamic>> menuItems = [
      {
        'title': AppLocalizations.of(context)!.menuRequestsHistory,
        'originalTitle': 'Requests History',
        'icon': Icons.history,
        'color': Colors.blue,
      },
      {
        'title': AppLocalizations.of(context)!.menuShoppingTour,
        'originalTitle': 'Shopping Tour',
        'icon': Icons.shopping_cart,
        'color': Colors.orange,
      },
      {
        'title': AppLocalizations.of(context)!.menuAddShortage,
        'originalTitle': 'Add Shortage',
        'icon': Icons.remove_circle_outline,
        'color': Colors.red,
      },
      {
        'title': AppLocalizations.of(context)!.menuAddExcess,
        'originalTitle': 'Add Excess',
        'icon': Icons.add_circle_outline,
        'color': Colors.green,
      },
      if (isAdmin) ...[
        {
          'title': AppLocalizations.of(context)!.menuStartTransactions,
          'originalTitle': 'Start Transactions',
          'icon': Icons.swap_horiz,
          'color': Colors.indigo,
        },
        {
          'title': AppLocalizations.of(context)!.menuViewTransactions,
          'originalTitle': 'View Transactions',
          'icon': Icons.track_changes,
          'color': Colors.deepOrange,
        },
      ],
      {
        'title': AppLocalizations.of(context)!.menuSuggestProduct,
        'originalTitle': 'Suggest Product',
        'icon': Icons.recommend,
        'color': Colors.purple,
      },
      {
        'title': AppLocalizations.of(context)!.menuSuggestionsComplaints,
        'originalTitle': 'Suggestions/Complaints',
        'icon': Icons.lightbulb_outline,
        'color': Colors.teal,
      },
      {
        'title': AppLocalizations.of(context)!.menuBalanceHistory,
        'originalTitle': 'Balance History',
        'icon': Icons.account_balance_wallet,
        'color': Colors.amber[800]!,
      },
      if (isAdmin)
        {
          'title': AppLocalizations.of(context)!.menuManageUsers,
          'originalTitle': 'Manage Users',
          'icon': Icons.people,
          'color': Colors.blueGrey,
        },
    ];

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(), // Ensure it's always scrollable for refresh
        child: Column(
          children: [
            // News Line (Shortages Marquee)
            Container(
              height: 40,
              width: double.infinity,
              color: Colors.red[800] ?? Colors.red,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: Text(
                      AppLocalizations.of(context)!.urgentShortages,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: provider.isLoading && shortages.isEmpty
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            ),
                          )
                        : shortages.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context)!.noShortages,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: shortages.length,
                            itemBuilder: (context, index) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    '• ${shortages[index]} •',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            if (_searchQuery.isEmpty) ...[
              // Advertisement space
              Container(
                height: 120,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ), // Added margin to avoid overlap
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Menu Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                    if (isAdmin) {
                      final suggestionProvider =
                          Provider.of<AppSuggestionProvider>(context);
                      if (item['originalTitle'] == 'Suggest Product') {
                        badgeCount =
                            suggestionProvider.pendingProductSuggestionsCount;
                      } else if (item['originalTitle'] == 'View Transactions') {
                        badgeCount = suggestionProvider.pendingExcessCount;
                      } else if (item['originalTitle'] == 'Manage Users') {
                        badgeCount = suggestionProvider.waitingUsersCount;
                      }
                    }

                    return _buildMenuCard(
                      context,
                      item['title'] ?? 'Menu Item',
                      item['originalTitle'] ?? '',
                      item['icon'] ?? Icons.help,
                      item['color'] ?? Colors.blue,
                      badgeCount: badgeCount,
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String originalTitle,
    IconData icon,
    Color? color, {
    int badgeCount = 0,
  }) {
    final isAdmin =
        Provider.of<AuthProvider>(context, listen: false).userRole == 'admin';

    final effectiveColor = color ?? Colors.blue;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Use originalTitle for logic comparison to avoid localization issues in logic
          final logicTitle = originalTitle.isNotEmpty ? originalTitle : title;

          if (logicTitle == 'Add Excess') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddExcessScreen()),
            );
          } else if (logicTitle == 'Add Shortage') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddShortageScreen(),
              ),
            );
          } else if (logicTitle == 'Requests History') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RequestsHistoryScreen(),
              ),
            );
          } else if (logicTitle == 'Shopping Tour') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateOrderScreen(),
              ),
            );
          } else if (logicTitle == 'Start Transactions') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminMatchableProductsScreen(),
              ),
            );
          } else if (logicTitle == 'View Transactions') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FollowUpTransactionsScreen(),
              ),
            );
          } else if (logicTitle == 'Suggest Product') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SuggestProductScreen(),
              ),
            );
          } else if (logicTitle == 'Suggestions/Complaints') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => isAdmin
                    ? const AdminViewSuggestionsScreen()
                    : const SuggestionsComplaintsScreen(),
              ),
            );
          } else if (logicTitle == 'Manage Users') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminManageUsersScreen(),
              ),
            );
          } else if (logicTitle == 'Balance History') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BalanceHistoryScreen(),
              ),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Tapped on $title')));
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 32, color: effectiveColor),
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
