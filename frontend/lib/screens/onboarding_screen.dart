import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'pharmacy_form_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userStatus = Provider.of<AuthProvider>(context).userStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
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
        const Text(
          'Welcome to MediSync!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'To start using the platform, you need to link your pharmacy and provide documentation.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
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
          label: const Text('Adding New Pharmacy'),
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
        const Text(
          'Awaiting Approval',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Your documents have been submitted and are currently being reviewed by the admin. We will notify you once your account is active.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            Provider.of<AuthProvider>(context, listen: false).refreshProfile();
          },
          child: const Text('Check Status Now'),
        ),
      ],
    );
  }
}
