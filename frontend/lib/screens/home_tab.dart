import 'package:flutter/material.dart';
import 'add_excess_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
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

          // Advertisement Placeholder
          Container(
            height: 150,
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
                  fontSize: 18,
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
                childAspectRatio: 1.0, // Reduced from 1.2 to give more height
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
