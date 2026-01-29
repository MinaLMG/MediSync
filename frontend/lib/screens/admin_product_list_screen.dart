import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../utils/search_utils.dart';

class AdminProductListScreen extends StatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          Provider.of<ProductProvider>(context, listen: false).fetchProducts(),
    );
  }

  void _showPriceDialog(String hasVolumeId, List<dynamic> currentPrices) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final provider = Provider.of<ProductProvider>(context);
          return AlertDialog(
            title: const Text('Manage Prices'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...currentPrices.asMap().entries.map(
                  (entry) => ListTile(
                    title: Text('${entry.value} coins'),
                    trailing: IconButton(
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete, color: Colors.red),
                      onPressed: provider.isLoading
                          ? null
                          : () async {
                              final success = await provider.updateProductPrice(
                                hasVolumeId,
                                0,
                                false,
                                index: entry.key,
                              );
                              if (success) {
                                setState(
                                  () => currentPrices.removeAt(entry.key),
                                );
                              }
                            },
                    ),
                  ),
                ),
                const Divider(),
                ElevatedButton.icon(
                  onPressed: () async {
                    final priceController = TextEditingController();
                    final double? newPrice = await showDialog<double>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Add Price'),
                        content: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Customer Price',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('Cancel'),
                          ),
                          StatefulBuilder(
                            builder: (context, setDialogState) {
                              final p = Provider.of<ProductProvider>(context);
                              return ElevatedButton(
                                onPressed: p.isLoading
                                    ? null
                                    : () => Navigator.pop(
                                        c,
                                        double.tryParse(priceController.text),
                                      ),
                                child: p.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Add'),
                              );
                            },
                          ),
                        ],
                      ),
                    );

                    if (newPrice != null) {
                      final success = await provider.updateProductPrice(
                        hasVolumeId,
                        newPrice,
                        true,
                      );
                      if (success) {
                        setState(() => currentPrices.add(newPrice));
                      }
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Price'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final nameController = TextEditingController(text: product['name']);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final provider = Provider.of<ProductProvider>(context);
          return AlertDialog(
            title: const Text('Edit Product Info'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        final success = await provider.updateProduct(
                          product['_id'],
                          {'name': nameController.text.trim()},
                        );
                        if (success && mounted) Navigator.pop(ctx);
                      },
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final filteredProducts = provider.products
        .where((p) => SearchUtils.matches(p['name'], searchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<ProductProvider>(
              context,
              listen: false,
            ).fetchProducts(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),
          Expanded(
            child: provider.isLoading && provider.products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.medication),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: p['status'] == 'active'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: p['status'] == 'active'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              child: Text(
                                (p['status'] ?? 'active').toUpperCase(),
                                style: TextStyle(
                                  color: p['status'] == 'active'
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: provider.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      p['status'] == 'active'
                                          ? Icons.block
                                          : Icons.check_circle_outline,
                                      size: 18,
                                      color: p['status'] == 'active'
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                              tooltip: p['status'] == 'active'
                                  ? 'Deactivate'
                                  : 'Activate',
                              onPressed: provider.isLoading
                                  ? null
                                  : () =>
                                        provider.toggleProductStatus(p['_id']),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.blue,
                              ),
                              onPressed: () => _showEditProductDialog(p),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Price: ${p['volumes'][0]['prices'].isEmpty ? "No prices set" : p['volumes'][0]['prices'].join(", ")} coins',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.blue),
                          onPressed: () => _showPriceDialog(
                            p['volumes'][0]['hasVolumeId'],
                            List.from(p['volumes'][0]['prices']),
                          ),
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
