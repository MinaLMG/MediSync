import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../providers/excess_provider.dart';
import '../../providers/app_suggestion_provider.dart';
import '../../l10n/generated/app_localizations.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  bool _isExporting = false;

  Future<void> _exportShoppingSheet() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final excessProvider = Provider.of<ExcessProvider>(
        context,
        listen: false,
      );
      await excessProvider.fetchMarketExcesses(detailed: true);

      if (excessProvider.errorMessage != null) {
        throw Exception(excessProvider.errorMessage);
      }

      final marketData = excessProvider.marketExcesses;
      if (marketData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.msgNoMarketItems),
            ),
          );
        }
        setState(() {
          _isExporting = false;
        });
        return;
      }

      // 1. Flatten the data
      List<Map<String, dynamic>> flattenedData = [];
      for (var productGroup in marketData) {
        String productName = productGroup['product']?['name'] ?? 'Unknown';
        for (var priceGroup in productGroup['prices'] ?? []) {
          double price = (priceGroup['price'] as num?)?.toDouble() ?? 0.0;
          for (var item in priceGroup['items'] ?? []) {
            String expiry = item['expiryDate'] ?? '';
            String formattedExpiry = expiry;
            if (expiry.contains('/') && expiry.length == 5) {
              List<String> parts = expiry.split('/');
              formattedExpiry = "${parts[1]}/${parts[0]}";
            }
            flattenedData.add({
              'productName': productName,
              'quantity': (item['quantity'] as num?)?.toInt() ?? 0,
              'price': price,
              'expiry': formattedExpiry,
              'sale': (item['salePercentage'] as num?)?.toDouble() ?? 0.0,
              'pharmacyName': item['pharmacyName'] ?? '',
              'relatedPharmacyName': item['relatedPharmacyName'] ?? '',
            });
          }
        }
      }

      // 2. Sort by quantity (Descending)
      flattenedData.sort((a, b) => b['quantity'].compareTo(a['quantity']));

      // 3. Generate Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Header row
      sheetObject.appendRow([
        AppLocalizations.of(context)!.labelProductName,
        AppLocalizations.of(context)!.labelPharmacyExport,
        AppLocalizations.of(context)!.labelRelatedPharmacyExport,
        AppLocalizations.of(context)!.labelQuantity,
        AppLocalizations.of(context)!.labelPrice,
        AppLocalizations.of(context)!.labelExpiry,
        AppLocalizations.of(context)!.labelSalePercentage,
      ]);

      // Data rows
      for (var row in flattenedData) {
        sheetObject.appendRow([
          row['productName'],
          row['pharmacyName'],
          row['relatedPharmacyName'],
          row['quantity'],
          row['price'],
          row['expiry'],
          row['sale'],
        ]);
      }

      // 4. Save and Open
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          "${AppLocalizations.of(context)!.labelMarketExcessesExport}_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File('${directory.path}/$fileName');

      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.msgExportSuccess),
            ),
          );
          await OpenFile.open(file.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${AppLocalizations.of(context)!.msgExportError}: $e",
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.adminStatsTitle),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard(
            title: AppLocalizations.of(context)!.adminStatsTitle, // Or "Pharmacies Summary"
            subtitle: 'View financial summary of all pharmacies',
            icon: Icons.account_balance_wallet,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PharmaciesSummaryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            title: AppLocalizations.of(context)!.exportShoppingSheet,
            subtitle: AppLocalizations.of(context)!.labelMarketExcessesExport,
            icon: Icons.file_download,
            onTap: _isExporting ? null : _exportShoppingSheet,
            isLoading: _isExporting,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue[900]),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class PharmaciesSummaryScreen extends StatefulWidget {
  const PharmaciesSummaryScreen({super.key});

  @override
  State<PharmaciesSummaryScreen> createState() =>
      _PharmaciesSummaryScreenState();
}

