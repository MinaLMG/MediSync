import 'package:flutter/material.dart';

class UIUtils {
  static void showPharmacyInfo(BuildContext context, dynamic pharmacy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.local_pharmacy, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(pharmacy['name'] ?? 'Pharmacy Info')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(
              Icons.location_on,
              pharmacy['address'] ?? 'No address provided',
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.phone, pharmacy['phone'] ?? 'No phone provided'),
            if (pharmacy['ownerName'] != null) ...[
              const SizedBox(height: 12),
              _infoRow(Icons.person, 'Owner: ${pharmacy['ownerName']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
