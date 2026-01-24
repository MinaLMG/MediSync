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

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue[900], // Slightly darker for Admin
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/medisync.png'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Notifications
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
    // Menu items for Admin
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
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
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
