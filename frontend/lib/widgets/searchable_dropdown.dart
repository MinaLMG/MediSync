import 'package:flutter/material.dart';
import '../utils/search_utils.dart';

class DropdownItem {
  final String id;
  final String displayText;

  DropdownItem({required this.id, required this.displayText});
}

class SearchableDropdown extends StatefulWidget {
  final String? value;
  final List<DropdownItem> items;
  final String labelText;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;
  final IconData? prefixIcon;

  const SearchableDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelText,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  void _showSearchDialog() async {
    final String? selectedId = await showDialog<String>(
      context: context,
      builder: (context) => _SearchDialog(
        items: widget.items,
        title: widget.labelText,
        initialValue: widget.value,
      ),
    );

    if (selectedId != null) {
      widget.onChanged(selectedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.items.firstWhere(
      (item) => item.id == widget.value,
      orElse: () =>
          DropdownItem(id: '', displayText: 'Select ${widget.labelText}'),
    );

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
                            : selectedItem.displayText,
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

class _SearchDialog extends StatefulWidget {
  final List<DropdownItem> items;
  final String title;
  final String? initialValue;

  const _SearchDialog({
    required this.items,
    required this.title,
    this.initialValue,
  });

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<DropdownItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items.where((item) {
        return SearchUtils.matches(item.displayText, query);
      }).toList();
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
            Text(
              'Search ${widget.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Type to search (* for wildcard)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterItems,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SizedBox(
                width: double.maxFinite,
                child: _filteredItems.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No results found'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return ListTile(
                            title: Text(item.displayText),
                            selected: item.id == widget.initialValue,
                            onTap: () => Navigator.pop(context, item.id),
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
    super.dispose();
  }
}
