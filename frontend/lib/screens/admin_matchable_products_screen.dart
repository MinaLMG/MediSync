import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/search_utils.dart';
import 'matching_detail_screen.dart';

class AdminMatchableProductsScreen extends StatefulWidget {
  const AdminMatchableProductsScreen({super.key});

  @override
  State<AdminMatchableProductsScreen> createState() =>
      _AdminMatchableProductsScreenState();
}

class _AdminMatchableProductsScreenState
    extends State<AdminMatchableProductsScreen> {
  String _searchQuery = '';

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

    final filteredProducts = transactionProvider.matchableProducts.where((
      item,
    ) {
      final product = item['product'];
      return SearchUtils.matches(product['name'], _searchQuery);
    }).toList();

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products (* for wildcard)...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: transactionProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No matchable items found.'
                          : 'No matches found.',
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final item = filteredProducts[index];
                      final product = item['product'];
                      final hasFulfillment =
                          item['hasShortageFulfillment'] == true;

                      return Card(
                        color: hasFulfillment
                            ? Colors.purple[50]
                            : Colors.white,
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
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasFulfillment)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 4),
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
                              Text(
                                product['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
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
          ),
        ],
      ),
    );
  }
}
