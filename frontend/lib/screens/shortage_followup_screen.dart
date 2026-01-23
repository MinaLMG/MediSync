import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shortage_provider.dart';

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
      appBar: AppBar(title: const Text('Follow-up Shortages')),
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
                      Text('Pharmacy: ${item['pharmacy']['name']}'),
                      Text('Volume: ${item['volume']['name']}'),
                      const SizedBox(height: 8),
                      Text('Quantity Needed: ${item['quantity']}'),

                      if (item['maxSurplus'] != null)
                        Text(
                          'Max Surplus: ${item['maxSurplus']} EGP',
                          style: const TextStyle(color: Colors.blue),
                        ),

                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              provider.deleteShortage(item['_id']);
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
