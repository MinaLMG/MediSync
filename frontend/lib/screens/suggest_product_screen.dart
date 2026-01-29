import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

class SuggestProductScreen extends StatefulWidget {
  const SuggestProductScreen({super.key});

  @override
  State<SuggestProductScreen> createState() => _SuggestProductScreenState();
}

class _SuggestProductScreenState extends State<SuggestProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final price = double.tryParse(_priceController.text);
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid price')),
        );
        return;
      }

      final success = await Provider.of<ProductProvider>(
        context,
        listen: false,
      ).suggestProduct({'name': _nameController.text.trim(), 'price': price});
      // ... rest of the method is unchanged but need context for tool

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product suggestion submitted successfully!'),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<ProductProvider>(
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
    final isLoading = Provider.of<ProductProvider>(context).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Suggest New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  helperText: 'e.g. Panadol 500mg',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Store Price (coins)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Submit Suggestion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
