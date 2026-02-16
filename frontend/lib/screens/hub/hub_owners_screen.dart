import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hub_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class HubOwnersScreen extends StatefulWidget {
  const HubOwnersScreen({super.key});

  @override
  State<HubOwnersScreen> createState() => _HubOwnersScreenState();
}

class _HubOwnersScreenState extends State<HubOwnersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<HubProvider>(context, listen: false).fetchOwners();
    });
  }

  void _showOwnerDialog({Map<String, dynamic>? owner}) {
    final nameController = TextEditingController(text: owner?['name'] ?? '');
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            owner == null
                ? AppLocalizations.of(context)!.addOwner
                : AppLocalizations.of(context)!.editOwner,
          ),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.ownerName,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (nameController.text.isEmpty) return;

                      setDialogState(() => isProcessing = true);

                      final hubProvider = Provider.of<HubProvider>(
                        context,
                        listen: false,
                      );
                      bool success;
                      if (owner == null) {
                        success = await hubProvider.createOwner(
                          nameController.text,
                        );
                      } else {
                        success = await hubProvider.updateOwner(
                          owner['_id'],
                          nameController.text,
                        );
                      }
                      if (success && mounted) {
                        Navigator.pop(context);
                      } else {
                        setDialogState(() => isProcessing = false);
                      }
                    },
              child: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.hubOwnersTitle),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Consumer<HubProvider>(
        builder: (context, hubProvider, _) {
          if (hubProvider.isLoading && hubProvider.owners.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hubProvider.owners.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noOwnersFound ??
                    'No owners found',
              ),
            );
          }

          return ListView.builder(
            itemCount: hubProvider.owners.length,
            itemBuilder: (context, index) {
              final owner = hubProvider.owners[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    owner['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${AppLocalizations.of(context)!.balance}: ${NumberFormat("#,##0").format(owner['balance'])}',
                    style: TextStyle(
                      color: owner['balance'] >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showOwnerDialog(owner: owner),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOwnerDialog(),
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
