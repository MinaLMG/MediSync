import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/excess_provider.dart';
import 'providers/shortage_provider.dart';
import 'providers/order_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ExcessProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ShortageProvider>(
          create: (context) => ShortageProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => ShortageProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (context) =>
              OrderProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => OrderProvider(auth),
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
    return MaterialApp(
      title: 'MediSync',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
