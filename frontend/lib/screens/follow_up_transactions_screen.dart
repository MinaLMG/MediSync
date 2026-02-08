import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../utils/ui_utils.dart';
import '../providers/auth_provider.dart';
import 'admin_edit_transaction_screen.dart';
import '../l10n/generated/app_localizations.dart';

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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.labelRefundStatus(newStatus))),
      );
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleFollowUpTransactions),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<TransactionProvider>(
                context,
                listen: false,
              ).fetchTransactions(status: selectedStatus);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: tp.isLoading && tp.transactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await tp.fetchTransactions(status: selectedStatus);
                    },
                    child: tp.transactions.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.7,
                                child: Center(child: Text(l10n.msgNoData)),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: tp.transactions.length,
                            itemBuilder: (context, index) {
                              final tx = tp.transactions[index];
                              return _buildTransactionCard(tx);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip(null, l10n.labelAll),
          _filterChip('pending', l10n.statusPending),
          _filterChip('accepted', l10n.statusActive),
          _filterChip('completed', l10n.statusFulfilled),
          _filterChip('cancelled', l10n.statusCancelled),
          _filterChip('rejected', l10n.statusRejected),
        ],
      ),
    );
  }

  bool _isShortageFulfillment(Map<String, dynamic> tx) {
    if (tx['stockExcessSources'] != null && tx['stockExcessSources'] is List) {
      for (var source in tx['stockExcessSources']) {
        if (source['stockExcess'] != null &&
            source['stockExcess']['shortage_fulfillment'] == true) {
          return true;
        }
      }
    }
    return false;
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
    final tp = Provider.of<TransactionProvider>(context);
    final shortage = tx['stockShortage']['shortage'];
    final product = shortage['product']['name'];
    final buyer = shortage['pharmacy']['name'];
    final l10n = AppLocalizations.of(context)!;

    final isOrder = tx['stockShortage']?['shortage']?['order'] != null;
    final orderSerial = isOrder
        ? tx['stockShortage']['shortage']['order']['serial']
        : null;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = auth.userRole == 'admin';

    return Card(
      color: isOrder ? Colors.blue[100] : null,
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
                    if (orderSerial != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.withAlpha(76)),
                        ),
                        child: Text(
                          l10n.labelOrderPrefix + orderSerial,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
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
            InkWell(
              onTap: () => UIUtils.showPharmacyInfo(
                context,
                tx['stockShortage']['shortage']['pharmacy'],
              ),
              child: Text(
                l10n.labelBuyer(buyer),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(l10n.labelTotalQty(tx['totalQuantity'])),
            Text(l10n.labelTotalValue(tx['totalAmount'].toString())),
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
                    l10n.labelDelivery(tx['delivery']['name']),
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
            Text(
              l10n.labelSellers,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            ...(tx['stockExcessSources'] as List).map(
              (s) => InkWell(
                onTap: () => UIUtils.showPharmacyInfo(
                  context,
                  s['stockExcess']['pharmacy'],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '- ${s['stockExcess']['pharmacy']['name']} (${s['quantity']} ${l10n.labelUnitsShort})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (tx['status'] != 'completed' && tx['status'] != 'cancelled')
              Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    children: [
                      if (tx['status'] == 'pending')
                        TextButton(
                          onPressed: tp.isLoading
                              ? null
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(l10n.dialogConfirmAccept),
                                      content: Text(
                                        l10n.msgConfirmAcceptTransaction,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: tp.isLoading
                                              ? null
                                              : () => Navigator.pop(ctx),
                                          child: Text(l10n.actionNo),
                                        ),
                                        TextButton(
                                          onPressed: tp.isLoading
                                              ? null
                                              : () {
                                                  Navigator.pop(ctx);
                                                  _updateStatus(
                                                    tx['_id'],
                                                    'accepted',
                                                  );
                                                },
                                          child: tp.isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : Text(l10n.actionYesAccept),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                          child: const Text('Accept'),
                        ),
                      if (tx['status'] == 'accepted')
                        TextButton(
                          onPressed: tp.isLoading
                              ? null
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(l10n.dialogConfirmComplete),
                                      content: Text(
                                        l10n.msgConfirmCompleteTransaction,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: tp.isLoading
                                              ? null
                                              : () => Navigator.pop(ctx),
                                          child: Text(l10n.actionNo),
                                        ),
                                        TextButton(
                                          onPressed: tp.isLoading
                                              ? null
                                              : () {
                                                  Navigator.pop(ctx);
                                                  _updateStatus(
                                                    tx['_id'],
                                                    'completed',
                                                  );
                                                },
                                          child: tp.isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : Text(l10n.actionYesComplete),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                          child: const Text('Complete'),
                        ),
                      TextButton(
                        onPressed: tp.isLoading
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(l10n.dialogConfirmCancel),
                                    content: Text(
                                      l10n.msgConfirmCancelTransaction,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: tp.isLoading
                                            ? null
                                            : () => Navigator.pop(ctx),
                                        child: Text(l10n.actionNo),
                                      ),
                                      TextButton(
                                        onPressed: tp.isLoading
                                            ? null
                                            : () {
                                                Navigator.pop(ctx);
                                                _updateStatus(
                                                  tx['_id'],
                                                  'cancelled',
                                                );
                                              },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: tp.isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.red,
                                                    ),
                                              )
                                            : Text(l10n.actionYesCancel),
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
                      TextButton.icon(
                        onPressed: tp.isLoading
                            ? null
                            : () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) =>
                                        AdminEditTransactionScreen(
                                          transaction: tx,
                                        ),
                                  ),
                                );
                                if (result == true) {
                                  tp.fetchTransactions(status: selectedStatus);
                                }
                              },
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(
                          l10n.labelEdit,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      if (isAdmin &&
                          tx['status'] != 'completed' &&
                          tx['status'] != 'cancelled' &&
                          _isShortageFulfillment(tx))
                        TextButton.icon(
                          onPressed: tp.isLoading
                              ? null
                              : () => _showEditRatiosDialog(tx),
                          icon: const Icon(Icons.percent, size: 16),
                          label: Text(
                            l10n.labelEditRatios,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  if (isAdmin && tx['delivery'] != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: tp.isLoading
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(l10n.dialogDetachDelivery),
                                    content: Text(l10n.msgDetachDelivery),
                                    actions: [
                                      TextButton(
                                        onPressed: tp.isLoading
                                            ? null
                                            : () => Navigator.pop(ctx),
                                        child: Text(l10n.actionClose),
                                      ),
                                      TextButton(
                                        onPressed: tp.isLoading
                                            ? null
                                            : () async {
                                                Navigator.pop(ctx);
                                                final success = await tp
                                                    .unassignTransaction(
                                                      tx['_id'],
                                                    );
                                                if (mounted && success) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        l10n.msgDeliveryDetached,
                                                      ),
                                                    ),
                                                  );
                                                  // Refresh with current filter
                                                  tp.fetchTransactions(
                                                    status: selectedStatus,
                                                  );
                                                }
                                              },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.orange,
                                        ),
                                        child: tp.isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.orange,
                                                    ),
                                              )
                                            : Text(l10n.actionDetach),
                                      ),
                                    ],
                                  ),
                                );
                              },
                        icon: const Icon(Icons.person_remove, size: 16),
                        label: Text(l10n.dialogDetachDelivery),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
            Text(
              l10n.labelCreated(
                DateFormat(
                  'yyyy-MM-dd HH:mm',
                  Localizations.localeOf(context).languageCode,
                ).format(DateTime.parse(tx['createdAt'])),
              ),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            if (tx['status'] == 'completed' &&
                isAdmin &&
                (tx['reversalTicket'] == null ||
                    (tx['reversalTicket'] is Map &&
                        tx['reversalTicket']['revertedAt'] == null)))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: tp.isLoading ? null : () => _showRevertDialog(tx),
                  icon: const Icon(
                    Icons.settings_backup_restore,
                    color: Colors.red,
                    size: 16,
                  ),
                  label: Text(
                    l10n.actionRevertTransaction,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
            if (tx['status'] == 'cancelled' &&
                tx['reversalTicket'] != null &&
                isAdmin)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: tp.isLoading
                      ? null
                      : () => _showEditTicketDialog(tx),
                  icon: const Icon(
                    Icons.receipt_long,
                    size: 16,
                    color: Colors.blue,
                  ),
                  label: Text(
                    l10n.actionViewEditTicket,
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditTicketDialog(dynamic tx) {
    final ticket = tx['reversalTicket'];

    if (ticket is String) {
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
      builder: (ctx) => _ReversalExpensesDialog(
        tx: tx,
        initialExpenses:
            (ticket['expenses'] as List?)
                ?.map(
                  (p) => {
                    'userId': p['user']?['_id'] ?? p['pharmacy']?['_id'],
                    'pharmacyName': 'Existing Expense',
                    'amount': (p['amount'] as num).toDouble(),
                  },
                )
                .toList() ??
            [],
        initialDescription: ticket['description'],
        isEditing: true,
        onConfirm: (expenses, description) async {
          final updateData = {'expenses': expenses, 'description': description};

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
      builder: (ctx) => _ReversalExpensesDialog(
        tx: tx,
        onConfirm: (expenses, description) async {
          final ticket = {'expenses': expenses, 'description': description};

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
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        (Localizations.localeOf(context).languageCode == 'ar'
                ? UIUtils.translateStatus(status)
                : status)
            .toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showEditRatiosDialog(dynamic tx) {
    final l10n = AppLocalizations.of(context)!;
    // commissionRatio is 0-1 range in backend, so multiply by 100 for percentage
    final double buyerComm = (tx['buyerCommissionRatio'] ?? 0.0) * 100;
    final double sellerRew = (tx['sellerBonusRatio'] ?? 0.0) * 100;

    final buyerCommController = TextEditingController(
      text: buyerComm.toStringAsFixed(1),
    );
    final sellerRewController = TextEditingController(
      text: sellerRew.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.labelEditRatios),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: buyerCommController,
              decoration: InputDecoration(
                labelText: l10n.labelBuyerCommPercentage,
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: sellerRewController,
              decoration: InputDecoration(
                labelText: l10n.labelSellerRewardPercentage,
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: Provider.of<TransactionProvider>(context).isLoading
                ? null
                : () async {
                    final data = {
                      'commissionRatio': null,
                      'buyerCommissionRatio': double.tryParse(
                        buyerCommController.text,
                      ),
                      'sellerBonusRatio': double.tryParse(
                        sellerRewController.text,
                      ),
                    };
                    Navigator.pop(ctx);
                    final success = await Provider.of<TransactionProvider>(
                      context,
                      listen: false,
                    ).updateTransactionRatios(tx['_id'], data);
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ratios updated')),
                      );
                      Provider.of<TransactionProvider>(
                        context,
                        listen: false,
                      ).fetchTransactions(status: selectedStatus);
                    }
                  },
            child: Provider.of<TransactionProvider>(context).isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.actionUpdateTicket),
          ),
        ],
      ),
    );
  }
}

class _ReversalExpensesDialog extends StatefulWidget {
  final dynamic tx;
  final Function(List<Map<String, dynamic>>, String) onConfirm;
  final List<Map<String, dynamic>>? initialExpenses;
  final String? initialDescription;
  final bool isEditing;

  const _ReversalExpensesDialog({
    required this.tx,
    required this.onConfirm,
    this.initialExpenses,
    this.initialDescription,
    this.isEditing = false,
  });

  @override
  State<_ReversalExpensesDialog> createState() =>
      _ReversalExpensesDialogState();
}

class _ReversalExpensesDialogState extends State<_ReversalExpensesDialog> {
  final List<Map<String, dynamic>> _expenses = [];
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialExpenses != null) {
      _expenses.addAll(widget.initialExpenses!);
    }
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shortage = widget.tx['stockShortage'];
    final buyerPh = shortage['shortage']['pharmacy'];
    final sources = widget.tx['stockExcessSources'] as List;

    return AlertDialog(
      title: Text(
        widget.isEditing
            ? l10n.titleEditReversalTicket
            : l10n.titleReversalExpenses,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isEditing) ...[
              Text(
                l10n.labelAutomaticReversalSummary,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.labelBuyer(buyerPh['name'])} (Refunded: ${-(shortage['balanceEffect'] ?? 0)} EGP)',
                style: const TextStyle(fontSize: 12),
              ),
              ...sources.map(
                (s) => Text(
                  '${l10n.labelSeller(s['stockExcess']['pharmacy']['name'])} (Deducted: ${s['balanceEffect'] ?? 0} EGP)',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const Divider(),
            ],
            Text(
              l10n.labelInvolvedParties,
              style: const TextStyle(
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
              decoration: InputDecoration(
                labelText: l10n.labelDescriptionReason,
                labelStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: Provider.of<TransactionProvider>(context).isLoading
              ? null
              : () => widget.onConfirm(_expenses, _descriptionController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isEditing ? Colors.blue : Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Provider.of<TransactionProvider>(context).isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.isEditing
                      ? l10n.actionUpdateTicket
                      : l10n.actionConfirmReversion,
                ),
        ),
      ],
    );
  }

  Widget _buildPartyItem(dynamic pharmacy, String role, String pharmacyId) {
    final l10n = AppLocalizations.of(context)!;
    final existingIndex = _expenses.indexWhere(
      (p) => p['userId'] == pharmacyId,
    );
    final isExpenseAdded = existingIndex != -1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: isExpenseAdded ? Colors.red[50] : Colors.white,
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
              if (!isExpenseAdded)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _expenses.add({
                        'pharmacyName': pharmacy['name'],
                        'userId': pharmacyId,
                        'amount': 0.0,
                      });
                    });
                  },
                  icon: const Icon(
                    Icons.money_off,
                    size: 16,
                    color: Colors.red,
                  ),
                  label: Text(
                    l10n.labelAddExpense,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () {
                    setState(() {
                      _expenses.removeAt(existingIndex);
                    });
                  },
                ),
            ],
          ),
          if (isExpenseAdded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text(
                    l10n.labelAmountEgp,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller:
                          TextEditingController(
                              text: _expenses[existingIndex]['amount']
                                  .toString(),
                            )
                            ..selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: _expenses[existingIndex]['amount']
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
                        _expenses[existingIndex]['amount'] =
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
