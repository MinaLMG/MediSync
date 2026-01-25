import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoryHeader('📦 Stock & Inventory'),
          _buildFAQItem(
            'How can I add an excess?',
            'Go to the Home tab and click on "Add Excess Product". Fill in the product details, expiry date, and discount. Once submitted, other pharmacies can see and request it.',
          ),
          _buildFAQItem(
            'What is a "Shortage Request"?',
            'If you need a product that is not available in your stock, you can create a "Shortage Request". Other pharmacies with excess of that product can then fulfill your request.',
          ),

          const SizedBox(height: 24),
          _buildCategoryHeader('💰 Balance & Financials'),
          _buildFAQItem(
            'How can I get my balance?',
            'Your current balance is displayed at the top of the Home tab. You can also view a detailed breakdown in your "Transaction History".',
          ),
          _buildFAQItem(
            'How does the commission work?',
            'MediSync charges a small commission on successful matches between pharmacies. This helps us maintain the platform and provide delivery services.',
          ),

          const SizedBox(height: 24),
          _buildCategoryHeader('🔄 Transactions & History'),
          _buildFAQItem(
            'Where is the orders history?',
            'All your past transactions and current orders can be found in the "History" tab at the bottom of the dashboard.',
          ),
          _buildFAQItem(
            'How do I track a delivery?',
            'Once a match is confirmed and a delivery person is assigned, you can view the live status in the "Delivery Tracking" section of your active order.',
          ),

          const SizedBox(height: 24),
          _buildCategoryHeader('⚙️ Account Management'),
          _buildFAQItem(
            'How do I edit my pharmacy data?',
            'Go to "Account" -> "My Account" and click the "Edit" button. Update your info and submit. Your request will be processed shortly.',
          ),
          _buildFAQItem(
            'Can I change my password?',
            'Yes! Use the "Reset My Password" option in the Account menu. You will need your current password to set a new one.',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
