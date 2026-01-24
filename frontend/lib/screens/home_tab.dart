import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shortage_provider.dart';
import '../providers/product_provider.dart';
import '../utils/search_utils.dart';
import 'add_excess_screen.dart';
import 'add_shortage_screen.dart';
import 'orders_history_screen.dart';
import 'admin_matchable_products_screen.dart';
import 'follow_up_transactions_screen.dart';
import 'suggest_product_screen.dart';
import 'suggestions_complaints_screen.dart';
import 'admin_view_suggestions_screen.dart';
import 'admin_manage_users_screen.dart';
import '../providers/app_suggestion_provider.dart';

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
    final productProvider = Provider.of<ProductProvider>(context);
    final isAdmin = authProvider.userRole == 'admin';
    final shortages = provider.globalShortages;

    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Orders History', 'icon': Icons.history, 'color': Colors.blue},
      {
        'title': 'Add Shortage',
        'icon': Icons.remove_circle_outline,
        'color': Colors.red,
      },
      {
        'title': 'Add Excess',
        'icon': Icons.add_circle_outline,
        'color': Colors.green,
      },
      if (isAdmin) ...[
        {
          'title': 'Start Transactions',
          'icon': Icons.swap_horiz,
          'color': Colors.indigo,
        },
        {
          'title': 'View Transactions',
          'icon': Icons.track_changes,
          'color': Colors.deepOrange,
        },
      ],
      {
        'title': 'Suggest Product',
        'icon': Icons.recommend,
        'color': Colors.purple,
      },
      {
        'title': 'Suggestions/Complaints',
        'icon': Icons.lightbulb_outline,
        'color': Colors.teal,
      },
      if (isAdmin)
        {
          'title': 'Manage Users',
          'icon': Icons.people,
          'color': Colors.blueGrey,
        },
    ];

    final filteredProducts = _searchQuery.isEmpty
        ? []
        : productProvider.products.where((p) {
            if (p is! Map) return false;
            return SearchUtils.matches(p['name']?.toString(), _searchQuery);
          }).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // News Line (Shortages Marquee)
          Container(
            height: 40,
            width: double.infinity,
            color: Colors.red[800],
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Text(
                    'URGENT SHORTAGES',
                    style: TextStyle(
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
                      ? const Center(
                          child: Text(
                            'No current shortages reported',
                            style: TextStyle(
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

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search),
                      border: InputBorder.none,
                      hintText: 'Search for product (* for wildcard)',
                      suffixIcon: Icon(Icons.qr_code_scanner),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: filteredProducts.isEmpty
                        ? const ListTile(title: Text('No matches found'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final p = filteredProducts[index];
                              return ListTile(
                                leading: const Icon(Icons.medication),
                                title: Text(p['name']),
                                subtitle: const Text('Tap to view details'),
                                onTap: () {
                                  // Clear search or navigate
                                  setState(() => _searchQuery = '');
                                  FocusScope.of(context).unfocus();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
          ),

          if (_searchQuery.isEmpty) ...[
            // Advertisement space
            Container(
              height: 120,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
              child: const Center(
                child: Text(
                  'Advertisement Space\n(Promotions & Offers)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                    if (item['title'] == 'Suggest Product') {
                      badgeCount =
                          suggestionProvider.pendingProductSuggestionsCount;
                    } else if (item['title'] == 'View Transactions') {
                      badgeCount = suggestionProvider.pendingExcessCount;
                    } else if (item['title'] == 'Manage Users') {
                      badgeCount = suggestionProvider.waitingUsersCount;
                    }
                  }

                  return _buildMenuCard(
                    context,
                    item['title'],
                    item['icon'],
                    item['color'],
                    badgeCount: badgeCount,
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
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
    final isAdmin =
        Provider.of<AuthProvider>(context, listen: false).userRole == 'admin';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (title == 'Add Excess') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddExcessScreen()),
            );
          } else if (title == 'Add Shortage') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddShortageScreen(),
              ),
            );
          } else if (title == 'Orders History') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrdersHistoryScreen(),
              ),
            );
          } else if (title == 'Start Transactions') {
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
          } else if (title == 'Suggest Product') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SuggestProductScreen(),
              ),
            );
          } else if (title == 'Suggestions/Complaints') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => isAdmin
                    ? const AdminViewSuggestionsScreen()
                    : const SuggestionsComplaintsScreen(),
              ),
            );
          } else if (title == 'Manage Users') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminManageUsersScreen(),
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
