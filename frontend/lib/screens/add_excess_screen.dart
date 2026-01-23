import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/excess_provider.dart';

class AddExcessScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddExcessScreen({super.key, this.initialData});

  @override
  State<AddExcessScreen> createState() => _AddExcessScreenState();
}

class _AddExcessScreenState extends State<AddExcessScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProductId;
  String? _selectedVolumeId;
  double? _selectedPrice;
  bool _isManualPrice = false;
  final TextEditingController _manualPriceController = TextEditingController();

  DateTime? _expiryDate;
  final TextEditingController _quantityController = TextEditingController();

  String _saleType = 'percentage'; // or 'price'
  final TextEditingController _saleValueController = TextEditingController();

  bool get isEditMode => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Provider.of<ProductProvider>(
        context,
        listen: false,
      ).fetchProducts();

      if (isEditMode) {
        final data = widget.initialData!;
        setState(() {
          _selectedProductId = data['product']['_id'];
          _selectedVolumeId = data['volume']['_id'];
          _expiryDate = DateTime.parse(data['expiryDate']);
          _quantityController.text = data['originalQuantity'].toString();

          // Price logic
          final price = data['selectedPrice'].toDouble();
          _selectedPrice =
              price; // We'll check if it exists in list during build

          if (data['saleType'] != null) {
            _saleType = data['saleType'];
            _saleValueController.text = data['saleValue'].toString();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _manualPriceController.dispose();
    _quantityController.dispose();
    _saleValueController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _expiryDate != null) {
      if (_selectedProductId == null || _selectedVolumeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select product and volume')),
        );
        return;
      }

      final price = _isManualPrice
          ? double.parse(_manualPriceController.text)
          : _selectedPrice;

      if (price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or enter a price')),
        );
        return;
      }

      // Validation: Discount cannot be higher than 30%
      final saleValText = _saleValueController.text;
      double? saleVal;

      if (saleValText.isNotEmpty) {
        saleVal = double.tryParse(saleValText);
        if (saleVal == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid sale value')),
          );
          return;
        }

        if (_saleType == 'percentage') {
          if (saleVal > 30) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sale cannot exceed 30%')),
            );
            return;
          }
        } else {
          // 'flat' means discount amount.
          // Max discount is 30% of price.
          // e.g. Price 100, max discount 30. Entered 35 -> Error.

          final maxDiscount = price * 0.3;

          if (saleVal > maxDiscount) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Discount too high. Max 30% discount is ${maxDiscount.toStringAsFixed(2)} EGP',
                ),
              ),
            );
            return;
          }

          // Also check if saleVal >= price (cannot give away for free or pay user)
          if (saleVal >= price) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Discount cannot be equal or greater than the price',
                ),
              ),
            );
            return;
          }
        }
      }

      final excessData = {
        'product': _selectedProductId,
        'volume': _selectedVolumeId,
        'quantity': int.parse(_quantityController.text),
        'expiryDate': _expiryDate!.toIso8601String(),
        'selectedPrice': price,
        'saleType': saleVal != null ? _saleType : null,
        'saleValue': saleVal,
      };

      final success = isEditMode
          ? await Provider.of<ExcessProvider>(
              context,
              listen: false,
            ).updateExcess(widget.initialData!['_id'], excessData)
          : await Provider.of<ExcessProvider>(
              context,
              listen: false,
            ).addExcess(excessData);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? 'Excess updated successfully'
                    : 'Excess added successfully',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<ExcessProvider>(
                      context,
                      listen: false,
                    ).errorMessage ??
                    'Error processing request',
              ),
            ),
          );
        }
      }
    } else if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select expiry date')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    // Logic to get current product and volumes
    final selectedProduct = _selectedProductId != null
        ? productProvider.products.firstWhere(
            (p) => p['_id'] == _selectedProductId,
            orElse: () => null,
          )
        : null;

    final volumes = selectedProduct?['volumes'] as List<dynamic>? ?? [];

    // Auto-select volume if only one
    if (volumes.length == 1 && _selectedVolumeId != volumes[0]['volumeId']) {
      // Defer state update to next frame to avoid build error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedVolumeId = volumes[0]['volumeId'];
          // Also reset price selection when volume changes automatically
          _selectedPrice = null;
        });
      });
    }

    // Get prices for selected volume
    final currentVolume = volumes.firstWhere(
      (v) => v['volumeId'] == _selectedVolumeId,
      orElse: () => null,
    );
    final List<String> prices =
        (currentVolume?['prices'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // Price logic for Edit Mode: If the price isn't in the list, treat as manual
    if (isEditMode &&
        _selectedPrice != null &&
        !_isManualPrice &&
        prices.isNotEmpty) {
      if (!prices.contains(_selectedPrice.toString())) {
        _isManualPrice = true;
        _manualPriceController.text = _selectedPrice!.toString();
        _selectedPrice = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Excess Stock' : 'Add Excess Stock'),
      ),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedProductId,
                      decoration: const InputDecoration(labelText: 'Product'),
                      items: productProvider.products
                          .map<DropdownMenuItem<String>>((product) {
                            return DropdownMenuItem(
                              value: product['_id'],
                              child: Text(product['name']),
                            );
                          })
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProductId = value;
                          _selectedVolumeId = null;
                          _selectedPrice = null;
                          _isManualPrice = false;
                        });
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Volume Dropdown
                    if (volumes.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedVolumeId,
                        decoration: const InputDecoration(labelText: 'Volume'),
                        items: volumes.map<DropdownMenuItem<String>>((v) {
                          return DropdownMenuItem(
                            value: v['volumeId'],
                            child: Text(v['volumeName']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVolumeId = value;
                            _selectedPrice = null;
                            _isManualPrice = false;
                          });
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    const SizedBox(height: 16),

                    // Price Section
                    if (_selectedVolumeId != null) ...[
                      const Text(
                        'Price (EGP)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (!_isManualPrice)
                        DropdownButtonFormField<double>(
                          value: _selectedPrice,
                          decoration: const InputDecoration(
                            labelText: 'Select Price',
                          ),
                          items: prices.map((p) {
                            return DropdownMenuItem(
                              value: double.parse(p),
                              child: Text(p),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPrice = value;
                            });
                          },
                        ),

                      Row(
                        children: [
                          Checkbox(
                            value: _isManualPrice,
                            onChanged: (val) {
                              setState(() {
                                _isManualPrice = val!;
                                if (_isManualPrice) _selectedPrice = null;
                              });
                            },
                          ),
                          const Text('Enter Manual Price'),
                        ],
                      ),

                      if (_isManualPrice)
                        TextFormField(
                          controller: _manualPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Manual Price',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                    ],
                    const SizedBox(height: 16),

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Expiry Date
                    ListTile(
                      title: Text(
                        _expiryDate == null
                            ? 'Select Expiry Date'
                            : 'Expiry: ${DateFormat('yyyy-MM-dd').format(_expiryDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                          firstDate: DateTime.now(), // Block past dates
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked != null) {
                          // Double check
                          if (picked.isBefore(
                            DateTime.now().subtract(const Duration(days: 1)),
                          )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Expiry date cannot be in the past',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() => _expiryDate = picked);
                        }
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Sale Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sale Offer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Percentage Off'),
                                  value: 'percentage',
                                  groupValue: _saleType,
                                  onChanged: (v) =>
                                      setState(() => _saleType = v!),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Flat Discount'),
                                  value: 'flat',
                                  groupValue: _saleType,
                                  onChanged: (v) =>
                                      setState(() => _saleType = v!),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: _saleValueController,
                            decoration: InputDecoration(
                              labelText: _saleType == 'percentage'
                                  ? 'Percentage Value (%)'
                                  : 'Discount Amount (EGP)',
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => null, // Optional
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            Provider.of<ExcessProvider>(context).isLoading
                            ? null
                            : _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                        ),
                        child: Provider.of<ExcessProvider>(context).isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                isEditMode ? 'Update Excess' : 'Submit Excess',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
