import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import 'admin_order_fulfillment_screen.dart';
import '../l10n/generated/app_localizations.dart';

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  State<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends State<AdminOrderListScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchOrders());
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    await Provider.of<OrderProvider>(context, listen: false).fetchOrders();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final orders = Provider.of<OrderProvider>(context).orders;

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageOrdersTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (ctx, i) {
                final order = orders[i];
                // order: { serial, status, totalItems, fulfilledItems, totalAmount, pharmacy: { name }, items: [] }
                final pharmacyName =
                    order['pharmacy']?['name'] ?? l10n.labelUnknown;
                final totalAmount = order['totalAmount'] ?? 0;
                final status = order['status'];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${l10n.labelPharmacyPrefix} $pharmacyName'),
                        Text(
                          l10n.labelTotalAmountPrefix(
                            totalAmount.toStringAsFixed(2),
                          ),
                        ),
                        Text('${l10n.labelStatusPrefix} $status'),
                        Text(
                          l10n.labelProgressPrefix(
                            order['fulfilledItems'],
                            order['totalItems'],
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AdminOrderFulfillmentScreen(order: order),
                        ),
                      ).then((_) => _fetchOrders());
                    },
                  ),
                );
              },
            ),
    );
  }
}
