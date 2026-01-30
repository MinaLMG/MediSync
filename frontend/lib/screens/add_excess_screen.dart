import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/excess_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/async_searchable_dropdown.dart';

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

  String? _expiryDate;
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  bool _shortageFulfillment = false;
  final TextEditingController _saleValueController = TextEditingController();

  List<dynamic> _availableVolumes = [];
  bool _isFetchingVolumes = false;

  bool get isEditMode => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
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
          _expiryDate = data['expiryDate'];
          _expiryController.text = _expiryDate ?? '';
          _quantityController.text = data['originalQuantity'].toString();
          _shortageFulfillment = data['shortage_fulfillment'] ?? true;
          _selectedPrice = data['selectedPrice'].toDouble();
          _manualPriceController.text = _selectedPrice.toString();
          _isManualPrice = true;
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                    onChanged: (DateTime dateTime) =>
                        setDialogState(() => selectedYear = dateTime.year),
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
                        onTap: () => Navigator.pop(
                          context,
                          DateTime(selectedYear, month),
                        ),
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
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = DateFormat('MM/yy').format(picked);
        _expiryController.text = _expiryDate!;
      });
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
          if (saleVal == null || saleVal < 0 || saleVal > 100) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid sale percentage')),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Success')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<ExcessProvider>(
                      context,
                      listen: false,
                    ).errorMessage ??
                    'Error',
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
    final currentVolume =
        _availableVolumes.isNotEmpty && _selectedVolumeId != null
        ? _availableVolumes.firstWhere(
            (v) => v['volumeId'].toString() == _selectedVolumeId.toString(),
            orElse: () => null,
          )
        : null;
    final List<String> prices =
        (currentVolume?['prices'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

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
                          child: Text(
                            'REJECTION REASON: ${widget.initialData!['rejectionReason']}',
                            style: const TextStyle(color: Colors.red),
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
                        child: Text(
                          'Product: ${widget.initialData!['product']['name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],

                    if (!isEditMode) ...[
                      AsyncSearchableDropdown(
                        value: _selectedProductId,
                        labelText: 'Product',
                        onChanged: (product) async {
                          if (product == null) {
                            setState(() {
                              _selectedProductId = null;
                              _selectedPrice = null;
                              _availableVolumes = [];
                              _selectedVolumeId = null;
                            });
                            return;
                          }
                          setState(() {
                            _selectedProductId = product['_id'];
                            _selectedPrice = null;
                            _availableVolumes = [];
                            _selectedVolumeId = null;
                            _isFetchingVolumes = true;
                          });
                          try {
                            final fullProduct =
                                await Provider.of<ProductProvider>(
                                  context,
                                  listen: false,
                                ).fetchProductDetails(product['_id']);
                            if (mounted) {
                              setState(() {
                                if (fullProduct != null) {
                                  _availableVolumes =
                                      fullProduct['volumes'] ?? [];
                                  if (_availableVolumes.isNotEmpty)
                                    _selectedVolumeId =
                                        _availableVolumes[0]['volumeId']
                                            .toString();
                                }
                              });
                            }
                          } catch (e) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error loading volumes'),
                                ),
                              );
                          } finally {
                            if (mounted)
                              setState(() => _isFetchingVolumes = false);
                          }
                        },
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        key: ValueKey(
                          'volume_dropdown_excess_${_selectedProductId ?? "none"}',
                        ),
                        value: _selectedVolumeId,
                        decoration: InputDecoration(
                          labelText: 'Volume',
                          hintText: _isFetchingVolumes
                              ? 'Loading...'
                              : 'Select volume',
                          suffixIcon: _isFetchingVolumes
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        items: _isFetchingVolumes || _selectedProductId == null
                            ? []
                            : _availableVolumes
                                  .map<DropdownMenuItem<String>>(
                                    (v) => DropdownMenuItem(
                                      value: v['volumeId'].toString(),
                                      child: Text(v['volumeName']),
                                    ),
                                  )
                                  .toList(),
                        onChanged:
                            _isFetchingVolumes || _selectedProductId == null
                            ? null
                            : (value) => setState(() {
                                _selectedVolumeId = value;
                                _selectedPrice = null;
                              }),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_selectedVolumeId != null && !isStockTaken) ...[
                      const Text(
                        'Price (coins)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (!_isManualPrice)
                        DropdownButtonFormField<double>(
                          key: ValueKey(
                            'price_dropdown_${_selectedVolumeId ?? "none"}',
                          ),
                          value: _selectedPrice,
                          decoration: const InputDecoration(
                            labelText: 'Select Price',
                          ),
                          items: prices
                              .map(
                                (p) => DropdownMenuItem(
                                  value: double.parse(p),
                                  child: Text(p),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedPrice = value),
                        ),
                      Row(
                        children: [
                          Checkbox(
                            value: _isManualPrice,
                            onChanged: (val) => setState(() {
                              _isManualPrice = val!;
                              if (_isManualPrice) _selectedPrice = null;
                            }),
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
                          if (qty > originalQuantity) return 'Too high';
                          if (qty < taken) return 'Too low';
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
                        onChanged: (val) =>
                            setState(() => _shortageFulfillment = val!),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!_shortageFulfillment)
                        TextFormField(
                          controller: _saleValueController,
                          decoration: const InputDecoration(
                            labelText: 'Percentage Value (%)',
                            border: OutlineInputBorder(),
                            suffixText: '%',
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
