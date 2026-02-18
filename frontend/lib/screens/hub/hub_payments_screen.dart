import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hub_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class HubPaymentsScreen extends StatefulWidget {
  const HubPaymentsScreen({super.key});

  @override
  State<HubPaymentsScreen> createState() => _HubPaymentsScreenState();
}

class _HubPaymentsScreenState extends State<HubPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<HubProvider>(context, listen: false).fetchOwnerPayments();
      Provider.of<HubProvider>(context, listen: false).fetchOwners();
    });
  }

  void _showPaymentDialog() {
    String? selectedOwnerId;
    final valueController = TextEditingController();
    final notesController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final hubProvider = Provider.of<HubProvider>(dialogContext);
          return AlertDialog(
            title: Text(AppLocalizations.of(dialogContext)!.makePayment),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedOwnerId,
                  items: hubProvider.owners.map((o) {
                    return DropdownMenuItem<String>(
                      value: o['_id'],
                      child: Text(o['name']),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedOwnerId = val),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      dialogContext,
                    )!.hubOwnersTitle,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(dialogContext)!.paymentValue,
                    helperText: "Positive: To Hub, Negative: From Hub",
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(dialogContext)!.notes,
                    hintText: "Optional notes",
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(dialogContext)!.cancel),
              ),
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        if (selectedOwnerId == null ||
                            valueController.text.isEmpty)
                          return;
                        final value = double.tryParse(valueController.text);
                        if (value == null) return;

                        setDialogState(() => isProcessing = true);

                        final success =
                            await Provider.of<HubProvider>(
                              dialogContext,
                              listen: false,
                            ).createOwnerPayment(
                              selectedOwnerId!,
                              value,
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                            );

                        if (success && mounted) {
                          Navigator.pop(dialogContext);
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
                    : Text(AppLocalizations.of(dialogContext)!.confirm),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.menuHubPayments),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Consumer<HubProvider>(
        builder: (context, hubProvider, _) {
          if (hubProvider.isLoading && hubProvider.ownerPayments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hubProvider.ownerPayments.isEmpty) {
            return Center(child: Text("No payments recorded yet"));
          }

          return ListView.builder(
            itemCount: hubProvider.ownerPayments.length,
            itemBuilder: (context, index) {
              final payment = hubProvider.ownerPayments[index];
              final value = payment['value'] ?? 0;
              final ownerName = payment['owner']?['name'] ?? 'Unknown';
              final date = DateTime.parse(payment['createdAt']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: value > 0
                        ? Colors.green[100]
                        : Colors.red[100],
                    child: Icon(
                      value > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                      color: value > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    ownerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal()),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${value > 0 ? "+" : ""}${NumberFormat("#,##0").format(value)}',
                        style: TextStyle(
                          color: value > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'edit') {
                            _showEditDialog(payment);
                          } else if (action == 'delete') {
                            _confirmDelete(payment);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: const Icon(Icons.edit),
                              title: Text("Edit"),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              title: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showPaymentDialog,
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add_card, color: Colors.white),
      ),
    );
  }

  void _showEditDialog(dynamic payment) {
    final valueController = TextEditingController(
      text: payment['value'].toString(),
    );
    final notesController = TextEditingController(text: payment['notes'] ?? '');
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Payment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valueController,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Payment Value",
                  helperText: "Positive: To Hub, Negative: From Hub",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Notes",
                  hintText: "Optional notes",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      final newValue = double.tryParse(valueController.text);
                      if (newValue == null) return;

                      setDialogState(() => isProcessing = true);

                      final success =
                          await Provider.of<HubProvider>(
                            context,
                            listen: false,
                          ).updateOwnerPayment(
                            payment['_id'],
                            newValue,
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          );

                      if (success && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Payment updated")),
                        );
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
                  : const Text("UPDATE"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(dynamic payment) {
    bool isProcessing = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Delete Payment"),
          content: isProcessing
              ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                )
              : const Text(
                  "Are you sure you want to delete this payment record? This will reverse the cash balance adjustment.",
                ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      setDialogState(() => isProcessing = true);
                      final success = await Provider.of<HubProvider>(
                        context,
                        listen: false,
                      ).deleteOwnerPayment(payment['_id']);

                      if (success && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Payment deleted")),
                        );
                      } else {
                        setDialogState(() => isProcessing = false);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("DELETE", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
