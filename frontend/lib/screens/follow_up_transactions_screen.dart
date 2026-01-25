import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';

class FollowUpTransactionsScreen extends StatefulWidget {
  final String? initialStatus;

  const FollowUpTransactionsScreen({super.key, this.initialStatus});

  @override
  State<FollowUpTransactionsScreen> createState() =>
      _FollowUpTransactionsScreenState();
}

class _FollowUpTransactionsScreenState
    extends State<FollowUpTransactionsScreen> {
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialStatus;
    Future.microtask(
      () => Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).fetchTransactions(status: selectedStatus),
    );
  }

  void _updateStatus(String id, String newStatus) async {
    final success = await Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).updateTransactionStatus(id, newStatus);
    if (mounted && success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      // Refresh with current filter
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).fetchTransactions(status: selectedStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Follow-up Transactions')),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: tp.isLoading
                ? const Center(child: CircularProgressIndicator())
                : tp.transactions.isEmpty
                ? const Center(child: Text('No transactions found.'))
                : ListView.builder(
                    itemCount: tp.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = tp.transactions[index];
                      return _buildTransactionCard(tx);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip(null, 'All'),
          _filterChip('pending', 'Pending'),
          _filterChip('accepted', 'Accepted'),
          _filterChip('completed', 'Completed'),
          _filterChip('cancelled', 'Cancelled'),
          _filterChip('rejected', 'Rejected'),
        ],
      ),
    );
  }

  Widget _filterChip(String? status, String label) {
    final isSelected = selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          setState(() => selectedStatus = status);
          Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).fetchTransactions(status: status);
        },
      ),
    );
  }

  Widget _buildTransactionCard(dynamic tx) {
    final shortage = tx['stockShortage']['shortage'];
    final product = shortage['product']['name'];
    final buyer = shortage['pharmacy']['name'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tx['serial'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Text(
                          '#${tx['serial']}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    Text(
                      product,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                _statusBadge(tx['status']),
              ],
            ),
            const SizedBox(height: 8),
            Text('Buyer: $buyer', style: const TextStyle(color: Colors.blue)),
            Text('Total Qty: ${tx['totalQuantity']}'),
            Text('Total Value: ${tx['totalAmount']} EGP'),
            if (tx['delivery'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.delivery_dining,
                    size: 14,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Delivery: ${tx['delivery']['name']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(),
            const Text(
              'Sellers:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            ...(tx['stockExcessSources'] as List).map(
              (s) => Text(
                '- ${s['stockExcess']['pharmacy']['name']} (${s['quantity']} units)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            if (tx['status'] != 'completed' && tx['status'] != 'cancelled')
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (tx['status'] == 'pending')
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Accept'),
                                content: const Text(
                                  'Are you sure you want to accept this transaction?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _updateStatus(tx['_id'], 'accepted');
                                    },
                                    child: const Text('Yes, Accept'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Accept'),
                        ),
                      if (tx['status'] == 'accepted')
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Complete'),
                                content: const Text(
                                  'Are you sure you want to mark this transaction as completed?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _updateStatus(tx['_id'], 'completed');
                                    },
                                    child: const Text('Yes, Complete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Complete'),
                        ),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Cancel'),
                              content: const Text(
                                'Are you sure you want to cancel this transaction? All quantities will be returned to their respective pharmacies.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _updateStatus(tx['_id'], 'cancelled');
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Yes, Cancel'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                  if (Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).userRole ==
                          'admin' &&
                      tx['delivery'] != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Detach Delivery'),
                              content: const Text(
                                'This will remove the assigned delivery person. The transaction will become available for assignment again.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Close'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final success =
                                        await Provider.of<TransactionProvider>(
                                          context,
                                          listen: false,
                                        ).unassignTransaction(tx['_id']);
                                    if (mounted && success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Delivery person detached',
                                          ),
                                        ),
                                      );
                                      // Refresh with current filter
                                      Provider.of<TransactionProvider>(
                                        context,
                                        listen: false,
                                      ).fetchTransactions(
                                        status: selectedStatus,
                                      );
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                  ),
                                  child: const Text('Detach'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_remove, size: 16),
                        label: const Text('Detach Delivery'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
            Text(
              'Created: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(tx['createdAt']))}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            if (tx['status'] == 'completed' &&
                Provider.of<AuthProvider>(context, listen: false).userRole ==
                    'admin' &&
                (tx['reversalTicket'] == null ||
                    (tx['reversalTicket'] is Map &&
                        tx['reversalTicket']['revertedAt'] == null)))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showRevertDialog(tx),
                  icon: const Icon(
                    Icons.settings_backup_restore,
                    color: Colors.red,
                    size: 16,
                  ),
                  label: const Text(
                    'Revert Transaction',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
            if (tx['status'] == 'cancelled' &&
                tx['reversalTicket'] != null &&
                Provider.of<AuthProvider>(context, listen: false).userRole ==
                    'admin')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showEditTicketDialog(tx),
                  icon: const Icon(
                    Icons.receipt_long,
                    size: 16,
                    color: Colors.blue,
                  ),
                  label: const Text(
                    'View/Edit Ticket',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditTicketDialog(dynamic tx) {
    // We assume tx has the reversalTicket object populated or we might need to fetch it.
    // If population is not deep enough, we might only have ID.
    // For now, let's assume if it's not null, it's populated.
    // If it's just ID, we would need to fetch it, but let's try to use what we have.
    final ticket = tx['reversalTicket'];

    // Check if ticket is just an ID string
    if (ticket is String) {
      // We can't edit it easily without fetching. show error or simple dialog.
      // Ideally backend population handles this.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ticket details not loaded. Refresh or implementation needed.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _ReversalPunishmentDialog(
        tx: tx,
        initialPunishments:
            (ticket['punishments'] as List?)
                ?.map(
                  (p) => {
                    'userId':
                        p['user']?['_id'] ??
                        p['pharmacy']?['_id'], // Prefer User ID, fallback to Pharmacy ID for matching
                    // We need a display name. If user is populated, use name. If pharmacy, use pharmacy name.
                    // This might be tricky if population is partial.
                    'pharmacyName':
                        'Existing Punishment', // Placeholder, hard to reconstruct name without deep population
                    'amount': (p['amount'] as num).toDouble(),
                  },
                )
                .toList() ??
            [],
        initialDescription: ticket['description'],
        isEditing: true, // New flag to handle update mode
        onConfirm: (punishments, description) async {
          final updateData = {
            'punishments': punishments,
            'description': description,
          };

          final success = await Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).updateReversalTicket(ticket['_id'], updateData);

          if (mounted) {
            Navigator.pop(ctx);
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ticket updated successfully')),
              );
              Provider.of<TransactionProvider>(
                context,
                listen: false,
              ).fetchTransactions(status: selectedStatus);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error: ${Provider.of<TransactionProvider>(context, listen: false).errorMessage}',
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showRevertDialog(dynamic tx) {
    showDialog(
      context: context,
      builder: (ctx) => _ReversalPunishmentDialog(
        tx: tx,
        onConfirm: (punishments, description) async {
          final ticket = {
            'punishments': punishments,
            'description': description,
          };

          final success = await Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).revertTransaction(tx['_id'], ticket);

          if (mounted) {
            Navigator.pop(ctx);
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction successfully reverted'),
                ),
              );
              Provider.of<TransactionProvider>(
                context,
                listen: false,
              ).fetchTransactions(status: selectedStatus);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error: ${Provider.of<TransactionProvider>(context, listen: false).errorMessage}',
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'accepted':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
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

class _ReversalPunishmentDialog extends StatefulWidget {
  final dynamic tx;
  final Function(List<Map<String, dynamic>>, String) onConfirm;
  final List<Map<String, dynamic>>? initialPunishments;
  final String? initialDescription;
  final bool isEditing;

  const _ReversalPunishmentDialog({
    required this.tx,
    required this.onConfirm,
    this.initialPunishments,
    this.initialDescription,
    this.isEditing = false,
  });

  @override
  State<_ReversalPunishmentDialog> createState() =>
      _ReversalPunishmentDialogState();
}

class _ReversalPunishmentDialogState extends State<_ReversalPunishmentDialog> {
  final List<Map<String, dynamic>> _punishments = [];
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPunishments != null) {
      _punishments.addAll(widget.initialPunishments!);
    }
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortage = widget.tx['stockShortage'];
    final buyerPh = shortage['shortage']['pharmacy'];
    final sources = widget.tx['stockExcessSources'] as List;

    return AlertDialog(
      title: Text(
        widget.isEditing
            ? 'Edit Reversal Ticket'
            : 'Revert Transaction & Punishment',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isEditing) ...[
              const Text(
                'AUTOMATIC REVERSAL SUMMARY:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                'Buyer: ${buyerPh['name']} (Refunded: ${-(shortage['balanceEffect'] ?? 0)} EGP)',
                style: const TextStyle(fontSize: 12),
              ),
              ...sources.map(
                (s) => Text(
                  'Seller: ${s['stockExcess']['pharmacy']['name']} (Deducted: ${s['balanceEffect'] ?? 0} EGP)',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const Divider(),
            ],
            const Text(
              'INVOLVED PARTIES (Select to Punish):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            _buildPartyItem(buyerPh, 'Buyer', buyerPh['_id']),
            ...sources.map(
              (s) => _buildPartyItem(
                s['stockExcess']['pharmacy'],
                'Seller',
                s['stockExcess']['pharmacy']['_id'],
              ),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description / Reason',
                labelStyle: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () =>
              widget.onConfirm(_punishments, _descriptionController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isEditing ? Colors.blue : Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.isEditing ? 'Update Ticket' : 'Confirm Reversion'),
        ),
      ],
    );
  }

  Widget _buildPartyItem(dynamic pharmacy, String role, String pharmacyId) {
    final existingIndex = _punishments.indexWhere(
      (p) => p['userId'] == pharmacyId,
    );
    final isPunished = existingIndex != -1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: isPunished ? Colors.red[50] : Colors.white,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pharmacy['name']} ($role)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      pharmacy['phone'] ?? 'No phone',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (!isPunished)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _punishments.add({
                        'pharmacyName': pharmacy['name'],
                        'userId': pharmacyId,
                        'amount': 0.0,
                      });
                    });
                  },
                  icon: const Icon(Icons.gavel, size: 16, color: Colors.red),
                  label: const Text(
                    'Punish',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () {
                    setState(() {
                      _punishments.removeAt(existingIndex);
                    });
                  },
                ),
            ],
          ),
          if (isPunished)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Text(
                    'Amount (EGP): ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller:
                          TextEditingController(
                              text: _punishments[existingIndex]['amount']
                                  .toString(),
                            )
                            ..selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: _punishments[existingIndex]['amount']
                                    .toString()
                                    .length,
                              ),
                            ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        _punishments[existingIndex]['amount'] =
                            double.tryParse(val) ?? 0.0;
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
