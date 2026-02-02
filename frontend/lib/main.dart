import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/product_provider.dart';
import 'providers/excess_provider.dart';
import 'providers/shortage_provider.dart';
import 'providers/order_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/app_suggestion_provider.dart';
import 'providers/delivery_request_provider.dart';
import 'providers/balance_history_provider.dart';
import 'providers/requests_history_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadLocale()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ExcessProvider()),
        ChangeNotifierProvider(create: (_) => AppSuggestionProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryRequestProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ShortageProvider>(
          create: (context) => ShortageProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => previous!..update(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (context) =>
              OrderProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => previous!..update(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (context) => TransactionProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => previous!..update(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => previous!..update(auth),
        ),
        ChangeNotifierProvider(create: (_) => BalanceHistoryProvider()),
        ChangeNotifierProxyProvider<AuthProvider, RequestsHistoryProvider>(
          create: (context) => RequestsHistoryProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => previous!..update(auth),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'MediSync',
      debugShowCheckedModeBanner: false,
      locale: settingsProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('ar'), // Arabic
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<void> _autoLoginFuture;

  @override
  void initState() {
    super.initState();
    _autoLoginFuture = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _autoLoginFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isAuthenticated) {
              if (auth.userRole == 'admin') {
                return DashboardScreen(userType: auth.userRole ?? 'admin');
              } else if (auth.userRole == 'delivery') {
                return DashboardScreen(userType: auth.userRole ?? 'delivery');
              }
              return DashboardScreen(userType: auth.userRole ?? 'pharmacy');
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}
