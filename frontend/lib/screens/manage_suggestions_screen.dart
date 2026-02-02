import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../utils/search_utils.dart';
import '../l10n/generated/app_localizations.dart';

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
    final provider = Provider.of<ProductProvider>(context, listen: false);

    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.titleSuggestionAction(
            '${status[0].toUpperCase()}${status.substring(1)}',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.msgConfirmSuggestionAction(status)),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: l10n.labelReviewerNotesOptional,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
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
      await provider.updateSuggestionStatus(
        id,
        status,
        notes: notesController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<ProductProvider>(context);

    final filteredSuggestions = provider.suggestions.where((s) {
      return SearchUtils.matches(s['name'], _searchQuery) ||
          SearchUtils.matches(s['suggestedBy']['name'] ?? '', _searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleProductSuggestions)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.hintSearchSuggestions,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: provider.isLoading && provider.suggestions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredSuggestions.isEmpty
                ? Center(child: Text(l10n.msgNoSuggestionsFound))
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
                                label: l10n.labelProposedPrice,
                                value: '${s['price']} ${l10n.labelCoins}',
                              ),
                              const Divider(),
                              _InfoRow(
                                label: l10n.labelSuggestedBy,
                                value: s['suggestedBy']['name'] ?? 'Unknown',
                              ),
                              if (s['adminNotes'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  l10n.labelReviewerNotes(s['adminNotes']),
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
                                        onPressed: provider.isLoading
                                            ? null
                                            : () => _handleStatus(
                                                s['_id'],
                                                'rejected',
                                              ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: Text(
                                          l10n.actionReject.toUpperCase(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: provider.isLoading
                                            ? null
                                            : () => _handleStatus(
                                                s['_id'],
                                                'approved',
                                              ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: provider.isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Center(
                                                child: Text(
                                                  l10n.actionApprove
                                                      .toUpperCase(),
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
    Color color = Colors.orange;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'pending':
        color = Colors.orange;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
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
