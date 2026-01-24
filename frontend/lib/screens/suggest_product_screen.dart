import 'package:flutter/material.dart';
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
  final _ingredientController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _categoryController = TextEditingController();
  final _volumeController = TextEditingController();
  final _valueController = TextEditingController(text: '1');
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientController.dispose();
    _manufacturerController.dispose();
    _categoryController.dispose();
    _volumeController.dispose();
    _valueController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await Provider.of<ProductProvider>(context, listen: false)
          .suggestProduct({
            'name': _nameController.text.trim(),
            'activeIngredient': _ingredientController.text.trim(),
            'manufacturerName': _manufacturerController.text.trim(),
            'categoryName': _categoryController.text.trim(),
            'volumeName': _volumeController.text.trim(),
            'value': int.parse(_valueController.text),
            'price': double.parse(_priceController.text),
          });

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
                controller: _ingredientController,
                decoration: const InputDecoration(
                  labelText: 'Active Ingredient',
                  helperText: 'e.g. Paracetamol',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _manufacturerController,
                decoration: const InputDecoration(
                  labelText: 'Manufacturer',
                  helperText: 'e.g. GlaxoSmithKline',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  helperText: 'e.g. Analgesic',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _volumeController,
                decoration: const InputDecoration(
                  labelText: 'Volume Name',
                  helperText: 'e.g. Box, Bottle',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Units per Volume',
                  helperText: 'e.g. 24 (tablets per box)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Store Price (EGP)',
                ),
                keyboardType: TextInputType.number,
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
