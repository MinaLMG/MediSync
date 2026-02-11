import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/excess_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/async_searchable_dropdown.dart';
import '../l10n/generated/app_localizations.dart';

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
  bool _isSubmitting = false;

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
    final l10n = AppLocalizations.of(context)!;
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
          : _selectedPrice;
      if (price != null && price > 0) {
        Provider.of<ExcessProvider>(
          context,
          listen: false,
        ).fetchMarketInsight(_selectedProductId!, _selectedVolumeId!, price);
      }
    }
  }

  void _submitForm() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      if (!isEditMode && _expiryDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.msgSelectExpiryDate)));
        return;
      }
      if (_selectedProductId == null || _selectedVolumeId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.msgSelectProductVolume)));
        return;
      }

      double? price = _isManualPrice
          ? double.tryParse(_manualPriceController.text)
          : _selectedPrice;
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.msgPleaseEnterValidPrice)));
        return;
      }

      double? saleVal;
      if (!_shortageFulfillment) {
        final saleValText = _saleValueController.text;
        if (saleValText.isNotEmpty) {
          saleVal = double.tryParse(saleValText);
          if (saleVal == null || saleVal < 0 || saleVal > 100) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.msgInvalidSalePercentage)),
            );
            return;
          }
        }
      } else {
        saleVal = 0;
      }

      final quantity = int.tryParse(_quantityController.text);
      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.msgEnterValidQuantity)));
        return;
      }

      setState(() => _isSubmitting = true);

      try {
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
            ).showSnackBar(SnackBar(content: Text(l10n.actionSuccessful)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  Provider.of<ExcessProvider>(
                        context,
                        listen: false,
                      ).errorMessage ??
                      l10n.msgGenericError,
                ),
              ),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
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

    final int originalQuantity = widget.initialData?['originalQuantity'] ?? 0;
    final int remainingQuantity = widget.initialData?['remainingQuantity'] ?? 0;
    final int taken = isEditMode ? (originalQuantity - remainingQuantity) : 0;
    final bool isStockTaken = taken > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? l10n.titleEditExcess : l10n.titleAddExcess),
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
                            '${l10n.labelRejectionReason} ${widget.initialData!['rejectionReason']}',
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
                          l10n.labelProductWithName(
                            widget.initialData!['product']['name'],
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],

                    if (!isEditMode) ...[
                      AsyncSearchableDropdown(
                        value: _selectedProductId,
                        labelText: l10n.labelName,
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
                                SnackBar(
                                  content: Text(l10n.msgErrorLoadingVolumes),
                                ),
                              );
                          } finally {
                            if (mounted)
                              setState(() => _isFetchingVolumes = false);
                            _fetchMarketInsight();
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
                                _fetchMarketInsight();
                              }),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_selectedVolumeId != null && !isStockTaken) ...[
                      Text(
                        l10n.labelPriceCoins,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (!_isManualPrice)
                        DropdownButtonFormField<double>(
                          key: ValueKey(
                            'price_dropdown_${_selectedVolumeId ?? "none"}',
                          ),
                          value: _selectedPrice,
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
                          onChanged: (value) => setState(() {
                            _selectedPrice = value;
                            _fetchMarketInsight();
                          }),
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
                          decoration: InputDecoration(
                            labelText: l10n.labelManualPrice,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          onChanged: (v) => _fetchMarketInsight(),
                        ),
                      const SizedBox(height: 16),
                    ],

                    _buildMarketInsightTable(l10n),

                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: l10n.labelQuantity,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final qty = int.tryParse(v);
                        if (qty == null || qty <= 0) return 'Invalid quantity';
                        if (isEditMode) {
                          final int originalQuantity =
                              widget.initialData?['originalQuantity'] ?? 0;
                          final int remainingQuantity =
                              widget.initialData?['remainingQuantity'] ?? 0;
                          final int taken =
                              (originalQuantity - remainingQuantity);
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
                        decoration: InputDecoration(
                          labelText: l10n.labelExpiryDateMMYY,
                          hintText: l10n.hintSelectExpiryDate,
                          suffixIcon: const Icon(Icons.calendar_today),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (!isStockTaken) ...[
                      Text(
                        l10n.labelRequestType,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<bool>(
                        value: _shortageFulfillment,
                        items: [
                          DropdownMenuItem(
                            value: true,
                            child: Text(l10n.labelShortageFulfillment),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text(l10n.labelRealExcess),
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
                      if (!_shortageFulfillment) ...[
                        TextFormField(
                          controller: _saleValueController,
                          decoration: InputDecoration(
                            labelText: l10n.labelPercentageValue,
                            hintText: l10n.labelPercentageValue,
                            border: const OutlineInputBorder(),
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
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.msgSystemCommissionInfo(
                              Provider.of<SettingsProvider>(
                                context,
                              ).minimumCommission.toStringAsFixed(0),
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: _isSubmitting
                            ? ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey,
                                disabledForegroundColor: Colors.white,
                              )
                            : ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.blue[800],
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey,
                                disabledForegroundColor: Colors.white,
                              ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
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

  Widget _buildMarketInsightTable(AppLocalizations l10n) {
    final excessProvider = Provider.of<ExcessProvider>(context);
    final insights = excessProvider.marketInsight;

    // Only show if product and volume are selected
    if (_selectedProductId == null || _selectedVolumeId == null) {
      return const SizedBox.shrink();
    }

    // Check if price is set
    double? price = _isManualPrice
        ? double.tryParse(_manualPriceController.text)
        : _selectedPrice;
    if (price == null || price <= 0) {
      return const SizedBox.shrink();
    }

    if (excessProvider.isLoading && insights.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (insights.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Text(
          l10n.msgNoMarketInsight,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.blue[100]!),
      ),
      color: Colors.blue[50]!.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.query_stats, size: 20, color: Colors.blue[800]),
                const SizedBox(width: 8),
                Text(
                  l10n.labelMarketInsight,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            const Divider(),
            SizedBox(
              width: double.infinity,
              child: DataTable(
                headingRowHeight: 35,
                dataRowHeight: 40,
                columnSpacing: 10,
                horizontalMargin: 8,
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.blue[900],
                ),
                columns: [
                  DataColumn(label: Text(l10n.labelCompetitorExpiry)),
                  DataColumn(label: Text(l10n.labelCompetitorSale)),
                ],
                rows: insights.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          item['expiryDate'] ?? '-',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item['salePercentage']}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
