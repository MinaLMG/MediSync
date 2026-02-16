import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hub_provider.dart';
import '../../providers/product_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'hub_purchase_item_widget.dart';
import 'hub_invoice_item_view_widget.dart';

class HubPurchaseInvoiceScreen extends StatefulWidget {
  const HubPurchaseInvoiceScreen({super.key});

  @override
  State<HubPurchaseInvoiceScreen> createState() =>
      _HubPurchaseInvoiceScreenState();
}

class _HubPurchaseInvoiceScreenState extends State<HubPurchaseInvoiceScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<HubProvider>(context, listen: false).fetchPurchaseInvoices();
    });
  }

  void _viewInvoice(Map<String, dynamic> invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("View Purchase Invoice")),
          body: HubPurchaseInvoiceForm(initialInvoice: invoice, readOnly: true),
        ),
      ),
    );
  }

  void _createNewInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HubPurchaseInvoiceForm()),
    );
  }

  void _editInvoice(dynamic invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HubPurchaseInvoiceForm(initialInvoice: invoice),
      ),
    );
  }

  Future<void> _deleteInvoice(dynamic invoice) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePurchaseInvoice ?? "Delete Invoice"),
        content: Text(
          l10n.deleteInvoiceConfirmation ??
              "Are you sure you want to delete this invoice? This will reverse the stock and cash balance.",
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
      final result = await hubProvider.deletePurchaseInvoice(invoice['_id']);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invoice deleted successfully")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? "Failed to delete invoice"),
            ),
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
        title: Text(l10n.menuHubPurchaseInvoice),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Consumer<HubProvider>(
        builder: (context, hubProvider, _) {
          if (hubProvider.isLoading && hubProvider.purchaseInvoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hubProvider.purchaseInvoices.isEmpty) {
            return Center(child: Text(l10n.noDataAvailable));
          }

          return ListView.builder(
            itemCount: hubProvider.purchaseInvoices.length,
            itemBuilder: (context, index) {
              final invoice = hubProvider.purchaseInvoices[index];
              final date = DateTime.parse(invoice['date']);
              final total = invoice['totalAmount'] ?? 0;
              final itemsCount = (invoice['items'] as List).length;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    "Invoice #${invoice['_id'].toString().substring(invoice['_id'].length - 6).toUpperCase()}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal())}\n$itemsCount items",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        NumberFormat.currency(symbol: 'EGP ').format(total),
                        style: const TextStyle(
                          color: Colors.blue,
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

class HubPurchaseInvoiceForm extends StatefulWidget {
  final Map<String, dynamic>? initialInvoice;
  final bool readOnly;
  const HubPurchaseInvoiceForm({
    super.key,
    this.initialInvoice,
    this.readOnly = false,
  });

  @override
  State<HubPurchaseInvoiceForm> createState() => _HubPurchaseInvoiceFormState();
}

class _HubPurchaseInvoiceFormState extends State<HubPurchaseInvoiceForm> {
  final List<Map<String, dynamic>> _items = [];
  double _totalAmount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialInvoice != null) {
      final items = widget.initialInvoice!['items'] as List;
      for (var item in items) {
        // Safe access for excess/product/volume which might be Strings or Maps
        final excessData = item['excess'];
        final productData = item['product'];
        final volumeData = item['volume'];

        _items.add({
          '_id': item['_id'],
          'excess': excessData is Map ? excessData['_id'] : excessData,
          'product': productData is Map ? productData['_id'] : productData,
          'product_name': productData is Map ? productData['name'] : 'Unknown',
          'volume': volumeData is Map ? volumeData['_id'] : volumeData,
          'quantity': item['quantity'],
          'buyingPrice': (item['buyingPrice'] ?? 0).toDouble(),
          'sellingPrice': (item['sellingPrice'] ?? 0).toDouble(),
          'salePercentage': (item['salePercentage'] ?? 0).toDouble(),
          'total': ((item['quantity'] ?? 0) * (item['buyingPrice'] ?? 0))
              .toDouble(),
          'expiryDate': item['expiryDate'],
        });
      }
      _calculateTotal();
    }
    Future.microtask(() {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  void _calculateTotal() {
    setState(() {
      _totalAmount = _items.fold(
        0.0,
        (sum, item) => sum + (item['total'] as double),
      );
    });
  }

  Future<void> _submitInvoice() async {
    if (_items.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final hubProvider = Provider.of<HubProvider>(context, listen: false);
      Map<String, dynamic> result;

      if (widget.initialInvoice == null) {
        result = await hubProvider.createPurchaseInvoice({
          'items': _items,
          'totalAmount': _totalAmount,
          'date': DateTime.now().toIso8601String(),
        });
      } else {
        result = await hubProvider.updatePurchaseInvoice(
          widget.initialInvoice!['_id'],
          {
            'items': _items,
            'date':
                widget.initialInvoice!['date'], // Keep original date or update?
          },
        );
      }

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.initialInvoice == null
                    ? "Invoice created"
                    : "Invoice updated",
              ),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? "Error processing invoice"),
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

  void _addItem() {
    if (widget.readOnly) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => HubPurchaseItemWidget(
        onAdd: (item) {
          setState(() {
            _items.add(item);
            _calculateTotal();
          });
        },
      ),
    );
  }

  void _editItem(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => widget.readOnly
          ? HubInvoiceItemViewWidget(item: _items[index])
          : HubPurchaseItemWidget(
              initialData: _items[index],
              readOnly: widget.readOnly,
              onAdd: (item) {
                if (widget.readOnly) return;
                setState(() {
                  _items[index] = item;
                  _calculateTotal();
                });
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.readOnly
              ? "View Purchase Invoice"
              : widget.initialInvoice == null
              ? "New Purchase Invoice"
              : "Edit Purchase Invoice",
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
                          "Qty: ${item['quantity']} | Buy: ${item['buyingPrice']} | Sell: ${item['sellingPrice']}",
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
                                    _calculateTotal();
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
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Amount:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      NumberFormat("#,##0").format(_totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (widget.readOnly || _items.isEmpty || _isLoading)
                        ? null
                        : _submitInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.readOnly
                          ? Colors.grey
                          : widget.initialInvoice == null
                          ? Colors.green
                          : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: widget.readOnly
                        ? const Text("Read Only Mode")
                        : _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.initialInvoice == null
                                ? "Confirm Purchase"
                                : "Save Changes",
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
              child: const Icon(Icons.add),
            ),
    );
  }
}
