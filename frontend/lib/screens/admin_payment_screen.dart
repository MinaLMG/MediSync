import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../utils/api_service.dart';
import 'package:intl/intl.dart';
import '../l10n/generated/app_localizations.dart';

class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({super.key});

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<PaymentProvider>(context, listen: false).fetchPayments();
    });
  }

  void _showPaymentDialog(
    BuildContext context, {
    Map<String, dynamic>? payment,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => PaymentDialog(payment: payment),
    ).then((val) {
      if (val == true) {
        Provider.of<PaymentProvider>(context, listen: false).fetchPayments();
      }
    });
  }

  void _confirmDelete(
    BuildContext context,
    String paymentId,
    String pharmacyName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text(
          'Are you sure you want to delete this payment for $pharmacyName? This will reverse the balance change.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.deleteRequest('/payment/$paymentId');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment deleted successfully'),
                    ),
                  );
                  Provider.of<PaymentProvider>(
                    context,
                    listen: false,
                  ).fetchPayments();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final payments = paymentProvider.payments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => paymentProvider.fetchPayments(),
          ),
        ],
      ),
      body: paymentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : payments.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.noMatchesFound))
          : ListView.builder(
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                final isDeposit = payment['type'] == 'deposit';
                final date = DateTime.parse(payment['createdAt']).toLocal();

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDeposit
                          ? Colors.green[100]
                          : Colors.red[100],
                      child: Icon(
                        isDeposit ? Icons.add : Icons.remove,
                        color: isDeposit ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      payment['pharmacy']['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(DateFormat('MMM dd, yyyy • HH:mm').format(date)),
                        Text(
                          _formatMethod(payment['method'] ?? 'cash'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (payment['referenceNumber'] != null &&
                            payment['referenceNumber'].toString().isNotEmpty)
                          Text(
                            'Ref: ${payment['referenceNumber']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isDeposit ? "+" : "-"}${payment['amount']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDeposit ? Colors.green : Colors.red,
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showPaymentDialog(context, payment: payment);
                            } else if (value == 'delete') {
                              _confirmDelete(
                                context,
                                payment['_id'],
                                payment['pharmacy']['name'],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Payment'),
      ),
    );
  }

  String _formatMethod(String method) {
    switch (method) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cheque':
        return 'Cheque';
      case 'cash':
        return 'Cash';
      case 'other':
        return 'Other';
      default:
        return method;
    }
  }
}

class PaymentDialog extends StatefulWidget {
  final Map<String, dynamic>? payment;

  const PaymentDialog({super.key, this.payment});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPharmacyId;
  String _type = 'deposit';
  String _method = 'cash';
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();

  List<dynamic> _pharmacies = [];
  bool _isLoadingPharmacies = true;
  bool _isSubmitting = false;

  bool get isEdit => widget.payment != null;

  @override
  void initState() {
    super.initState();
    _fetchPharmacies();

    if (isEdit) {
      final p = widget.payment!;
      _selectedPharmacyId = p['pharmacy']['_id'];
      _type = p['type'];
      _method = p['method'] ?? 'cash';
      _amountController.text = p['amount'].toString();
      _referenceController.text = p['referenceNumber'] ?? '';
      _noteController.text = p['adminNote'] ?? '';
    }
  }

  Future<void> _fetchPharmacies() async {
    try {
      final response = await ApiService.getRequest('/admin/pharmacies');
      setState(() {
        _pharmacies = response['success'] ? response['data'] : [];
        _isLoadingPharmacies = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingPharmacies = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? 'Edit Payment' : 'New Payment'),
      content: _isLoadingPharmacies
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Pharmacy'),
                      value: _selectedPharmacyId,
                      items: _pharmacies.map<DropdownMenuItem<String>>((p) {
                        return DropdownMenuItem(
                          value: p['_id'],
                          child: Text(p['name']),
                        );
                      }).toList(),
                      onChanged: isEdit
                          ? null
                          : (val) => setState(() => _selectedPharmacyId = val),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Type'),
                      value: _type,
                      items: const [
                        DropdownMenuItem(
                          value: 'deposit',
                          child: Text('💰 Deposit'),
                        ),
                        DropdownMenuItem(
                          value: 'withdrawal',
                          child: Text('💸 Withdrawal'),
                        ),
                      ],
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (double.tryParse(val) == null ||
                            double.parse(val) <= 0) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                      ),
                      value: _method,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(
                          value: 'bank_transfer',
                          child: Text('Bank Transfer'),
                        ),
                        DropdownMenuItem(
                          value: 'cheque',
                          child: Text('Cheque'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (val) => setState(() => _method = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Reference Number (Optional)',
                        prefixIcon: Icon(Icons.receipt),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Admin Note (Optional)',
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.actionCancel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final data = {
        'pharmacyId': _selectedPharmacyId,
        'amount': double.parse(_amountController.text),
        'type': _type,
        'method': _method,
        'referenceNumber': _referenceController.text,
        'adminNote': _noteController.text,
      };

      if (isEdit) {
        await ApiService.putRequest('/payment/${widget.payment!['_id']}', data);
      } else {
        final success = await Provider.of<PaymentProvider>(
          context,
          listen: false,
        ).createPayment(data);
        if (!success) throw Exception('Failed to create payment');
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Payment updated' : 'Payment created'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
