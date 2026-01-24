import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../utils/search_utils.dart';

class ManageSuggestionsScreen extends StatefulWidget {
  const ManageSuggestionsScreen({super.key});

  @override
  State<ManageSuggestionsScreen> createState() =>
      _ManageSuggestionsScreenState();
}

class _ManageSuggestionsScreenState extends State<ManageSuggestionsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<ProductProvider>(
        context,
        listen: false,
      ).fetchSuggestions(),
    );
  }

  void _handleStatus(String id, String status) async {
    final notesController = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${status[0].toUpperCase()}${status.substring(1)} Suggestion',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to $status this suggestion?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (Optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
            ),
            child: Text(status.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Provider.of<ProductProvider>(
        context,
        listen: false,
      ).updateSuggestionStatus(id, status, notes: notesController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);

    final filteredSuggestions = provider.suggestions.where((s) {
      return SearchUtils.matches(s['name'], _searchQuery) ||
          SearchUtils.matches(s['suggestedBy']['name'], _searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('New Product Suggestions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search suggestions (* for wildcard)...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: provider.isLoading && provider.suggestions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredSuggestions.isEmpty
                ? const Center(child: Text('No suggestions found.'))
                : ListView.builder(
                    itemCount: filteredSuggestions.length,
                    itemBuilder: (context, index) {
                      final s = filteredSuggestions[index];
                      final isPending = s['status'] == 'pending';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    s['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  _StatusBadge(status: s['status']),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'Proposed Price',
                                value: '${s['price']} EGP',
                              ),
                              const Divider(),
                              _InfoRow(
                                label: 'Suggested By',
                                value: s['suggestedBy']['name'],
                              ),
                              if (s['adminNotes'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Admin Notes: ${s['adminNotes']}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                              if (isPending) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _handleStatus(s['_id'], 'rejected'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('REJECT'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _handleStatus(s['_id'], 'approved'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'APPROVE & CREATE',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
