import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.helpSupportTitle),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoryHeader(context, l10n.catStockInventory),
          _buildFAQItem(l10n.qHowToAddExcess, l10n.aHowToAddExcess),
          _buildFAQItem(l10n.qWhatIsShortage, l10n.aWhatIsShortage),

          const SizedBox(height: 24),
          _buildCategoryHeader(context, l10n.catBalanceFinance),
          _buildFAQItem(l10n.qHowToGetBalance, l10n.aHowToGetBalance),
          _buildFAQItem(l10n.qHowCommissionWorks, l10n.aHowCommissionWorks),

          const SizedBox(height: 24),
          _buildCategoryHeader(context, l10n.catTransactionsHistory),
          _buildFAQItem(l10n.qWhereIsHistory, l10n.aWhereIsHistory),
          _buildFAQItem(l10n.qHowToTrackDelivery, l10n.aHowToTrackDelivery),

          const SizedBox(height: 24),
          _buildCategoryHeader(context, l10n.catAccountManagement),
          _buildFAQItem(l10n.qHowToEditProfile, l10n.aHowToEditProfile),
          _buildFAQItem(l10n.qCanIChangePassword, l10n.aCanIChangePassword),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title) {
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
