import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/excess_provider.dart';

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
    _tabController = TabController(length: 2, vsync: this);
    // Fetch data
    Future.microtask(() {
      final provider = Provider.of<ExcessProvider>(context, listen: false);
      provider.fetchPendingExcesses();
      provider.fetchAvailableExcesses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-up Excesses'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending (Not Accepted)'),
            Tab(text: 'Available (Accepted)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPendingList(), _buildAvailableList()],
      ),
    );
  }

  Widget _buildPendingList() {
    return Consumer<ExcessProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.pendingExcesses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.pendingExcesses.isEmpty) {
          return const Center(child: Text('No pending excesses'));
        }

        return ListView.builder(
          itemCount: provider.pendingExcesses.length,
          itemBuilder: (context, index) {
            final item = provider.pendingExcesses[index];
            // Highlighting Logic
            final expiryDate = DateTime.parse(item['expiryDate']);
            final isNearExpiry =
                expiryDate.difference(DateTime.now()).inDays <
                180; // < 6 months
            final isNewPrice = item['isNewPrice'] == true;

            Color cardColor = Colors.white;
            if (isNewPrice) cardColor = Colors.blue[50]!; // New Price Highlight

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
                    Text('${item['pharmacy']['name']}'),
                    const SizedBox(height: 8),

                    if (isNewPrice)
                      Container(
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
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),

                    // Always show percentage if available
                    if (item['salePercentage'] != null)
                      Text(
                        '${item['salePercentage'].toStringAsFixed(1)}% Off',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    Text('Price: ${item['selectedPrice']} EGP'),
                    Text('Quantity: ${item['originalQuantity']}'),

                    Text(
                      'Expiry: ${DateFormat('yyyy-MM-dd').format(expiryDate)}',
                      style: TextStyle(
                        color: isNearExpiry ? Colors.red : Colors.black,
                        fontWeight: isNearExpiry
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),

                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            provider.deleteExcess(item['_id']);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            provider.approveExcess(item['_id']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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
          return const Center(child: Text('No available excesses'));
        }

        return ListView.builder(
          itemCount: provider.availableExcesses.length,
          itemBuilder: (context, index) {
            final item = provider.availableExcesses[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(item['product']['name'] ?? 'Unknown'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pharmacy: ${item['pharmacy']['name']}'),
                    Text('Price: ${item['selectedPrice']} EGP'),
                    if (item['salePercentage'] != null)
                      Text(
                        'Discount: ${item['salePercentage'].toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      'Remaining: ${item['remainingQuantity']}/${item['originalQuantity']}',
                    ),
                  ],
                ),
                trailing: Chip(
                  label: const Text('Available'),
                  backgroundColor: Colors.green[100],
                  avatar: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 18,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
