import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/product_provider.dart';
import '../../providers/excess_provider.dart';
import '../../widgets/async_searchable_dropdown.dart';
import '../../l10n/generated/app_localizations.dart';

class HubPurchaseItemWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final Map<String, dynamic>? initialData;
  final bool readOnly;
  const HubPurchaseItemWidget({
    super.key,
    required this.onAdd,
    this.initialData,
    this.readOnly = false,
  });

  @override
  State<HubPurchaseItemWidget> createState() => _HubPurchaseItemWidgetState();
}

class _HubPurchaseItemWidgetState extends State<HubPurchaseItemWidget> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProductId;
  String? _selectedProductName;
  String? _selectedVolumeId;
  String? _selectedVolumeName;
  double? _selectedSellingPrice;
  bool _isManualPrice = false;
  final TextEditingController _manualPriceController = TextEditingController();

  final TextEditingController _buyingPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _saleValueController =
      TextEditingController(); // Gamma
  final TextEditingController _expiryController = TextEditingController();
  String? _expiryDate;
  String? _itemId;
  String? _excessId;

  List<dynamic> _availableVolumes = [];
  bool _isFetchingVolumes = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _selectedProductId = data['product'];
      _selectedProductName = data['product_name'];
      _selectedVolumeId = data['volume'];
      _selectedVolumeName = data['volume_name'];

      _quantityController.text = (data['quantity'] ?? '').toString();
      _buyingPriceController.text = (data['buyingPrice'] ?? '').toString();

      double sp = (data['sellingPrice'] as num?)?.toDouble() ?? 0.0;
      _selectedSellingPrice = sp;
      _manualPriceController.text = sp.toString();

      _saleValueController.text = (data['salePercentage'] ?? '').toString();
      _expiryDate = data['expiryDate'];
      _expiryController.text = _expiryDate ?? '';
      _itemId = data['_id'];
      _excessId = data['excess'];

      if (_selectedProductId != null) {
        _fetchVolumesForEdit();
      }
    }
  }

  Future<void> _fetchVolumesForEdit() async {
    setState(() => _isFetchingVolumes = true);
    try {
      final fullProduct = await Provider.of<ProductProvider>(
        context,
        listen: false,
      ).fetchProductDetails(_selectedProductId!);

      if (mounted && fullProduct != null) {
        setState(() {
          _availableVolumes = fullProduct['volumes'] ?? [];
          // Check if selling price is correct
          if (_selectedVolumeId != null) {
            final vol = _availableVolumes.firstWhere(
              (v) => v['volumeId'].toString() == _selectedVolumeId.toString(),
              orElse: () => null,
            );
            if (vol != null) {
              final prices =
                  (vol['prices'] as List<dynamic>?)
                      ?.map((e) => double.tryParse(e.toString()) ?? 0.0)
                      .toList() ??
                  [];
              if (!prices.contains(_selectedSellingPrice)) {
                _isManualPrice = true;
              } else {
                _isManualPrice = false;
              }
            }
          }
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isFetchingVolumes = false);
      _fetchMarketInsight();
    }
  }

  @override
  void dispose() {
    _manualPriceController.dispose();
    _buyingPriceController.dispose();
    _quantityController.dispose();
    _saleValueController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final l10n = AppLocalizations.of(context)!;
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
          title: Text(l10n.labelSelectExpiryMonthYear),
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
                            DateFormat(
                              'MMM',
                              l10n.localeName,
                            ).format(DateTime(0, month)),
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
              child: Text(l10n.actionCancel),
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

  void _fetchMarketInsight() {
    if (_selectedProductId != null && _selectedVolumeId != null) {
      double? price = _isManualPrice
          ? double.tryParse(_manualPriceController.text)
          : _selectedSellingPrice;
      if (price != null && price > 0) {
        Provider.of<ExcessProvider>(
          context,
          listen: false,
        ).fetchMarketInsight(_selectedProductId!, _selectedVolumeId!, price);
      }
    }
  }

  void _submitForm() {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      if (_selectedProductId == null || _selectedVolumeId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.msgSelectProductVolume)));
        return;
      }

      final qty = int.tryParse(_quantityController.text) ?? 0;
      final bp = double.tryParse(_buyingPriceController.text) ?? 0;

      double? sp = _isManualPrice
          ? double.tryParse(_manualPriceController.text)
          : _selectedSellingPrice;

      if (sp == null || sp <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.msgPleaseEnterValidPrice)));
        return;
      }

      double? saleVal;
      final saleValText = _saleValueController.text;
      if (saleValText.isNotEmpty) {
        saleVal = double.tryParse(saleValText);
        if (saleVal == null || saleVal < 0 || saleVal > 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.msgInvalidSalePercentage)),
          );
          return;
        }
      } else {
        saleVal = 0;
      }

      widget.onAdd({
        '_id': _itemId,
        'excess': _excessId,
        'product': _selectedProductId,
        'product_name': _selectedProductName,
        'volume': _selectedVolumeId,
        'volume_name': _selectedVolumeName,
        'quantity': qty,
        'buyingPrice': bp,
        'sellingPrice': sp,
        'salePercentage': saleVal,
        'expiryDate': _expiryDate,
        'total': qty * bp,
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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

    final isEdit = widget.initialData != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? "Edit Invoice Item" : "Add Product to Invoice",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Product Search
              AsyncSearchableDropdown(
                value: _selectedProductId,
                labelText: l10n.labelName,
                onChanged: (product) async {
                  if (product == null) {
                    setState(() {
                      _selectedProductId = null;
                      _selectedProductName = null;
                      _selectedSellingPrice = null;
                      _availableVolumes = [];
                      _selectedVolumeId = null;
                      _selectedVolumeName = null;
                    });
                    return;
                  }
                  setState(() {
                    _selectedProductId = product['_id'];
                    _selectedProductName = product['name'];
                    _selectedSellingPrice = null;
                    _availableVolumes = [];
                    _selectedVolumeId = null;
                    _selectedVolumeName = null;
                    _isFetchingVolumes = true;
                  });
                  try {
                    final fullProduct = await Provider.of<ProductProvider>(
                      context,
                      listen: false,
                    ).fetchProductDetails(product['_id']);
                    if (mounted) {
                      setState(() {
                        if (fullProduct != null) {
                          _availableVolumes = fullProduct['volumes'] ?? [];
                          if (_availableVolumes.isNotEmpty) {
                            final firstVol = _availableVolumes[0];
                            _selectedVolumeId = firstVol['volumeId'].toString();
                            _selectedVolumeName = firstVol['volumeName'];
                          }
                        }
                      });
                    }
                  } catch (e) {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.msgErrorLoadingVolumes)),
                      );
                  } finally {
                    if (mounted) setState(() => _isFetchingVolumes = false);
                    _fetchMarketInsight();
                  }
                },
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Volume Dropdown
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'volume_dropdown_purchase_${_selectedProductId ?? "none"}',
                ),
                value: _selectedVolumeId,
                decoration: InputDecoration(
                  labelText: l10n.labelVolume,
                  hintText: _isFetchingVolumes
                      ? l10n.hintLoading
                      : l10n.hintSelectVolume,
                  suffixIcon: _isFetchingVolumes
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
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
                    (widget.readOnly ||
                        _isFetchingVolumes ||
                        _selectedProductId == null)
                    ? null
                    : (value) {
                        final vol = _availableVolumes.firstWhere(
                          (v) => v['volumeId'].toString() == value,
                          orElse: () => null,
                        );
                        setState(() {
                          _selectedVolumeId = value;
                          _selectedVolumeName = vol?['volumeName'];
                          _selectedSellingPrice = null;
                          _fetchMarketInsight();
                        });
                      },
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Buying Price
              TextFormField(
                controller: _buyingPriceController,
                decoration: const InputDecoration(labelText: "Buying Price"),
                keyboardType: TextInputType.number,
                enabled: !widget.readOnly,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Selling Price Selection (Excess Pricing)
              if (_selectedVolumeId != null) ...[
                Text(
                  "Selling Price (for Excess)",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (!_isManualPrice)
                  DropdownButtonFormField<double>(
                    value: _selectedSellingPrice,
                    decoration: InputDecoration(
                      labelText: l10n.labelSelectPrice,
                    ),
                    items: prices
                        .map(
                          (p) => DropdownMenuItem(
                            value: double.parse(p),
                            child: Text(p),
                          ),
                        )
                        .toList(),
                    onChanged: (widget.readOnly)
                        ? null
                        : (value) => setState(() {
                            _selectedSellingPrice = value;
                            _fetchMarketInsight();
                          }),
                  ),
                Row(
                  children: [
                    Checkbox(
                      value: _isManualPrice,
                      onChanged: (widget.readOnly)
                          ? null
                          : (val) => setState(() {
                              _isManualPrice = val!;
                              if (_isManualPrice) _selectedSellingPrice = null;
                            }),
                    ),
                    const Text('Enter Manual Selling Price'),
                  ],
                ),
                if (_isManualPrice)
                  TextFormField(
                    controller: _manualPriceController,
                    decoration: InputDecoration(
                      labelText: l10n.labelManualPrice,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (v) => _fetchMarketInsight(),
                  ),
                const SizedBox(height: 16),
              ],

              // Market Insight (reuse logic)
              _buildMarketInsightTable(l10n),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: l10n.labelQuantity),
                keyboardType: TextInputType.number,
                enabled: !widget.readOnly,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final qty = int.tryParse(v);
                  if (qty == null || qty <= 0) return 'Invalid quantity';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Expiry Date
              TextFormField(
                controller: _expiryController,
                readOnly: true,
                onTap: _selectExpiryDate,
                decoration: InputDecoration(
                  labelText: l10n.labelExpiryDateMMYY,
                  hintText: l10n.hintSelectExpiryDate,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Sale Percentage (Gamma)
              TextFormField(
                controller: _saleValueController,
                decoration: InputDecoration(
                  labelText: l10n.labelPercentageValue,
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                enabled: !widget.readOnly,
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.readOnly ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.readOnly
                        ? Colors.grey
                        : Colors.blue[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.readOnly
                        ? "View Mode"
                        : (isEdit ? "Save Changes" : "Add to Invoice"),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketInsightTable(AppLocalizations l10n) {
    // Re-implementing market insight table locally since reuse is hard without extracting to another widget
    final excessProvider = Provider.of<ExcessProvider>(context);
    final insights = excessProvider.marketInsight;

    if (_selectedProductId == null || _selectedVolumeId == null) {
      return const SizedBox.shrink();
    }

    double? price = _isManualPrice
        ? double.tryParse(_manualPriceController.text)
        : _selectedSellingPrice;

    if (price == null || price <= 0) return const SizedBox.shrink();

    if (excessProvider.isLoading && insights.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (insights.isEmpty) {
      return Text(
        l10n.msgNoMarketInsight,
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    return Card(
      color: Colors.blue[50]!.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.labelMarketInsight,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const Divider(),
            DataTable(
              headingRowHeight: 30,
              dataRowHeight: 35,
              columns: [
                DataColumn(label: Text(l10n.labelCompetitorExpiry)),
                DataColumn(label: Text(l10n.labelCompetitorSale)),
              ],
              rows: insights
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(Text(item['expiryDate'] ?? '-')),
                        DataCell(
                          Text(
                            '${item['salePercentage']}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
