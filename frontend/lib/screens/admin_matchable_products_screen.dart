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

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.medication,
                      color: Colors.blue,
                      size: 40,
                    ),
                    title: Text(
                      product['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
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
