import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_suggestion_provider.dart';

class AdminViewSuggestionsScreen extends StatefulWidget {
  const AdminViewSuggestionsScreen({super.key});

  @override
  State<AdminViewSuggestionsScreen> createState() =>
      _AdminViewSuggestionsScreenState();
}

class _AdminViewSuggestionsScreenState
    extends State<AdminViewSuggestionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AppSuggestionProvider>(
        context,
        listen: false,
      ).fetchAllSuggestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback & Complaints')),
      body: Consumer<AppSuggestionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.suggestions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.suggestions.isEmpty) {
            return const Center(child: Text('No suggestions found.'));
          }

          return RefreshIndicator(
            onRefresh: provider.fetchAllSuggestions,
            child: ListView.builder(
              itemCount: provider.suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = provider.suggestions[index];
                final date = DateTime.parse(suggestion['createdAt']).toLocal();
                final bool isSeen = suggestion['seen'] ?? false;

                return Card(
                  color: isSeen ? Colors.white : Colors.blue[50],
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      suggestion['pharmacy']?['name'] ?? 'Unknown Pharmacy',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                        decoration: isSeen ? null : TextDecoration.none,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'User: ${suggestion['user']?['name'] ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: isSeen
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(
                            Icons.circle,
                            color: Colors.blue,
                            size: 12,
                          ),
                    onTap: () {
                      if (!isSeen) {
                        provider.markAsSeen(suggestion['_id']);
                      }
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Feedback Details'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'From: ${suggestion['pharmacy']?['name'] ?? 'Unknown'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'User: ${suggestion['user']?['name'] ?? 'Unknown'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  DateFormat('yyyy-MM-dd HH:mm').format(date),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Divider(),
                                Text(
                                  suggestion['content'] ??
                                      'No content provided',
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
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
