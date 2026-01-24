import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/excess_provider.dart';
import '../providers/settings_provider.dart';

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

  bool _shortageFulfillment = false;
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

      if (mounted) {
        await Provider.of<SettingsProvider>(
          context,
          listen: false,
        ).fetchSettings();
      }

      if (isEditMode) {
        final data = widget.initialData!;
        setState(() {
          _selectedProductId = data['product']['_id'];
          _selectedVolumeId = data['volume']['_id'];
          _expiryDate = DateTime.parse(data['expiryDate']);
          _quantityController.text = data['originalQuantity'].toString();
          _shortageFulfillment = data['shortage_fulfillment'] ?? true;

          // Price logic
          final price = data['selectedPrice'].toDouble();
          _selectedPrice =
              price; // We'll check if it exists in list during build

          if (data['salePercentage'] != null) {
            _saleValueController.text = data['salePercentage'].toString();
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
          ? double.tryParse(_manualPriceController.text)
          : _selectedPrice;

      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid price')),
        );
        return;
      }

      double? saleVal;

      if (!_shortageFulfillment) {
        final saleValText = _saleValueController.text;
        if (saleValText.isNotEmpty) {
          saleVal = double.tryParse(saleValText);
          if (saleVal == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a valid sale percentage'),
              ),
            );
            return;
          }

          if (saleVal < 0 || saleVal > 100) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sale value must be between 0% and 100%'),
              ),
            );
            return;
          }
        }
      } else {
        saleVal = 0;
      }

      final quantity = int.tryParse(_quantityController.text);
      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid quantity')),
        );
        return;
      }

      final excessData = {
        'product': _selectedProductId,
        'volume': _selectedVolumeId,
        'quantity': quantity,
        'expiryDate': _expiryDate!.toIso8601String(),
        'selectedPrice': price,
        'salePercentage': saleVal,
        'shortage_fulfillment': _shortageFulfillment,
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
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                    ],
                    const SizedBox(height: 16),

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

                    // Type Selection (Fulfillment vs Real Excess)
                    const Text(
                      'Request Type',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<bool>(
                      value: _shortageFulfillment,
                      items: const [
                        DropdownMenuItem(
                          value: true,
                          child: Text('Shortage Fulfillment'),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text('Real Excess'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _shortageFulfillment = val!;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sale Info (Only for Real Excess)
                    if (!_shortageFulfillment)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue[200]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.blue[50],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sale Offer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'The current system sale is ${context.read<SettingsProvider>().minCommission}% if you would like to provide a higher sale enter its value. Higher sales have higher opportunities to be matched faster.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[800],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _saleValueController,
                              decoration: const InputDecoration(
                                labelText: 'Percentage Value (%)',
                                border: OutlineInputBorder(),
                                suffixText: '%',
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
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
