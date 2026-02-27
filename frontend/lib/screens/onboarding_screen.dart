import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'pharmacy_form_screen.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userStatus = Provider.of<AuthProvider>(context).userStatus;

    if (userStatus == 'active') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                const DashboardScreen(userType: 'pharmacy_owner'),
          ),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.onboardingTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: userStatus == 'pending'
              ? _buildPendingView(context)
              : userStatus == 'waiting'
              ? _buildWaitingView(context)
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildPendingView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_pharmacy_outlined, size: 80, color: Colors.blue),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.welcomeMessage,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.linkPharmacyInstructions,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PharmacyFormScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.addNewPharmacyButton),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.awaitingApprovalTitle,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.awaitingApprovalMessage,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            Provider.of<AuthProvider>(context, listen: false).refreshProfile();
          },
          child: Text(AppLocalizations.of(context)!.checkStatusButton),
        ),
      ],
    );
  }
}
