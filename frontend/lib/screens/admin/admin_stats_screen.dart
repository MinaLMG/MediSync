import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../providers/excess_provider.dart';
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
        AppLocalizations.of(context)!.labelQuantity,
        AppLocalizations.of(context)!.labelPrice,
        AppLocalizations.of(context)!.labelExpiry,
        AppLocalizations.of(context)!.labelSalePercentage,
      ]);

      // Data rows
      for (var row in flattenedData) {
        sheetObject.appendRow([
          row['productName'],
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
