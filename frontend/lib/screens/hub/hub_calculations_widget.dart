import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hub_provider.dart';
import '../../l10n/generated/app_localizations.dart';

class HubCalculationsWidget extends StatefulWidget {
  const HubCalculationsWidget({super.key});

  @override
  State<HubCalculationsWidget> createState() => _HubCalculationsWidgetState();
}

class _HubCalculationsWidgetState extends State<HubCalculationsWidget> {
  int _currentStep = 0;
  String? _selectedPharmacyId;
  final Set<String> _selectedExcessIds = {};

  // Calculation variables
  double alpha = 0.7; // Default 0.7
  double beta = 0.0; // Default 0.0

  // Quick Mode variables
  bool _isQuickMode = false;
  double _inputGamma = 0.85; // For Quick mode
  double _inputLossPercentage = 0.05; // Loss Ratio input for Quick mode

  final Map<String, int> _selectedQuantities = {};
  final Map<String, double> _invoiceSales = {};

  // Calculation variables
  int _calculationTypeIndex = 0;
  double _inputSildenafilRatio = 0.5; // If calculating R or Y
  double _inputNeededRevenue = 0.07; // If calculating Z or Y

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<HubProvider>(
        context,
        listen: false,
      ).fetchPharmaciesList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hubProvider = Provider.of<HubProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hubCalculationsTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(l10n.pharmacyMode),
                  icon: const Icon(Icons.store),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(l10n.quickMode),
                  icon: const Icon(Icons.bolt),
                ),
              ],
              selected: {_isQuickMode},
              onSelectionChanged: (val) {
                setState(() {
                  _isQuickMode = val.first;
                  _currentStep = _isQuickMode ? 2 : 0;
                  // Safety: If switching back to Pharmacy mode and Y was selected, reset to R
                  if (!_isQuickMode && _calculationTypeIndex == 2) {
                    _calculationTypeIndex = 0;
                  }
                });
              },
            ),
          ),
        ),
      ),
      body: hubProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCurrentStep(l10n, hubProvider),
      bottomNavigationBar: _isQuickMode ? null : _buildBottomActions(l10n),
    );
  }

  Widget _buildCurrentStep(AppLocalizations l10n, HubProvider hubProvider) {
    switch (_currentStep) {
      case 0:
        return _buildPharmacySelection(l10n, hubProvider);
      case 1:
        return _buildExcessSelection(l10n, hubProvider);
      case 2:
        return _buildCalculationsView(l10n, hubProvider);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPharmacySelection(
    AppLocalizations l10n,
    HubProvider hubProvider,
  ) {
    return ListView.builder(
      itemCount: hubProvider.pharmaciesList.length,
      itemBuilder: (context, index) {
        final ph = hubProvider.pharmaciesList[index];
        return ListTile(
          title: Text(ph['name']),
          subtitle: Text(ph['address'] ?? ''),
          selected: _selectedPharmacyId == ph['_id'],
          trailing: _selectedPharmacyId == ph['_id']
              ? const Icon(Icons.check_circle, color: Colors.teal)
              : null,
          onTap: () {
            setState(() {
              _selectedPharmacyId = ph['_id'];
            });
          },
        );
      },
    );
  }

  Widget _buildExcessSelection(AppLocalizations l10n, HubProvider hubProvider) {
    if (hubProvider.selectedPharmacyExcesses.isEmpty) {
      return Center(child: Text(l10n.noExcessesFound));
    }
    return ListView.builder(
      itemCount: hubProvider.selectedPharmacyExcesses.length,
      itemBuilder: (context, index) {
        final excess = hubProvider.selectedPharmacyExcesses[index];
        final isSelected = _selectedExcessIds.contains(
          excess['_id'].toString(),
        );
        return CheckboxListTile(
          title: Text(excess['product']['name']),
          subtitle: Text(
            '${l10n.labelVolume}: ${excess['volume']['name']} | ${l10n.labelPrice}: ${excess['selectedPrice']} | %${excess['salePercentage']} | ${l10n.labelQuantity}: ${excess['remainingQuantity']}',
          ),
          value: isSelected,
          onChanged: (val) {
            setState(() {
              final id = excess['_id'].toString();
              if (val == true) {
                _selectedExcessIds.add(id);
                _selectedQuantities[id] = excess['remainingQuantity'] ?? 0;
                _invoiceSales[id] = (excess['salePercentage'] ?? 0).toDouble();
              } else {
                _selectedExcessIds.remove(id);
                _selectedQuantities.remove(id);
                _invoiceSales.remove(id);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildCalculationsView(
    AppLocalizations l10n,
    HubProvider hubProvider,
  ) {
    // C calculation
    // the revenue from normal products
    double C = (0.1) / (1.0 - beta);

    // Sum Calculations
    double A = 0; // Sum(x[i] * (1 - gamma[i]))
    double B = 0; // Sum(x[i] * y[i])
    double X = 0; // Sum(x[i])

    final selectedExcesses = hubProvider.selectedPharmacyExcesses.where(
      (e) => _selectedExcessIds.contains(e['_id'].toString()),
    );

    for (var excess in selectedExcesses) {
      final id = excess['_id'].toString();
      int qty = _selectedQuantities[id] ?? excess['remainingQuantity'] ?? 0;
      double price = (excess['selectedPrice'] as num).toDouble();
      double xi = price * qty;

      double gamma_i = (excess['salePercentage'] ?? 0) / 100.0;
      // yi (Loss Percentage) = (salePercentage - _invoiceSales) / 100
      double itemInvoiceSale =
          _invoiceSales[id] ?? (excess['salePercentage'] ?? 0).toDouble();
      //yi should be a postive value for loss
      double yi = (itemInvoiceSale - (excess['salePercentage'] ?? 0)) / 100.0;
      A += (1.0 - gamma_i) * xi;
      B += yi * xi;
      X += xi;
    }

    double resultValue = 0;

    if (_isQuickMode) {
      double gamma_i = _inputGamma;
      // For quick mode, we simulate a single item structure
      // X = 1, A = (1 - gamma), B = y
      if (_calculationTypeIndex == 0) {
        // R = ((1 - gamma) * (z * alpha + (1 - z) * C) - y) / 1
        resultValue =
            ((1.0 - gamma_i) *
                (_inputSildenafilRatio * alpha +
                    (1.0 - _inputSildenafilRatio) * C)) -
            _inputLossPercentage;
      } else if (_calculationTypeIndex == 1) {
        // z = ((R * 1 + y) / (1 - gamma) - C) / (alpha - C)
        if (alpha - C != 0 && (1.0 - gamma_i) != 0) {
          resultValue =
              ((_inputNeededRevenue + _inputLossPercentage) / (1.0 - gamma_i) -
                  C) /
              (alpha - C);
        }
      } else if (_calculationTypeIndex == 2) {
        // y = (1 - gamma) * (z * alpha + (1 - z) * C) - R
        resultValue =
            ((1.0 - gamma_i) *
                (_inputSildenafilRatio * alpha +
                    (1.0 - _inputSildenafilRatio) * C)) -
            _inputNeededRevenue;
      }
    } else {
      if (_calculationTypeIndex == 0) {
        // R = (A * (z * alpha + (1 - z) * C) - B) / X
        if (X != 0) {
          resultValue =
              (A *
                      (_inputSildenafilRatio * alpha +
                          (1.0 - _inputSildenafilRatio) * C) -
                  B) /
              X;
        }
      } else if (_calculationTypeIndex == 1) {
        // z = ((R * X + B) / A - C) / (alpha - C)
        if (A != 0 && (alpha - C) != 0) {
          resultValue = ((_inputNeededRevenue * X + B) / A - C) / (alpha - C);
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlobalInputs(l10n),
          if (!_isQuickMode) ...[
            const Divider(height: 32),
            Text(
              "${l10n.selectedItems} (${_selectedExcessIds.length})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildItemsTable(l10n, hubProvider),
          ],
          const SizedBox(height: 24),
          _buildResultDisplay(l10n, resultValue),
        ],
      ),
    );
  }

  Widget _buildGlobalInputs(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: l10n.calculationType),
                value: _calculationTypeIndex,
                items: [
                  DropdownMenuItem(value: 0, child: Text(l10n.calculateR)),
                  DropdownMenuItem(value: 1, child: Text(l10n.calculateZ)),
                  if (_isQuickMode)
                    DropdownMenuItem(value: 2, child: Text(l10n.calculateY)),
                ],
                onChanged: (val) => setState(() {
                  _calculationTypeIndex = val!;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: alpha.toString(),
                decoration: InputDecoration(labelText: l10n.alpha),
                keyboardType: TextInputType.number,
                onChanged: (val) => setState(() {
                  alpha = double.tryParse(val) ?? 0.7;
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: beta.toString(),
                decoration: InputDecoration(labelText: l10n.beta),
                keyboardType: TextInputType.number,
                onChanged: (val) => setState(() {
                  beta = double.tryParse(val) ?? 0.0;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_calculationTypeIndex != 1) // Hidden if calculating Z
          TextFormField(
            initialValue: _inputSildenafilRatio.toString(),
            decoration: InputDecoration(labelText: l10n.zValue),
            keyboardType: TextInputType.number,
            onChanged: (val) => setState(() {
              _inputSildenafilRatio = double.tryParse(val) ?? 0.5;
            }),
          ),
        if (_calculationTypeIndex != 0) // Hidden if calculating R
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextFormField(
              initialValue: _inputNeededRevenue.toString(),
              decoration: InputDecoration(labelText: l10n.rValue),
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() {
                _inputNeededRevenue = double.tryParse(val) ?? 0.07;
              }),
            ),
          ),
        if (_isQuickMode) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextFormField(
              initialValue: _inputGamma.toString(),
              decoration: InputDecoration(labelText: l10n.gammaValue),
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() {
                _inputGamma = double.tryParse(val) ?? 0.2;
              }),
            ),
          ),
          if (_calculationTypeIndex != 2) // Hidden if calculating y
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextFormField(
                initialValue: _inputLossPercentage.toString(),
                decoration: InputDecoration(labelText: l10n.lossRatio),
                keyboardType: TextInputType.number,
                onChanged: (val) => setState(() {
                  _inputLossPercentage = double.tryParse(val) ?? 0.05;
                }),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildItemsTable(AppLocalizations l10n, HubProvider hubProvider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 32,
        ),
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
          border: TableBorder.all(color: Colors.grey.shade300),
          columns: [
            DataColumn(
              label: Text(
                l10n.labelProduct,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                l10n.labelPrice,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                l10n.labelSalePercentage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                l10n.labelMaxQuantity,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                l10n.labelQuantity,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                l10n.labelInvoiceSalePercentage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                l10n.labelLossPercentage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: hubProvider.selectedPharmacyExcesses
              .where((e) => _selectedExcessIds.contains(e['_id'].toString()))
              .map((item) {
                final id = item['_id'].toString();
                final maxQty = item['remainingQuantity'] ?? 0;
                final salePercentage = (item['salePercentage'] ?? 0).toDouble();
                final invoiceSale = _invoiceSales[id] ?? salePercentage;
                final lossPercentage = salePercentage - invoiceSale;

                return DataRow(
                  cells: [
                    DataCell(Text(item['product']['name'])),
                    DataCell(Text(item['selectedPrice'].toString())),
                    DataCell(Text("$salePercentage%")),
                    DataCell(Text(maxQty.toString())),
                    DataCell(
                      SizedBox(
                        width: 60,
                        child: TextFormField(
                          initialValue: (_selectedQuantities[id] ?? maxQty)
                              .toString(),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (val) {
                            setState(() {
                              int newQty = int.tryParse(val) ?? 0;
                              if (newQty > maxQty) newQty = maxQty;
                              if (newQty < 0) newQty = 0;
                              _selectedQuantities[id] = newQty;
                            });
                          },
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 60,
                        child: TextFormField(
                          initialValue: invoiceSale.toString(),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _invoiceSales[id] =
                                  double.tryParse(val) ?? salePercentage;
                            });
                          },
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        "${lossPercentage.toStringAsFixed(1)}%",
                        style: TextStyle(
                          color: lossPercentage > 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              })
              .toList(),
        ),
      ),
    );
  }

  Widget _buildResultDisplay(AppLocalizations l10n, double result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        children: [
          Text(
            _calculationTypeIndex == 0
                ? l10n.totalRevenueRatio
                : _calculationTypeIndex == 1
                ? l10n.totalSeldinafilRatio
                : l10n.totalLossRatio,
            style: TextStyle(
              color: Colors.teal.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.toStringAsFixed(4),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              child: Text(l10n.actionBack),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: (_currentStep == 0 && _selectedPharmacyId == null)
                ? null
                : (_currentStep == 1 && _selectedExcessIds.isEmpty)
                ? null
                : () {
                    if (_currentStep == 0) {
                      Provider.of<HubProvider>(
                        context,
                        listen: false,
                      ).fetchPharmacyExcesses(_selectedPharmacyId!);
                      setState(() => _currentStep = 1);
                    } else if (_currentStep == 1) {
                      setState(() => _currentStep = 2);
                    } else {
                      Navigator.pop(context);
                    }
                  },
            child: Text(
              _currentStep < 2 ? l10n.confirmSelection : l10n.actionDone,
            ),
          ),
        ],
      ),
    );
  }
}
