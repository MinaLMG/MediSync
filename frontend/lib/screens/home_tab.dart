import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shortage_provider.dart';
import 'add_excess_screen.dart';
import 'add_shortage_screen.dart';
import 'orders_history_screen.dart';
import 'admin_matchable_products_screen.dart';
import 'follow_up_transactions_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ShortageProvider>(
        context,
        listen: false,
      ).fetchGlobalActiveShortages();
    });
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!mounted) return;
      final provider = Provider.of<ShortageProvider>(context, listen: false);
      if (provider.globalShortages.isNotEmpty) {
        if (_currentPage < provider.globalShortages.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        if (_pageController.hasClients) {
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
    final isAdmin = authProvider.userRole == 'admin';
    final shortages = Provider.of<ShortageProvider>(context).globalShortages;

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
      {'title': 'Search Product', 'icon': Icons.search, 'color': Colors.orange},
      {
        'title': 'Suggest Product',
        'icon': Icons.recommend,
        'color': Colors.purple,
      },
      {
        'title': 'Suggestions to Portal',
        'icon': Icons.lightbulb_outline,
        'color': Colors.teal,
      },
    ];

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
                  child: shortages.isEmpty
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
                              child: Text(
                                shortages[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search),
                  border: InputBorder.none,
                  hintText: 'Search for product',
                  suffixIcon: Icon(Icons.qr_code_scanner),
                ),
              ),
            ),
          ),

          // Advertisement space (Reduced height)
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
                return _buildMenuCard(
                  context,
                  menuItems[index]['title'],
                  menuItems[index]['icon'],
                  menuItems[index]['color'],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
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
              child: Icon(icon, size: 32, color: color),
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
