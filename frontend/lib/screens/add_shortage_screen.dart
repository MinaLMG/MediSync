import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/shortage_provider.dart';

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
          _quantityController.text = data['quantity'].toString();
        });
      }
    });
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

      final shortageData = {
        'product': _selectedProductId,
        'volume': _selectedVolumeId,
        'quantity': int.parse(_quantityController.text),
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedVolumeId = volumes[0]['volumeId'];
        });
      });
    }

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
                          });
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    const SizedBox(height: 16),

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity Needed',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
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
