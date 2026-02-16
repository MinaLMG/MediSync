import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/excess_provider.dart';
import '../../l10n/generated/app_localizations.dart';

class HubSalesItemWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final Map<String, dynamic>? initialData;
  final bool readOnly;
  const HubSalesItemWidget({
    super.key,
    required this.onAdd,
    this.initialData,
    this.readOnly = false,
  });

  @override
  State<HubSalesItemWidget> createState() => _HubSalesItemWidgetState();
}

class _HubSalesItemWidgetState extends State<HubSalesItemWidget> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProductId;
  Map<String, dynamic>? _selectedExcess;

  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  List<dynamic> _productExcesses = [];
  bool _isLoadingExcesses = false;
  String? _itemId;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _selectedProductId = data['product'];
      _itemId = data['_id'];
      _sellingPriceController.text = (data['sellingPrice'] ?? '').toString();
      _quantityController.text = (data['quantity'] ?? '').toString();
    }
    Future.microtask(() => _fetchMyExcesses());
  }

  Future<void> _fetchMyExcesses() async {
    setState(() => _isLoadingExcesses = true);
    await Provider.of<ExcessProvider>(context, listen: false).fetchMyExcesses();
    if (mounted) {
      if (widget.initialData != null) {
        final allExcesses = Provider.of<ExcessProvider>(
          context,
          listen: false,
        ).myExcesses;
        final targetExcessId = widget.initialData!['excess'];
        final match = allExcesses.firstWhere(
          (e) => e['_id'] == targetExcessId,
          orElse: () => null,
        );
        setState(() {
          _selectedExcess = match;
          // Filter products for dropdown
          if (_selectedProductId != null) {
            _productExcesses = allExcesses.where((e) {
              return e['product']['_id'] == _selectedProductId &&
                  (e['status'] == 'available' ||
                      e['status'] == 'partially_fulfilled' ||
                      e['_id'] == targetExcessId);
            }).toList();
          }
        });
      }
      setState(() => _isLoadingExcesses = false);
    }
  }

  void _onProductSelected(String? id, String? name) {
    setState(() {
      _selectedProductId = id;
      _selectedExcess = null;
      _productExcesses = [];
    });

    if (id != null) {
      final allExcesses = Provider.of<ExcessProvider>(
        context,
        listen: false,
      ).myExcesses;

      // Filter for this product, available status, and remaining quantity > 0
      final matches = allExcesses.where((e) {
        return e['product']['_id'] == id &&
            (e['status'] == 'available' ||
                e['status'] == 'partially_fulfilled') &&
            (e['remainingQuantity'] ?? 0) > 0;
      }).toList();

      setState(() {
        _productExcesses = matches;
        if (matches.length == 1) {
          _selectedExcess = matches.first;
          _quantityController.text = "1";
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedExcess == null) return;

      final qty = int.parse(_quantityController.text);
      final sellingPrice = double.parse(_sellingPriceController.text);

      widget.onAdd({
        '_id': _itemId,
        'excess': _selectedExcess!['_id'],
        'product': _selectedExcess!['product']['_id'],
        'product_name': _selectedExcess!['product']['name'],
        'volume': _selectedExcess!['volume']['_id'],
        'volume_name': _selectedExcess!['volume']['name'],
        'quantity': qty,
        'sellingPrice': sellingPrice,
        'buyingPrice':
            _selectedExcess!['purchasePrice'] ??
            0, // For reference/display in list
        'expiryDate': _selectedExcess!['expiryDate'],
        'total': qty * sellingPrice,
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Extract unique products for dropdown
    final allExcesses = Provider.of<ExcessProvider>(context).myExcesses;
    final uniqueProducts = <String, Map<String, dynamic>>{};
    for (var e in allExcesses) {
      if ((e['status'] == 'available' ||
              e['status'] == 'partially_fulfilled') &&
          (e['remainingQuantity'] ?? 0) > 0) {
        final prod = e['product'];
        if (prod != null) {
          uniqueProducts[prod['_id']] = {
            '_id': prod['_id'],
            'name': prod['name'],
          };
        }
      }
    }
    final availableProductsList = uniqueProducts.values.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text(
            widget.initialData != null ? "Edit Sales Item" : "Add Sales Item",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingExcesses
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        // Product Dropdown (Local Search)
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: localizations
                                .labelSelectProduct, // "Select Product"
                            border: const OutlineInputBorder(),
                          ),
                          value: _selectedProductId,
                          items: availableProductsList.map((prod) {
                            return DropdownMenuItem<String>(
                              value: prod['_id'],
                              child: Text(prod['name']),
                            );
                          }).toList(),
                          onChanged: widget.readOnly
                              ? null
                              : (val) {
                                  final prod = uniqueProducts[val];
                                  _onProductSelected(val, prod?['name']);
                                },
                        ),
                        const SizedBox(height: 16),

                        // Excess Selection (if multiple)
                        if (_productExcesses.length > 1)
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: "Select Batch",
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedExcess?['_id'],
                            items: _productExcesses
                                .map<DropdownMenuItem<String>>((e) {
                                  final expiry = e['expiryDate'];
                                  final price =
                                      e['selectedPrice']; // Public/Selling Price
                                  final qty = e['remainingQuantity'];
                                  return DropdownMenuItem(
                                    value: e['_id'],
                                    child: Text(
                                      "$expiry | Price: $price | Qty: $qty",
                                    ),
                                  );
                                })
                                .toList(),
                            onChanged: widget.readOnly
                                ? null
                                : (val) {
                                    setState(() {
                                      _selectedExcess = _productExcesses
                                          .firstWhere((e) => e['_id'] == val);
                                    });
                                  },
                          ),

                        if (_selectedExcess != null) ...[
                          const SizedBox(height: 16),
                          // Details Card
                          Card(
                            color: Colors.grey[100],
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Volume: ${_selectedExcess!['volume']['name']}",
                                  ),
                                  Text(
                                    "Expiry: ${_selectedExcess!['expiryDate']}",
                                  ),
                                  Text(
                                    "Buying Cost: ${NumberFormat("#,##0").format(_selectedExcess!['purchasePrice'] ?? 0)}",
                                  ),
                                  Text(
                                    "Available Quantity: ${_selectedExcess!['remainingQuantity']}",
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Selling Price Input
                          TextFormField(
                            controller: _sellingPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: localizations
                                  .labelSellingPrice, // "Selling Price"
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return localizations.errorRequiredField;
                              if (double.tryParse(value) == null)
                                return "Invalid price";
                              return null;
                            },
                            enabled: !widget.readOnly,
                          ),
                          const SizedBox(height: 16),

                          // Quantity Input
                          TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText:
                                  localizations.labelQuantity, // "Quantity"
                              border: const OutlineInputBorder(),
                              helperText:
                                  "Max Available: ${(_selectedExcess!['remainingQuantity'] ?? 0) + (widget.initialData != null ? (widget.initialData!['quantity'] ?? 0) : 0)}",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return localizations.errorRequiredField;
                              final q = int.tryParse(value);
                              if (q == null || q <= 0)
                                return "Invalid quantity";

                              final maxAllowed =
                                  (_selectedExcess!['remainingQuantity'] ?? 0) +
                                  (widget.initialData != null
                                      ? (widget.initialData!['quantity'] ?? 0)
                                      : 0);

                              if (q > maxAllowed)
                                return "Exceeds available ($maxAllowed)";
                              return null;
                            },
                            enabled: !widget.readOnly,
                          ),
                        ] else if (_selectedProductId != null &&
                            _productExcesses.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "No available excess stock for this product.",
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.readOnly ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.readOnly
                    ? Colors.grey
                    : Colors.blue[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.readOnly
                    ? "View Mode"
                    : (widget.initialData != null
                          ? "Save Changes"
                          : localizations.btnAdd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
