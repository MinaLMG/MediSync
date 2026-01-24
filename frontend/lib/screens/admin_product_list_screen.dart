import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

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
        builder: (context, setState) => AlertDialog(
          title: const Text('Manage Prices'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...currentPrices.asMap().entries.map(
                (entry) => ListTile(
                  title: Text('${entry.value} EGP'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final success =
                          await Provider.of<ProductProvider>(
                            context,
                            listen: false,
                          ).updateProductPrice(
                            hasVolumeId,
                            0,
                            false,
                            index: entry.key,
                          );
                      if (success) {
                        setState(() => currentPrices.removeAt(entry.key));
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
                          labelText: 'Store Price',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(
                            c,
                            double.tryParse(priceController.text),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  );

                  if (newPrice != null) {
                    final success = await Provider.of<ProductProvider>(
                      context,
                      listen: false,
                    ).updateProductPrice(hasVolumeId, newPrice, true);
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
        ),
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final nameController = TextEditingController(text: product['name']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () async {
              final success =
                  await Provider.of<ProductProvider>(
                    context,
                    listen: false,
                  ).updateProduct(product['_id'], {
                    'name': nameController.text.trim(),
                  });
              if (success && mounted) Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final filteredProducts = provider.products
        .where(
          (p) => p['name'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),
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
                          'Price: ${p['volumes'][0]['prices'].isEmpty ? "No prices set" : p['volumes'][0]['prices'].join(", ")} EGP',
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
