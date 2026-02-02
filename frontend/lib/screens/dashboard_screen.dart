import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shortage_provider.dart';
import '../providers/product_provider.dart';
import '../providers/app_suggestion_provider.dart';
import '../providers/requests_history_provider.dart';
import 'login_screen.dart';
import 'home_tab.dart';
import 'notifications_screen.dart';
import '../providers/notification_provider.dart';
import 'package:intl/intl.dart';

import 'requests_history_screen.dart';
import 'profile_screen.dart';
import '../l10n/generated/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  final String userType;

  const DashboardScreen({super.key, required this.userType});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.userType != 'admin') {
      Future.microtask(() {
        if (mounted) {
          Provider.of<AuthProvider>(context, listen: false).refreshProfile();
        }
      });
    }
  }

  // Placeholder pages for other tabs
  late List<Widget> _pages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages = [
      const HomeTab(),
      const RequestsHistoryScreen(), // Replaced placeholder
      Center(child: Text(AppLocalizations.of(context)!.pendingCartPlaceholder)),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
            ),
            child: Image.asset('assets/images/medisync_full.png'),
          ),
        ),
        title: widget.userType != 'admin'
            ? Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final balance =
                      auth.currentUser?['pharmacy']?['balance'] ?? 0;
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.balanceDisplay(
                          NumberFormat("#,##0").format(balance),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Always refresh notifications
              Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).fetchNotifications();

              if (_selectedIndex == 0) {
                Provider.of<ShortageProvider>(
                  context,
                  listen: false,
                ).fetchGlobalActiveShortages();
                Provider.of<ProductProvider>(
                  context,
                  listen: false,
                ).fetchProducts();
                Provider.of<AppSuggestionProvider>(
                  context,
                  listen: false,
                ).fetchPendingCounts();
              } else if (_selectedIndex == 1) {
                Provider.of<RequestsHistoryProvider>(
                  context,
                  listen: false,
                ).fetchRequestsHistory();
              } else if (_selectedIndex == 3) {
                Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).refreshProfile();
              }
            },
            tooltip: AppLocalizations.of(context)!.reloadTooltip,
          ),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      left: 5,
                      top: 5,
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
                          notificationProvider.unreadCount.toString(),
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
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: AppLocalizations.of(context)!.navOrderHistory,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart_checkout),
            label: AppLocalizations.of(context)!.navPendingCart,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.navAccount,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