class _PharmaciesSummaryScreenState extends State<PharmaciesSummaryScreen> {
  List<dynamic> _summary = [];
  bool _isLoading = true;
  DateTime? startDate;
  DateTime? endDate;

  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<AppSuggestionProvider>(context, listen: false);
    final data = await provider.fetchPharmaciesSummary(
      startDate: startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : null,
      endDate: endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
    );
    if (mounted) {
      setState(() {
        _summary = data;
        _isLoading = false;
        _sortSummary(_sortColumnIndex, _sortAscending);
      });
    }
  }

  Future<void> _selectMonthly() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.day,
    );
    if (picked != null) {
      setState(() {
        startDate = DateTime(picked.year, picked.month, 1);
        endDate = DateTime(picked.year, picked.month + 1, 0);
      });
      _fetchSummary();
    }
  }

  Future<void> _selectYearly() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        startDate = DateTime(picked.year, 1, 1);
        endDate = DateTime(picked.year, 12, 31);
      });
      _fetchSummary();
    }
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _fetchSummary();
    }
  }

  void _clearFilters() {
    setState(() {
      startDate = null;
      endDate = null;
    });
    _fetchSummary();
  }

  void _sortSummary(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      _summary.sort((a, b) {
        dynamic valA;
        dynamic valB;

        switch (columnIndex) {
          case 0:
            valA = a['name'] ?? '';
            valB = b['name'] ?? '';
            break;
          case 1:
            valA = (a['balance'] as num?)?.toDouble() ?? 0.0;
            valB = (b['balance'] as num?)?.toDouble() ?? 0.0;
            break;
          case 2:
            valA = (a['totalBuyerValue'] as num?)?.toDouble() ?? 0.0;
            valB = (b['totalBuyerValue'] as num?)?.toDouble() ?? 0.0;
            break;
          case 3:
            valA = (a['totalSellerValue'] as num?)?.toDouble() ?? 0.0;
            valB = (b['totalSellerValue'] as num?)?.toDouble() ?? 0.0;
            break;
          case 4:
            valA = (a['totalTransactionsValue'] as num?)?.toDouble() ?? 0.0;
            valB = (b['totalTransactionsValue'] as num?)?.toDouble() ?? 0.0;
            break;
          case 5:
            valA = (a['currentExcessValue'] as num?)?.toDouble() ?? 0.0;
            valB = (b['currentExcessValue'] as num?)?.toDouble() ?? 0.0;
            break;
          case 6:
            final strA = a['lastTransactionDate'];
            final strB = b['lastTransactionDate'];
            valA = strA != null ? DateTime.tryParse(strA) ?? DateTime(2000) : DateTime(2000);
            valB = strB != null ? DateTime.tryParse(strB) ?? DateTime(2000) : DateTime(2000);
            return ascending ? valA.compareTo(valB) : valB.compareTo(valA);
        }

        if (valA is String && valB is String) {
          return ascending ? valA.compareTo(valB) : valB.compareTo(valA);
        } else if (valA is num && valB is num) {
          return ascending ? valA.compareTo(valB) : valB.compareTo(valA);
        }
        return 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacies Summary'),
      ),
      body: Column(
        children: [
          _buildFilterToolbar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _summary.isEmpty
                    ? const Center(child: Text('No pharmacies data found.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            sortColumnIndex: _sortColumnIndex,
                            sortAscending: _sortAscending,
                            columns: [
                              DataColumn(
                                label: const Text('Pharmacy'),
                                onSort: (index, ascending) =>
                                    _sortSummary(index, ascending),
                              ),
                              DataColumn(
                                label: const Text('Wallet'),
                                numeric: true,
                                onSort: (index, ascending) =>
                                    _sortSummary(index, ascending),
                              ),
                              DataColumn(
                                label: const Text('Buyer Value'),
                                numeric: true,
                                onSort: (index, ascending) =>
                                    _sortSummary(index, ascending),
                              ),
                              DataColumn(
                                label: const Text('Seller Value'),
                                numeric: true,
                                onSort: (index, ascending) =>
                                    _sortSummary(index, ascending),
                              ),
                              DataColumn(
                                label: const Text('Total Trans.'),
                                numeric: true,
                                onSort: (index, ascending) =>
                                    _sortSummary(index, ascending),
                              ),
                              DataColumn(
                                label: const Text('Excess val'),
                                numeric: true,
                                onSort: (index, ascending) =>
                                    _sortSummary(index, ascending),
                              ),
                              DataColumn(
                                label: const Text('Last TX'),
                                onSort: (index, ascending) =>
                                    _sortSummary(index, ascending),
                              ),
                            ],
                            rows: _summary.map((item) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(item['name'] ?? 'Unknown'),
                                  ),
                                  DataCell(
                                    Text((item['balance'] as num?)
                                            ?.toStringAsFixed(2) ??
                                        '0.00'),
                                  ),
                                  DataCell(
                                    Text((item['totalBuyerValue'] as num?)
                                            ?.toStringAsFixed(2) ??
                                        '0.00'),
                                  ),
                                  DataCell(
                                    Text((item['totalSellerValue'] as num?)
                                            ?.toStringAsFixed(2) ??
                                        '0.00'),
                                  ),
                                  DataCell(
                                    Text((item['totalTransactionsValue'] as num?)
                                            ?.toStringAsFixed(2) ??
                                        '0.00'),
                                  ),
                                  DataCell(
                                    Text((item['currentExcessValue'] as num?)
                                            ?.toStringAsFixed(2) ??
                                        '0.00'),
                                  ),
                                  DataCell(
                                    Text(item['lastTransactionDate'] != null
                                        ? (item['lastTransactionDate'] as String)
                                            .substring(0, 10)
                                        : 'N/A'),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterBtn(
              label: 'All-time',
              isActive: startDate == null && endDate == null,
              onPressed: _clearFilters,
            ),
            const SizedBox(width: 8),
            _FilterBtn(
              label: 'Monthly',
              isActive: startDate != null &&
                  endDate != null &&
                  endDate!.difference(startDate!).inDays < 32 &&
                  startDate!.day == 1,
              onPressed: _selectMonthly,
            ),
            const SizedBox(width: 8),
            _FilterBtn(
              label: 'Yearly',
              isActive: startDate != null &&
                  endDate != null &&
                  endDate!.difference(startDate!).inDays > 360,
              onPressed: _selectYearly,
            ),
            const SizedBox(width: 8),
            _FilterBtn(
              label: 'Custom',
              isActive: startDate != null && !((endDate!.difference(startDate!).inDays < 32 && startDate!.day == 1) || endDate!.difference(startDate!).inDays > 360),
              onPressed: _selectCustomRange,
            ),
            if (startDate != null || endDate != null) ...[
              const SizedBox(width: 16),
              Text(
                '${startDate != null ? DateFormat('MM/dd').format(startDate!) : ''} - ${endDate != null ? DateFormat('MM/dd').format(endDate!) : ''}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _FilterBtn({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onPressed(),
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[900],
      labelStyle: TextStyle(
        color: isActive ? Colors.blue[900] : Colors.grey[700],
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
