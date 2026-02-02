import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../l10n/generated/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleNotifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<NotificationProvider>(
              context,
              listen: false,
            ).fetchNotifications(),
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).markAllAsSeen();
            },
            tooltip: l10n.tooltipMarkAllAsSeen,
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchNotifications(),
                    child: Text(l10n.actionRetry),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.msgNoNotifications,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.separated(
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                final isSeen = notification['seen'] == true;
                DateTime? createdAt;
                try {
                  createdAt = DateTime.parse(
                    notification['createdAt'].toString(),
                  );
                } catch (e) {
                  debugPrint(
                    '⚠️ Error parsing date: ${notification['createdAt']}',
                  );
                  createdAt = DateTime.now();
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(notification['type']),
                    child: Icon(
                      _getCategoryIcon(notification['type']),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    notification['message'],
                    style: TextStyle(
                      fontWeight: isSeen ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, h:mm a').format(createdAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                  tileColor: isSeen ? null : Colors.blue.withOpacity(0.05),
                  onTap: () {
                    if (!isSeen) {
                      provider.markAsSeen(notification['_id']);
                    }
                    // TODO: Implement navigation based on actionUrl
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String? type) {
    switch (type) {
      case 'transaction':
        return Colors.blue;
      case 'system':
        return Colors.orange;
      case 'alert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? type) {
    switch (type) {
      case 'transaction':
        return Icons.swap_horiz;
      case 'system':
        return Icons.info_outline;
      case 'alert':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications;
    }
  }
}
