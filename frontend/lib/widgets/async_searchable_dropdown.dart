import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

class AsyncSearchableDropdown extends StatefulWidget {
  final String? value;
  final String labelText;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final FormFieldValidator<String>? validator;
  final IconData? prefixIcon;

  const AsyncSearchableDropdown({
    super.key,
    required this.value,
    required this.labelText,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  @override
  State<AsyncSearchableDropdown> createState() =>
      _AsyncSearchableDropdownState();
}

class _AsyncSearchableDropdownState extends State<AsyncSearchableDropdown> {
  String? _selectedName;

  @override
  void initState() {
    super.initState();
    // In edit mode, we might want to fetch the name if we only have the ID
    // But for simplicity, we assume the parent knows the name or we shows "Selected Product"
  }

  void _showSearchDialog() async {
    final Map<String, dynamic>? selectedProduct =
        await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => const _AsyncSearchDialog(),
        );

    if (selectedProduct != null) {
      setState(() {
        _selectedName = selectedProduct['name'];
      });
      widget.onChanged(selectedProduct);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showSearchDialog,
      child: FormField<String>(
        validator: widget.validator,
        initialValue: widget.value,
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(widget.prefixIcon)
                      : null,
                  border: const OutlineInputBorder(),
                  errorText: state.errorText,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.value == null || widget.value!.isEmpty
                            ? 'Select ${widget.labelText}'
                            : (_selectedName ?? 'Loading...'),
                        style: TextStyle(
                          color: widget.value == null || widget.value!.isEmpty
                              ? Colors.grey[600]
                              : Colors.black87,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AsyncSearchDialog extends StatefulWidget {
  const _AsyncSearchDialog();

  @override
  State<_AsyncSearchDialog> createState() => _AsyncSearchDialogState();
}

class _AsyncSearchDialogState extends State<_AsyncSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _items = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchItems(''); // Load initial items
  }

  void _fetchItems(String query) async {
    setState(() => _isLoading = true);
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final results = await provider.getProductsLite(search: query);
    if (mounted) {
      setState(() {
        _items = results;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchItems(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Search Product',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Type to search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                    ? const Center(child: Text('No results found'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return ListTile(
                            title: Text(item['name']),
                            onTap: () => Navigator.pop(context, item),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
