import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shortage_provider.dart';
import '../providers/product_provider.dart';
import '../providers/excess_provider.dart';
import 'add_excess_screen.dart';
import 'add_shortage_screen.dart';
import 'suggest_product_screen.dart';
import 'suggestions_complaints_screen.dart';
import '../providers/app_suggestion_provider.dart';
import '../providers/notification_provider.dart';
import 'requests_history_screen.dart';
import 'balance_history_screen.dart';
import 'create_order_screen.dart';
import 'hub/hub_owners_screen.dart';
import 'hub/hub_payments_screen.dart';
import 'hub/hub_purchase_invoice_screen.dart';
import 'hub/hub_sales_invoice_screen.dart';
import 'hub/hub_calculations_widget.dart';
import 'hub/cash_balance_history_screen.dart';
import 'hub/system_summary_screen.dart';
import '../providers/hub_provider.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  bool _isInteracting = false; // Flag to track user interaction

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<ShortageProvider>(
        context,
        listen: false,
      ).fetchGlobalActiveShortages();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      Provider.of<AppSuggestionProvider>(
        context,
        listen: false,
      ).fetchPendingCounts();
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!mounted || _isInteracting) return;
      final provider = Provider.of<ShortageProvider>(context, listen: false);
      if (provider.globalShortages.length > 1) {
        if (_pageController.hasClients) {
          int nextPage = _currentPage + 1;
          if (nextPage >= provider.globalShortages.length) {
            nextPage = 0;
          }

          _currentPage = nextPage;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _onRefresh() async {
    final shortages = Provider.of<ShortageProvider>(context, listen: false);
    final products = Provider.of<ProductProvider>(context, listen: false);
    final notifications = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final hub = Provider.of<HubProvider>(context, listen: false);

    final List<Future> refreshTasks = [
      shortages.fetchGlobalActiveShortages(),
      products.fetchProducts(),
      notifications.fetchNotifications(),
      auth.refreshProfile(),
    ];

    if (auth.currentUser?['pharmacy']?['isHub'] ?? false) {
      refreshTasks.add(hub.fetchHubSummary());
    }

    await Future.wait(refreshTasks);
  }

  @override
  void dispose() {
    _stopTimer();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShortageProvider>(context);
    final shortages = provider.globalShortages;

    final List<Map<String, dynamic>> menuItems = [
      {
        'title': AppLocalizations.of(context)!.menuRequestsHistory,
        'originalTitle': 'Requests History',
        'icon': Icons.history,
        'color': Colors.blue,
      },
      {
        'title': AppLocalizations.of(context)!.menuShoppingTour,
        'originalTitle': 'Shopping Tour',
        'icon': Icons.shopping_cart,
        'color': Colors.orange,
      },
      {
        'title': AppLocalizations.of(context)!.menuAddShortage,
        'originalTitle': 'Add Shortage',
        'icon': Icons.remove_circle_outline,
        'color': Colors.red,
      },
      {
        'title': AppLocalizations.of(context)!.menuAddExcess,
        'originalTitle': 'Add Excess',
        'icon': Icons.add_circle_outline,
        'color': Colors.green,
      },
      {
        'title': AppLocalizations.of(context)!.menuSuggestProduct,
        'originalTitle': 'Suggest Product',
        'icon': Icons.recommend,
        'color': Colors.purple,
      },
      {
        'title': AppLocalizations.of(context)!.menuSuggestionsComplaints,
        'originalTitle': 'Suggestions/Complaints',
        'icon': Icons.lightbulb_outline,
        'color': Colors.teal,
      },
      {
        'title': AppLocalizations.of(context)!.menuBalanceHistory,
        'originalTitle': 'Balance History',
        'icon': Icons.account_balance_wallet,
        'color': Colors.amber[800]!,
      },
    ];

    final authProvider = Provider.of<AuthProvider>(context);
    final isHub = authProvider.currentUser?['pharmacy']?['isHub'] ?? false;

    if (isHub) {
      menuItems.addAll([
        {
          'title': AppLocalizations.of(context)!.menuCashBalanceHistory,
          'originalTitle': 'Cash Balance History',
          'icon': Icons.account_balance_wallet_outlined,
          'color': Colors.green[800],
        },
        {
          'title': AppLocalizations.of(context)!.menuHubOwners,
          'originalTitle': 'Hub Owners',
          'icon': Icons.people_outline,
          'color': Colors.indigo,
        },
        {
          'title': AppLocalizations.of(context)!.menuHubPayments,
          'originalTitle': 'Owner Payments',
          'icon': Icons.payments_outlined,
          'color': Colors.pink,
        },
        {
          'title': AppLocalizations.of(context)!.menuHubPurchaseInvoice,
          'originalTitle': 'Purchase Invoice',
          'icon': Icons.add_business_outlined,
          'color': Colors.cyan,
        },
        {
          'title': AppLocalizations.of(context)!.menuHubSalesInvoice,
          'originalTitle': 'Sales Invoice',
          'icon': Icons.point_of_sale_outlined,
          'color': Colors.lime[800],
        },
        {
          'title': AppLocalizations.of(context)!.menuHubCalculations,
          'originalTitle': 'Calculations Widget',
          'icon': Icons.calculate_outlined,
          'color': Colors.indigo,
        },
        {
          'title': AppLocalizations.of(context)!.optimisticValue,
          'originalTitle': 'System Summary',
          'icon': Icons.analytics_outlined,
          'color': Colors.deepOrange,
        },
      ]);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // News Line (Shortages Marquee)
            Container(
              height: 40,
              width: double.infinity,
              color: Colors.red[800] ?? Colors.red,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: Text(
                      AppLocalizations.of(context)!.urgentShortages,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: provider.isLoading && shortages.isEmpty
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            ),
                          )
                        : shortages.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context)!.noShortages,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : Listener(
                            onPointerDown: (_) {
                              setState(() => _isInteracting = true);
                              _stopTimer();
                            },
                            onPointerUp: (_) {
                              setState(() => _isInteracting = false);
                              _startTimer();
                            },
                            onPointerCancel: (_) {
                              setState(() => _isInteracting = false);
                              _startTimer();
                            },
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: shortages.length,
                              onPageChanged: (index) {
                                _currentPage = index;
                              },
                              itemBuilder: (context, index) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      '• ${shortages[index]} •',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
            // Advertisement space
            Container(
              height: 120,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(76),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Menu Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return _buildMenuCard(
                    context,
                    item['title'] ?? 'Menu Item',
                    item['originalTitle'] ?? '',
                    item['icon'] ?? Icons.help,
                    item['color'] ?? Colors.blue,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    num value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          NumberFormat("#,##0").format(value),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String originalTitle,
    IconData icon,
    Color? color, {
    int badgeCount = 0,
  }) {
    final effectiveColor = color ?? Colors.blue;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          final logicTitle = originalTitle.isNotEmpty ? originalTitle : title;
          if (logicTitle == 'Add Excess') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddExcessScreen()),
            );
          } else if (logicTitle == 'Add Shortage') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddShortageScreen(),
              ),
            );
          } else if (logicTitle == 'Requests History') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RequestsHistoryScreen(),
              ),
            );
          } else if (logicTitle == 'Shopping Tour') {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateOrderScreen(),
              ),
            );
            // Reload market excesses if order was placed successfully
            if (result == true && mounted) {
              await Provider.of<ExcessProvider>(
                context,
                listen: false,
              ).fetchMarketExcesses();
            }
          } else if (logicTitle == 'Suggest Product') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SuggestProductScreen(),
              ),
            );
          } else if (logicTitle == 'Suggestions/Complaints') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SuggestionsComplaintsScreen(),
              ),
            );
          } else if (logicTitle == 'Balance History') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BalanceHistoryScreen(),
              ),
            );
          } else if (logicTitle == 'Hub Owners') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HubOwnersScreen()),
            );
          } else if (logicTitle == 'Owner Payments') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HubPaymentsScreen(),
              ),
            );
          } else if (logicTitle == 'Purchase Invoice') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HubPurchaseInvoiceScreen(),
              ),
            );
          } else if (logicTitle == 'Sales Invoice') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HubSalesInvoiceScreen(),
              ),
            );
          } else if (logicTitle == 'Calculations Widget') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HubCalculationsWidget(),
              ),
            );
          } else if (logicTitle == 'Cash Balance History') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CashBalanceHistoryScreen(),
              ),
            );
          } else if (logicTitle == 'System Summary') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SystemSummaryScreen(),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 32, color: effectiveColor),
                  if (badgeCount > 0)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
