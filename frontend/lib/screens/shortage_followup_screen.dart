import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shortage_provider.dart';
import '../utils/ui_utils.dart';

class ShortageFollowUpScreen extends StatefulWidget {
  const ShortageFollowUpScreen({super.key});

  @override
  State<ShortageFollowUpScreen> createState() => _ShortageFollowUpScreenState();
}

class _ShortageFollowUpScreenState extends State<ShortageFollowUpScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<ShortageProvider>(
        context,
        listen: false,
      ).fetchActiveShortages(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-up Shortages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<ShortageProvider>(
              context,
              listen: false,
            ).fetchActiveShortages(),
          ),
        ],
      ),
      body: Consumer<ShortageProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.activeShortages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.activeShortages.isEmpty) {
            return const Center(child: Text('No active shortages'));
          }

          return ListView.builder(
            itemCount: provider.activeShortages.length,
            itemBuilder: (context, index) {
              final item = provider.activeShortages[index];
              return Card(
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
                      InkWell(
                        onTap: () =>
                            UIUtils.showPharmacyInfo(context, item['pharmacy']),
                        child: Text(
                          'Pharmacy: ${item['pharmacy']['name']}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text('Volume: ${item['volume']['name']}'),
                      const SizedBox(height: 8),
                      Text('Quantity Needed: ${item['quantity']}'),
                      Text('Remaining Quantity: ${item['remainingQuantity']}'),

                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              final int total = item['quantity'] ?? 0;
                              final int remaining =
                                  item['remainingQuantity'] ?? 0;
                              if (total - remaining > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Cannot delete shortage that has already been partially fulfilled.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: const Text(
                                    'Are you sure you want to delete this shortage?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        provider.deleteShortage(item['_id']);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
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
      ),
    );
  }
}
