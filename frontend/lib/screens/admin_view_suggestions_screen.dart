import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_suggestion_provider.dart';
import '../l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleFeedbackComplaints),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<AppSuggestionProvider>(
              context,
              listen: false,
            ).fetchAllSuggestions(),
          ),
        ],
      ),
      body: Consumer<AppSuggestionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.suggestions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.suggestions.isEmpty) {
            return Center(child: Text(l10n.msgNoSuggestionsFound));
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
                      suggestion['pharmacy']?['name'] ??
                          l10n.labelUnknownPharmacy,
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
                          l10n.labelUserPrefix(
                            suggestion['user']?['name'] ?? l10n.statusUnknown,
                          ),
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
                          title: Text(l10n.titleFeedbackDetails),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.labelFromPrefix(
                                    suggestion['pharmacy']?['name'] ??
                                        l10n.labelUnknownPharmacy,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  l10n.labelUserPrefix(
                                    suggestion['user']?['name'] ??
                                        l10n.statusUnknown,
                                  ),
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
                                      l10n.msgNoContentProvided,
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.actionClose),
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
