import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hub_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class AdminTransactionsSummaryScreen extends StatefulWidget {
  const AdminTransactionsSummaryScreen({super.key});

  @override
  State<AdminTransactionsSummaryScreen> createState() =>
      _AdminTransactionsSummaryScreenState();
}

class _AdminTransactionsSummaryScreenState
    extends State<AdminTransactionsSummaryScreen> {
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<HubProvider>(context, listen: false).fetchAdminSummary();
    });
  }

  void _fetchWithFilter() {
    Provider.of<HubProvider>(context, listen: false).fetchAdminSummary(
      startDate: startDate != null
          ? DateFormat('yyyy-MM-dd').format(startDate!)
          : null,
      endDate: endDate != null
          ? DateFormat('yyyy-MM-dd').format(endDate!)
          : null,
    );
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
      Future.microtask(() {
        if (!mounted) return;
        setState(() {
          startDate = picked;
          // Correct way to add a month: same day next month
          endDate = DateTime(
            picked.year,
            picked.month + 1,
            picked.day,
            23,
            59,
            59,
          );
        });
        _fetchWithFilter();
      });
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
      Future.microtask(() {
        if (!mounted) return;
        setState(() {
          startDate = picked;
          // Correct way to add a year
          endDate = DateTime(
            picked.year + 1,
            picked.month,
            picked.day,
            23,
            59,
            59,
          );
        });
        _fetchWithFilter();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      startDate = null;
      endDate = null;
    });
    _fetchWithFilter();
  }

  Future<void> _selectDateRange() async {
    final firstDate = DateTime(2023);
    final lastDate = DateTime.now().add(const Duration(days: 1));

    DateTimeRange? initialRange;
    if (startDate != null && endDate != null) {
      // Clamp start and end to [firstDate, lastDate]
      DateTime clampedStart = startDate!.isBefore(firstDate)
          ? firstDate
          : (startDate!.isAfter(lastDate) ? lastDate : startDate!);
      DateTime clampedEnd = endDate!.isBefore(firstDate)
          ? firstDate
          : (endDate!.isAfter(lastDate) ? lastDate : endDate!);

      // Ensure start is not after end
      if (clampedStart.isAfter(clampedEnd)) {
        clampedStart = clampedEnd;
      }

      initialRange = DateTimeRange(start: clampedStart, end: clampedEnd);
    }

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      Future.microtask(() {
        if (!mounted) return;
        setState(() {
          startDate = picked.start;
          endDate = picked.end;
        });
        _fetchWithFilter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.menuAdminTransactionsSummary),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              if (value == 'all') _clearFilters();
              if (value == 'monthly') _selectMonthly();
              if (value == 'yearly') _selectYearly();
              if (value == 'custom') _selectDateRange();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text("All Time")),
              const PopupMenuItem(value: 'monthly', child: Text("Monthly")),
              const PopupMenuItem(value: 'yearly', child: Text("Yearly")),
              const PopupMenuItem(value: 'custom', child: Text("Custom Range")),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWithFilter,
          ),
        ],
      ),
      body: Consumer<HubProvider>(
        builder: (context, hubProvider, _) {
          if (hubProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = hubProvider.adminSummary;
          if (summary == null) {
            return const Center(child: Text("Failed to load summary"));
          }

          final breakdown = summary['breakdown'] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalCard(
                  title: AppLocalizations.of(context)!.totalRevenue,
                  value: summary['totalRevenue'] ?? 0,
                  color: Colors.blue[900]!,
                ),
                const SizedBox(height: 24),
                Text(
                  "Breakdown",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSummaryTile(
                  title: AppLocalizations.of(context)!.negativeCommissions,
                  value: breakdown['negativeCommissions'] ?? 0,
                  icon: Icons.percent,
                  color: Colors.orange,
                ),
                _buildSummaryTile(
                  title: AppLocalizations.of(context)!.hubExcessRevenue,
                  value: breakdown['hubExcessRevenue'] ?? 0,
                  icon: Icons.inventory,
                  color: Colors.green,
                ),
                _buildSummaryTile(
                  title: AppLocalizations.of(context)!.salesInvoiceRevenue,
                  value: breakdown['salesInvoiceRevenue'] ?? 0,
                  icon: Icons.receipt,
                  color: Colors.teal,
                ),
                _buildSummaryTile(
                  title: AppLocalizations.of(context)!.salesInvoiceProfit,
                  value: breakdown['salesInvoiceProfit'] ?? 0,
                  icon: Icons.trending_up,
                  color: Colors.blueGrey,
                ),
                _buildSummaryTile(
                  title: AppLocalizations.of(context)!.punishmentRevenueLabel,
                  value: breakdown['punishmentRevenue'] ?? 0,
                  icon: Icons.money_off,
                  color: Colors.redAccent,
                ),
                _buildSummaryTile(
                  title: AppLocalizations.of(context)!.compensationRevenueLabel,
                  value: -(breakdown['compensationLoss'] ?? 0),
                  icon: Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                if (startDate != null) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      "Period: ${DateFormat('yyyy-MM-dd').format(startDate!)} to ${DateFormat('yyyy-MM-dd').format(endDate ?? DateTime.now())}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalCard({
    required String title,
    required num value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat("#,##0").format(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "Coins",
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required String title,
    required num value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(
          NumberFormat("#,##0").format(value),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: value >= 0 ? Colors.green[700] : Colors.red,
          ),
        ),
      ),
    );
  }
}
