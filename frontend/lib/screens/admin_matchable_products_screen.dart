import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import 'matching_detail_screen.dart';

class AdminMatchableProductsScreen extends StatefulWidget {
  const AdminMatchableProductsScreen({super.key});

  @override
  State<AdminMatchableProductsScreen> createState() =>
      _AdminMatchableProductsScreenState();
}

class _AdminMatchableProductsScreenState
    extends State<AdminMatchableProductsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).fetchMatchableProducts(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matchable Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => transactionProvider.fetchMatchableProducts(),
          ),
        ],
      ),
      body: transactionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactionProvider.matchableProducts.isEmpty
          ? const Center(child: Text('No matchable items found at the moment.'))
          : ListView.builder(
              itemCount: transactionProvider.matchableProducts.length,
              itemBuilder: (context, index) {
                final item = transactionProvider.matchableProducts[index];
                final product = item['product'];
                final hasFulfillment = item['hasShortageFulfillment'] == true;

                return Card(
                  color: hasFulfillment ? Colors.purple[50] : Colors.white,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.medication,
                      color: hasFulfillment ? Colors.purple : Colors.blue,
                      size: 40,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (hasFulfillment)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Shortage Fulfillment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      'Matching available in ${item['volumes'].length} volumes',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchingDetailScreen(
                            productId: product['_id'],
                            productName: product['name'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
