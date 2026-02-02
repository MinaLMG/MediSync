import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

class UIUtils {
  static void showPharmacyInfo(BuildContext context, dynamic pharmacy) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.local_pharmacy, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(pharmacy['name'] ?? l10n.labelPharmacyInfo)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(
              Icons.location_on,
              pharmacy['address'] ?? l10n.msgNoAddress,
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.phone, pharmacy['phone'] ?? l10n.msgNoPhone),
            if (pharmacy['ownerName'] != null) ...[
              const SizedBox(height: 12),
              _infoRow(Icons.person, l10n.labelOwner(pharmacy['ownerName'])),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionClose),
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
