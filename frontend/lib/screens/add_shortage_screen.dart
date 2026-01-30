import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/shortage_provider.dart';
import '../widgets/async_searchable_dropdown.dart';

class AddShortageScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddShortageScreen({super.key, this.initialData});

  @override
  State<AddShortageScreen> createState() => _AddShortageScreenState();
}

class _AddShortageScreenState extends State<AddShortageScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProductId;
  String? _selectedVolumeId;
  final TextEditingController _quantityController = TextEditingController();

  // For volumes related to selected product
  List<dynamic> _availableVolumes = [];

  bool get isEditMode => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final data = widget.initialData!;
      setState(() {
        _selectedProductId = data['product']['_id'];
        _selectedVolumeId = data['volume']['_id'];
        _quantityController.text = data['quantity'].toString();
        // Since it's edit mode, we might need volume names etc.
        // But the screen already shows product/volume names in a container for edit mode.
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProductId == null || _selectedVolumeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select product and volume')),
        );
        return;
      }

      final quantity = int.tryParse(_quantityController.text);
      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid quantity')),
        );
        return;
      }

      final shortageData = {
        'product': _selectedProductId,
        'volume': _selectedVolumeId,
        'quantity': quantity,
      };

      final success = isEditMode
          ? await Provider.of<ShortageProvider>(
              context,
              listen: false,
            ).updateShortage(widget.initialData!['_id'], shortageData)
          : await Provider.of<ShortageProvider>(
              context,
              listen: false,
            ).createShortage(shortageData);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? 'Shortage updated successfully'
                    : 'Shortage added successfully',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<ShortageProvider>(
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

    // Auto-select volume if only one
    if (_availableVolumes.length == 1 &&
        _selectedVolumeId != _availableVolumes[0]['volumeId']) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedVolumeId = _availableVolumes[0]['volumeId'];
        });
      });
    }

    final int quantity = widget.initialData?['quantity'] ?? 0;
    final int remainingQuantity = widget.initialData?['remainingQuantity'] ?? 0;
    final int fulfilled = isEditMode ? (quantity - remainingQuantity) : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Shortage' : 'Add Shortage'),
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
                            Text(
                              'Volume: ${widget.initialData!['volume']['name']}',
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Product Searchable Dropdown (Creation only)
                    if (!isEditMode) ...[
                      AsyncSearchableDropdown(
                        value: _selectedProductId,
                        labelText: 'Product',
                        onChanged: (product) {
                          setState(() {
                            _selectedProductId = product?['_id'];
                            _selectedVolumeId = null;
                            _availableVolumes = product?['volumes'] ?? [];
                          });
                        },
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Volume Dropdown (Creation only)
                    if (!isEditMode && _availableVolumes.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedVolumeId,
                        decoration: const InputDecoration(labelText: 'Volume'),
                        items: _availableVolumes.map<DropdownMenuItem<String>>((
                          v,
                        ) {
                          return DropdownMenuItem(
                            value: v['volumeId'],
                            child: Text(v['volumeName']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVolumeId = value;
                          });
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity Needed',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final qty = int.tryParse(v);
                        if (qty == null || qty < 1) return 'Invalid quantity';
                        if (isEditMode) {
                          if (qty > quantity) {
                            return 'Quantity can only be decreased';
                          }
                          if (qty < fulfilled) {
                            return 'Cannot be less than $fulfilled (already fulfilled)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            Provider.of<ShortageProvider>(context).isLoading
                            ? null
                            : _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red[800],
                          foregroundColor: Colors.white,
                        ),
                        child: Provider.of<ShortageProvider>(context).isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                isEditMode
                                    ? 'Update Shortage'
                                    : 'Submit Shortage',
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
