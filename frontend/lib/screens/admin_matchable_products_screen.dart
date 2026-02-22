import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import 'matching_detail_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/search_utils.dart';

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
    _fetchMatchable();
  }

  void _fetchMatchable() {
    Future.microtask(
      () => Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).fetchMatchableProducts(),
    );
  }

  void _onSearchChanged(String v) {
    setState(() => _searchQuery = v);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);

    final filteredProducts = _searchQuery.isEmpty
        ? transactionProvider.matchableProducts
        : transactionProvider.matchableProducts.where((item) {
            final productName = item['product']['name'].toString();
            return SearchUtils.matches(productName, _searchQuery);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.matchableProductsTitle),
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
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchProductsHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: transactionProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await transactionProvider.fetchMatchableProducts();
                    },
                    child: filteredProducts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.7,
                                child: Center(
                                  child: Text(
                                    _searchQuery.isEmpty
                                        ? AppLocalizations.of(
                                            context,
                                          )!.noMatchableItemsFound
                                        : AppLocalizations.of(
                                            context,
                                          )!.noMatchesFound,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
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
                                    color: hasFulfillment
                                        ? Colors.purple
                                        : Colors.blue,
                                    size: 40,
                                  ),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (hasFulfillment)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          margin: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.shortageFulfillment,
                                            style: const TextStyle(
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
                                    AppLocalizations.of(
                                      context,
                                    )!.matchingAvailableInVolumes(
                                      item['volumes'].length,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MatchingDetailScreen(
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
          ),
        ],
      ),
    );
  }
}
