import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/hub_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import 'hub_sales_item_widget.dart';
import 'hub_invoice_item_view_widget.dart';

class HubSalesInvoiceScreen extends StatefulWidget {
  const HubSalesInvoiceScreen({super.key});

  @override
  State<HubSalesInvoiceScreen> createState() => _HubSalesInvoiceScreenState();
}

class _HubSalesInvoiceScreenState extends State<HubSalesInvoiceScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<HubProvider>(context, listen: false).fetchSalesInvoices();
    });
  }

  void _viewInvoice(Map<String, dynamic> invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("View Sales Invoice")),
          body: HubSalesInvoiceForm(initialInvoice: invoice, readOnly: true),
        ),
      ),
    );
  }

  void _createNewInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HubSalesInvoiceForm()),
    );
  }

  void _editInvoice(dynamic invoice) {
    // For now, sales invoice edit only allows date update in backend?
    // Or we show it read-only?
    // I'll show it in the form but maybe disable item changes if too complex.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HubSalesInvoiceForm(initialInvoice: invoice),
      ),
    );
  }

  Future<void> _deleteInvoice(dynamic invoice) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSalesInvoice ?? "Delete Sales Invoice"),
        content: const Text(
          "Are you sure? This will restore the stock levels and reverse the cash balance update.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete ?? "Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final hubProvider = Provider.of<HubProvider>(context, listen: false);
      final result = await hubProvider.deleteSalesInvoice(invoice['_id']);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sales invoice deleted")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? "Failed to delete")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hub Sales Invoices"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Consumer<HubProvider>(
        builder: (context, hubProvider, _) {
          if (hubProvider.isLoading && hubProvider.salesInvoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hubProvider.salesInvoices.isEmpty) {
            return Center(child: Text(l10n.noDataAvailable));
          }

          return ListView.builder(
            itemCount: hubProvider.salesInvoices.length,
            itemBuilder: (context, index) {
              final invoice = hubProvider.salesInvoices[index];
              final date = DateTime.parse(invoice['date']);
              final total = invoice['totalSellingPrice'] ?? 0;
              final revenue = invoice['totalRevenuePrice'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    "Invoice #${invoice['_id'].toString().substring(invoice['_id'].length - 6).toUpperCase()}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal())}\nProfit: ${NumberFormat("#,##0").format(revenue)}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        NumberFormat.currency(symbol: 'EGP ').format(total),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'view') _viewInvoice(invoice);
                          if (val == 'edit') _editInvoice(invoice);
                          if (val == 'delete') _deleteInvoice(invoice);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                const Icon(Icons.visibility, size: 20),
                                const SizedBox(width: 8),
                                const Text("View"),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit, size: 20),
                                const SizedBox(width: 8),
                                Text(l10n.edit ?? "Edit"),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.delete ?? "Delete",
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
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
        onPressed: _createNewInvoice,
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class HubSalesInvoiceForm extends StatefulWidget {
  final Map<String, dynamic>? initialInvoice;
  final bool readOnly;
  const HubSalesInvoiceForm({
    super.key,
    this.initialInvoice,
    this.readOnly = false,
  });

  @override
  State<HubSalesInvoiceForm> createState() => _HubSalesInvoiceFormState();
}

class _HubSalesInvoiceFormState extends State<HubSalesInvoiceForm> {
  final List<Map<String, dynamic>> _items = [];
  double _totalSellingAmount = 0.0;
  double _totalCostAmount = 0.0;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialInvoice != null) {
      final items = widget.initialInvoice!['items'] as List;
      for (var item in items) {
        final excessData = item['excess'];
        final productData = item['product'];

        _items.add({
          '_id': item['_id'],
          'excess': excessData is Map ? excessData['_id'] : excessData,
          'product_name': productData is Map ? productData['name'] : 'Unknown',
          'quantity': item['quantity'],
          'buyingPrice': (item['buyingPrice'] ?? 0).toDouble(),
          'sellingPrice': (item['sellingPrice'] ?? 0).toDouble(),
          'total': ((item['quantity'] ?? 0) * (item['sellingPrice'] ?? 0))
              .toDouble(),
        });
      }
      _calculateTotals();
    }
  }

  void _addItem() {
    if (widget.initialInvoice != null) {
      // For sales, we might want to restrict editing items after the fact?
      // But let's allow it if it stays in frontend for now.
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HubSalesItemWidget(
        onAdd: (item) {
          setState(() {
            _items.add(item);
            _hasChanges = true;
            _calculateTotals();
          });
        },
      ),
    );
  }

  void _calculateTotals() {
    double selling = 0.0;
    double cost = 0.0;
    for (var item in _items) {
      selling += (item['total'] as num).toDouble();
      cost += ((item['buyingPrice'] ?? 0) * (item['quantity'] ?? 0));
    }
    setState(() {
      _totalSellingAmount = selling;
      _totalCostAmount = cost;
    });
  }

  Future<void> _submitInvoice() async {
    if (_items.isEmpty || _isLoading) return;

    try {
      final hubProvider = Provider.of<HubProvider>(context, listen: false);

      final invoiceData = {
        'items': _items
            .map(
              (e) => {
                'excess': e['excess'],
                'quantity': e['quantity'],
                'sellingPrice': e['sellingPrice'],
              },
            )
            .toList(),
        'date': DateTime.now().toIso8601String(),
      };

      final result = widget.initialInvoice == null
          ? await hubProvider.createSalesInvoice(invoiceData)
          : await hubProvider.updateSalesInvoice(
              widget.initialInvoice!['_id'],
              invoiceData,
            );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.initialInvoice == null
                    ? "Sales invoice created successfully"
                    : "Sales invoice updated successfully",
              ),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? "Failed to save invoice"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _editItem(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => widget.readOnly
          ? HubInvoiceItemViewWidget(item: _items[index], isSales: true)
          : HubSalesItemWidget(
              initialData: _items[index],
              readOnly: widget.readOnly,
              onAdd: (item) {
                if (widget.readOnly) return;
                setState(() {
                  _items[index] = item;
                  _hasChanges = true;
                  _calculateTotals();
                });
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialInvoice == null
              ? "New Sales Invoice"
              : "View Sales Invoice",
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text("No items added yet"))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        title: Text(item['product_name']),
                        subtitle: Text(
                          "Qty: ${item['quantity']} | Cost: ${(item['buyingPrice'] as num).toStringAsFixed(1)} | Sell: ${(item['sellingPrice'] as num).toStringAsFixed(1)}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              NumberFormat("#,##0").format(item['total']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!widget.readOnly)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _items.removeAt(index);
                                    _hasChanges = true;
                                    _calculateTotals();
                                  });
                                },
                              ),
                          ],
                        ),
                        onTap: () => _editItem(index),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_hasChanges)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.orange[800],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "You have unsaved changes. Click save to commit to backend.",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Revenue:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        symbol: "EGP ",
                      ).format(_totalSellingAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!widget.readOnly)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_items.isEmpty || _isLoading)
                          ? null
                          : _submitInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "${AppLocalizations.of(context)!.btnSave} & Sync",
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
              onPressed: _addItem,
              backgroundColor: Colors.blue[800],
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}
