import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/excess_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/searchable_dropdown.dart';

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

  String? _expiryDate; // Stored as "MM/YY"
  final TextEditingController _expiryController = TextEditingController();
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
          _expiryDate = data['expiryDate'];
          _expiryController.text = _expiryDate ?? '';
          _quantityController.text = data['originalQuantity'].toString();
          _shortageFulfillment = data['shortage_fulfillment'] ?? true;

          // Price logic
          final price = data['selectedPrice'].toDouble();
          _selectedPrice = price;
          _manualPriceController.text = price.toString();

          // Initialize _isManualPrice if the initial price is not in the list
          // This will be refined as soon as settings/products are fetched
          _isManualPrice =
              true; // Default to true if editing, will be checked against list later

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
    _expiryController.dispose();
    _quantityController.dispose();
    _saleValueController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    if (isEditMode) return;

    int selectedYear = _expiryDate != null
        ? 2000 + int.parse(_expiryDate!.split('/')[1])
        : DateTime.now().year;
    int selectedMonth = _expiryDate != null
        ? int.parse(_expiryDate!.split('/')[0])
        : DateTime.now().month;

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Expiry (Month/Year)'),
              content: SizedBox(
                height: 300,
                width: 300,
                child: Column(
                  children: [
                    Expanded(
                      child: YearPicker(
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 10),
                        ),
                        selectedDate: DateTime(selectedYear, selectedMonth),
                        onChanged: (DateTime dateTime) {
                          setDialogState(() {
                            selectedYear = dateTime.year;
                          });
                        },
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2,
                            ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          return InkWell(
                            onTap: () {
                              Navigator.pop(
                                context,
                                DateTime(selectedYear, month),
                              );
                            },
                            child: Center(
                              child: Text(
                                DateFormat('MMM').format(DateTime(0, month)),
                                style: TextStyle(
                                  fontWeight: selectedMonth == month
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selectedMonth == month
                                      ? Colors.blue
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
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
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expiryDate = DateFormat('MM/yy').format(picked);
        _expiryController.text = _expiryDate!;
      });
    }
  }

  DateTime _parseMMYY(String mmyy) {
    try {
      final parts = mmyy.split('/');
      final month = int.parse(parts[0]);
      final year = 2000 + int.parse(parts[1]);
      // Return the LAST day of that month for correctness
      return DateTime(year, month + 1, 0);
    } catch (e) {
      return DateTime.now().add(const Duration(days: 30));
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (!isEditMode && _expiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select expiry date')),
        );
        return;
      }

      if (_selectedProductId == null || _selectedVolumeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select product and volume')),
        );
        return;
      }

      double? price = _isManualPrice
          ? double.tryParse(_manualPriceController.text)
          : _selectedPrice;

      final int originalQuantity = widget.initialData?['originalQuantity'] ?? 0;
      final int remainingQuantity =
          widget.initialData?['remainingQuantity'] ?? 0;
      final int taken = isEditMode ? (originalQuantity - remainingQuantity) : 0;
      final bool isStockTaken = taken > 0;

      // If stock is taken, we must use the original price if something went wrong with current selection
      if (isEditMode && isStockTaken) {
        price ??= widget.initialData!['selectedPrice'].toDouble();
      }

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
        'quantity': quantity,
        'selectedPrice': price,
        'salePercentage': saleVal,
        'shortage_fulfillment': _shortageFulfillment,
      };

      // IMMUTABLE FIELDS: ONLY FOR CREATION
      if (!isEditMode) {
        excessData['product'] = _selectedProductId!;
        excessData['volume'] = _selectedVolumeId!;
        excessData['expiryDate'] = _expiryDate!;
      }

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    final selectedProduct = _selectedProductId != null
        ? productProvider.products.firstWhere(
            (p) => p['_id'] == _selectedProductId,
            orElse: () => null,
          )
        : null;

    final volumes = selectedProduct?['volumes'] as List<dynamic>? ?? [];

    if (volumes.length == 1 && _selectedVolumeId != volumes[0]['volumeId']) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedVolumeId = volumes[0]['volumeId'];
          _selectedPrice = null;
        });
      });
    }

    final currentVolume = volumes.firstWhere(
      (v) => v['volumeId'] == _selectedVolumeId,
      orElse: () => null,
    );
    final List<String> prices =
        (currentVolume?['prices'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // Removed auto-activation logic from build to respect user's manual toggle

    final int originalQuantity = widget.initialData?['originalQuantity'] ?? 0;
    final int remainingQuantity = widget.initialData?['remainingQuantity'] ?? 0;
    final int taken = isEditMode ? (originalQuantity - remainingQuantity) : 0;
    final bool isStockTaken = taken > 0;

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
                    if (isEditMode) ...[
                      if (widget.initialData!['status'] == 'rejected' &&
                          widget.initialData!['rejectionReason'] != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'REJECTION REASON:',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.initialData!['rejectionReason'],
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product: ${widget.initialData!['product']['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (!isEditMode) ...[
                      SearchableDropdown(
                        value: _selectedProductId,
                        labelText: 'Product',
                        items: productProvider.products
                            .map<DropdownItem>(
                              (product) => DropdownItem(
                                id: product['_id'],
                                displayText: product['name'],
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProductId = value;
                            _selectedVolumeId = null;
                            _selectedPrice = null;
                            // _isManualPrice stays as is
                          });
                        },
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      if (volumes.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedVolumeId,
                          decoration: const InputDecoration(
                            labelText: 'Volume',
                          ),
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
                              // _isManualPrice stays as is
                            });
                          },
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],

                    if (_selectedVolumeId != null && !isStockTaken) ...[
                      const Text(
                        'Price (coins)',
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
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final qty = int.tryParse(v);
                        if (qty == null || qty <= 0) return 'Invalid quantity';
                        if (isEditMode) {
                          if (qty > originalQuantity) {
                            return 'Quantity can only be decreased';
                          }
                          if (qty < taken) {
                            return 'Cannot be less than $taken (already taken)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    if (!isEditMode) ...[
                      TextFormField(
                        controller: _expiryController,
                        readOnly: true,
                        onTap: _selectExpiryDate,
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date (MM/YY)',
                          hintText: 'Select Expiry Date',
                          suffixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (!isStockTaken) ...[
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
                                'The current system sale is ${context.read<SettingsProvider>().minCommission}% if you would like to provide a higher sale enter its value.',
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
                                validator: (v) => null,
                              ),
                            ],
                          ),
                        ),
                    ],

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
