import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../utils/config.dart';
import '../utils/search_utils.dart';
import 'admin_simulation_screen.dart';
import '../l10n/generated/app_localizations.dart';

class AdminPharmaciesScreen extends StatefulWidget {
  const AdminPharmaciesScreen({super.key});

  @override
  State<AdminPharmaciesScreen> createState() => _AdminPharmaciesScreenState();
}

class _AdminPharmaciesScreenState extends State<AdminPharmaciesScreen> {
  bool _isLoading = false;
  List<dynamic> _pharmacies = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPharmacies();
  }

  Future<void> _fetchPharmacies() async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/admin/pharmacies'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        if (mounted) setState(() => _pharmacies = data['data']);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredPharmacies = _pharmacies.where((ph) {
      return SearchUtils.matches(ph['name'], _searchQuery) ||
          SearchUtils.matches(ph['email'], _searchQuery) ||
          SearchUtils.matches(ph['phone'], _searchQuery) ||
          SearchUtils.matches(ph['address'], _searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.managePharmaciesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPharmacies,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchPharmaciesHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPharmacies.isEmpty
                ? Center(child: Text(l10n.noPharmaciesFound))
                : ListView.builder(
                    itemCount: filteredPharmacies.length,
                    itemBuilder: (context, index) {
                      final ph = filteredPharmacies[index];
                      final owner = ph['owner'];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ExpansionTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.local_pharmacy),
                          ),
                          title: Text(ph['name']),
                          subtitle: Text(
                            ph['address'] ??
                                AppLocalizations.of(context)!.labelAddress,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _detailRow(
                                    AppLocalizations.of(
                                      context,
                                    )!.labelOwnerName,
                                    ph['ownerName'],
                                  ),
                                  _detailRow(
                                    AppLocalizations.of(context)!.labelEmail,
                                    ph['email'],
                                  ),
                                  _detailRow(
                                    AppLocalizations.of(context)!.labelPhone,
                                    ph['phone'],
                                  ),
                                  _detailRow(
                                    AppLocalizations.of(context)!.labelBalance,
                                    '${ph['balance'] ?? 0} ${AppLocalizations.of(context)!.coinsSuffix}',
                                  ),
                                  const Divider(),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.userInformation,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  _detailRow(
                                    AppLocalizations.of(context)!.labelName,
                                    owner?['name'] ?? 'N/A',
                                  ),
                                  _detailRow(
                                    AppLocalizations.of(context)!.labelEmail,
                                    owner?['email'] ?? 'N/A',
                                  ),
                                  _detailRow(
                                    l10n.labelAccountStatus,
                                    ph['status']?.toUpperCase() ??
                                        l10n.labelUnknown,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AdminSimulationScreen(
                                                  pharmacyId: ph['_id'],
                                                  pharmacyName: ph['name'],
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.visibility),
                                      label: Text(l10n.actionSimulate),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[800],
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _showCompensationDialog(
                                                context,
                                                ph['_id'],
                                                ph['name'],
                                              ),
                                          icon: const Icon(
                                            Icons.monetization_on,
                                          ),
                                          label: Text(l10n.actionCompensation),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[700],
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _showCompensationHistory(
                                                context,
                                                ph['_id'],
                                                ph['name'],
                                              ),
                                          icon: const Icon(Icons.history),
                                          label: Text(l10n.actionHistory),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _showPaymentDialog(
                                            context,
                                            ph['_id'],
                                            ph['name'],
                                          ),
                                          icon: const Icon(Icons.payment),
                                          label: Text(l10n.actionPayment),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[700],
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showPaymentHistory(
                                            context,
                                            ph['_id'],
                                            ph['name'],
                                          ),
                                          icon: const Icon(Icons.receipt_long),
                                          label: Text(l10n.actionPayments),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showCompensationDialog(
    BuildContext context,
    String pharmacyId,
    String pharmacyName, {
    Map<String, dynamic>? compensation,
  }) {
    final amountController = TextEditingController(
      text: compensation != null ? compensation['amount'].toString() : '',
    );
    final descriptionController = TextEditingController(
      text: compensation != null ? compensation['description'] : '',
    );
    bool isSubmitting = false;
    final isEdit = compensation != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(
              isEdit
                  ? l10n.editBalanceTitle
                  : '${l10n.adjustBalanceTitle} - $pharmacyName',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.adjustmentAmountLabel,
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.reasonLabel,
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.actionCancel),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final amount = double.tryParse(amountController.text);
                        final description = descriptionController.text.trim();

                        if (amount == null ||
                            amount == 0 ||
                            description.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.errorRequired,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        try {
                          final token = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).token;

                          final url = isEdit
                              ? '${Constants.baseUrl}/compensation/${compensation!['_id']}'
                              : '${Constants.baseUrl}/compensation';

                          final method = isEdit ? http.put : http.post;

                          final response = await method(
                            Uri.parse(url),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                            },
                            body: json.encode({
                              if (!isEdit) 'pharmacyId': pharmacyId,
                              'amount': amount,
                              'description': description,
                            }),
                          );

                          final data = json.decode(response.body);

                          if ((response.statusCode == 200 ||
                                  response.statusCode == 201) &&
                              data['success']) {
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.adjustmentSuccess,
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _fetchPharmacies(); // Refresh list
                            }
                          } else {
                            throw Exception(data['message'] ?? 'Failed');
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isEdit
                            ? AppLocalizations.of(context)!.actionUpdate
                            : AppLocalizations.of(
                                context,
                              )!.actionDirectAdjustment,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCompensationHistory(
    BuildContext context,
    String pharmacyId,
    String pharmacyName,
  ) {
    // This part can remain mostly generic or add more ARB keys if user demands full coverage
    // Using existing keys where possible
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => FutureBuilder(
          future: _fetchCompensations(context, pharmacyId),
          builder: (context, snapshot) {
            final l10n = AppLocalizations.of(context)!;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final compensations = snapshot.data as List<dynamic>? ?? [];

            return Column(
              children: [
                AppBar(
                  title: Text(
                    '$pharmacyName ${AppLocalizations.of(context)!.actionHistory}',
                  ),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                if (compensations.isEmpty)
                  Expanded(child: Center(child: Text(l10n.noMatchesFound)))
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: compensations.length,
                      itemBuilder: (context, index) {
                        final comp = compensations[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: const Icon(
                              Icons.attach_money,
                              color: Colors.green,
                            ),
                          ),
                          title: Text(
                            '${comp['amount']} ${AppLocalizations.of(context)!.coinsSuffix}',
                          ),
                          subtitle: Text(
                            (Localizations.localeOf(context).languageCode ==
                                        'ar' &&
                                    comp['description_ar'] != null)
                                ? comp['description_ar']
                                : (comp['description'] ?? ''),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showCompensationDialog(
                                    context,
                                    pharmacyId,
                                    pharmacyName,
                                    compensation: comp,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  _confirmDelete(
                                    context,
                                    comp['_id'],
                                    pharmacyId,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<dynamic>> _fetchCompensations(
    BuildContext context,
    String pharmacyId,
  ) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/compensation/$pharmacyId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        return data['data'];
      }
    } catch (e) {
      debugPrint('Error fetching compensations: $e');
    }
    return [];
  }

  void _confirmDelete(
    BuildContext context,
    String compensationId,
    String pharmacyId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.dialogConfirmDeleteAdjustment),
          content: Text(
            l10n.msgConfirmDeleteAdjustment,
          ), // Add to ARB if strictly needed
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close sheet
                await _deleteCompensation(context, compensationId);
                _fetchPharmacies(); // Refresh balance
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.actionDeleteRevert),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCompensation(
    BuildContext context,
    String compensationId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/compensation/$compensationId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.msgAdjustmentReverted),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Payment Methods (similar to compensation)
  void _showPaymentDialog(
    BuildContext context,
    String pharmacyId,
    String pharmacyName, {
    Map<String, dynamic>? payment,
  }) {
    final amountController = TextEditingController(
      text: payment != null ? payment['amount'].toString() : '',
    );
    final referenceController = TextEditingController(
      text: payment != null ? payment['referenceNumber'] ?? '' : '',
    );
    final noteController = TextEditingController(
      text: payment != null ? payment['adminNote'] ?? '' : '',
    );
    String type = payment != null ? payment['type'] : 'deposit';
    String method = payment != null ? payment['method'] ?? 'cash' : 'cash';
    bool isSubmitting = false;
    final isEdit = payment != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(
              isEdit
                  ? l10n.dialogEditPayment
                  : l10n.dialogRecordPayment(pharmacyName),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: l10n.labelPaymentType,
                    ),
                    value: type,
                    items: [
                      DropdownMenuItem(
                        value: 'deposit',
                        child: Text(l10n.labelDeposit),
                      ),
                      DropdownMenuItem(
                        value: 'withdrawal',
                        child: Text(l10n.labelWithdrawal),
                      ),
                    ],
                    onChanged: (val) => setDialogState(() => type = val!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: l10n.labelAdjustmentAmount,
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: l10n.labelPaymentMethod,
                    ),
                    value: method,
                    items: [
                      DropdownMenuItem(
                        value: 'cash',
                        child: Text(l10n.labelCash),
                      ),
                      DropdownMenuItem(
                        value: 'bank_transfer',
                        child: Text(l10n.labelBankTransfer),
                      ),
                      DropdownMenuItem(
                        value: 'cheque',
                        child: Text(l10n.labelCheque),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text(l10n.labelOther),
                      ),
                    ],
                    onChanged: (val) => setDialogState(() => method = val!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: referenceController,
                    decoration: InputDecoration(
                      labelText: l10n.labelReferenceNumber,
                      prefixIcon: const Icon(Icons.receipt),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: l10n.labelAdminNote,
                      prefixIcon: const Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.actionCancel),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.msgInvalidAmount),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        try {
                          final token = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).token;

                          final url = isEdit
                              ? '${Constants.baseUrl}/payment/${payment['_id']}'
                              : '${Constants.baseUrl}/payment';

                          final methodHttp = isEdit ? http.put : http.post;

                          final response = await methodHttp(
                            Uri.parse(url),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                            },
                            body: json.encode({
                              if (!isEdit) 'pharmacyId': pharmacyId,
                              'amount': amount,
                              'type': type,
                              'method': method,
                              'referenceNumber': referenceController.text,
                              'adminNote': noteController.text,
                            }),
                          );

                          final data = json.decode(response.body);

                          if ((response.statusCode == 200 ||
                                  response.statusCode == 201) &&
                              data['success']) {
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEdit
                                        ? l10n.msgPaymentUpdated
                                        : l10n.msgPaymentRecorded,
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _fetchPharmacies(); // Refresh list
                            }
                          } else {
                            throw Exception(data['message'] ?? 'Failed');
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? l10n.actionUpdate : l10n.actionRecord),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentHistory(
    BuildContext context,
    String pharmacyId,
    String pharmacyName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => FutureBuilder(
          future: _fetchPayments(context, pharmacyId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final payments = snapshot.data as List<dynamic>? ?? [];

            return Column(
              children: [
                AppBar(
                  title: Text(
                    '$pharmacyName - ${AppLocalizations.of(context)!.actionPayments}',
                  ),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                if (payments.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.msgNoBalanceHistory,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final pmt = payments[index];
                        final isDeposit = pmt['type'] == 'deposit';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDeposit
                                ? Colors.blue[100]
                                : Colors.orange[100],
                            child: Icon(
                              isDeposit ? Icons.add : Icons.remove,
                              color: isDeposit ? Colors.blue : Colors.orange,
                            ),
                          ),
                          title: Text(
                            '${isDeposit ? "+" : "-"}${pmt['amount']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDeposit ? Colors.blue : Colors.orange,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pmt['method'] ?? 'cash'} ${pmt['referenceNumber'] != null ? "• ${pmt['referenceNumber']}" : ""}',
                              ),
                              if (pmt['adminNote'] != null &&
                                  pmt['adminNote'].toString().isNotEmpty)
                                Text(
                                  pmt['adminNote'],
                                  style: const TextStyle(fontSize: 11),
                                ),
                              if (pmt['description'] != null)
                                Text(
                                  pmt['description'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showPaymentDialog(
                                    context,
                                    pharmacyId,
                                    pharmacyName,
                                    payment: pmt,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  _confirmDeletePayment(
                                    context,
                                    pmt['_id'],
                                    pharmacyId,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<dynamic>> _fetchPayments(
    BuildContext context,
    String pharmacyId,
  ) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/payment?pharmacyId=$pharmacyId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        return data['data'];
      }
    } catch (e) {
      debugPrint('Error fetching payments: $e');
    }
    return [];
  }

  void _confirmDeletePayment(
    BuildContext context,
    String paymentId,
    String pharmacyId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.titleConfirmDelete),
        content: Text(AppLocalizations.of(context)!.msgConfirmReversePayment),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close sheet
              await _deletePayment(context, paymentId);
              _fetchPharmacies(); // Refresh balance
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.actionDeleteRevert),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePayment(BuildContext context, String paymentId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/payment/$paymentId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.msgPaymentDeleted),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
