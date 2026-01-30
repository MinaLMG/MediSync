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

  List<dynamic> _availableVolumes = [];
  bool _isFetchingVolumes = false;

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

                    if (!isEditMode) ...[
                      AsyncSearchableDropdown(
                        value: _selectedProductId,
                        labelText: 'Product',
                        onChanged: (product) async {
                          if (product == null) {
                            setState(() {
                              _selectedProductId = null;
                              _availableVolumes = [];
                              _selectedVolumeId = null;
                            });
                            return;
                          }

                          setState(() {
                            _selectedProductId = product['_id'];
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
                                  if (_availableVolumes.isNotEmpty) {
                                    _selectedVolumeId =
                                        _availableVolumes[0]['volumeId']
                                            .toString();
                                  }
                                }
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error loading volumes'),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isFetchingVolumes = false;
                              });
                            }
                          }
                        },
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        key: ValueKey(
                          'volume_dropdown_${_selectedProductId ?? "none"}',
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
                            : _availableVolumes.map<DropdownMenuItem<String>>((
                                v,
                              ) {
                                return DropdownMenuItem(
                                  value: v['volumeId'].toString(),
                                  child: Text(v['volumeName']),
                                );
                              }).toList(),
                        onChanged:
                            _isFetchingVolumes || _selectedProductId == null
                            ? null
                            : (value) =>
                                  setState(() => _selectedVolumeId = value),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

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
                          if (qty > quantity)
                            return 'Quantity can only be decreased';
                          if (qty < fulfilled)
                            return 'Cannot be less than $fulfilled';
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
