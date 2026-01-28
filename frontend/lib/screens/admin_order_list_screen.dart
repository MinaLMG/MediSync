import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import 'admin_order_fulfillment_screen.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Orders')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (ctx, i) {
                final order = orders[i];
                // order: { serial, status, totalItems, fulfilledItems, totalAmount, pharmacy: { name }, items: [] }
                final pharmacyName =
                    order['pharmacy']?['name'] ?? 'Unknown Pharmacy';
                final totalAmount = order['totalAmount'] ?? 0;
                final status = order['status'];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Order #${order['serial']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pharmacy: $pharmacyName'),
                        Text(
                          'Total Amount: ${totalAmount.toStringAsFixed(2)} EGP',
                        ),
                        Text('Status: $status'),
                        Text(
                          'Progress: ${order['fulfilledItems']} / ${order['totalItems']} items',
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
