import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/delivery_request_provider.dart';
import '../providers/app_suggestion_provider.dart';
import '../utils/ui_utils.dart';
import '../l10n/generated/app_localizations.dart';

class AdminDeliveryRequestsScreen extends StatefulWidget {
  const AdminDeliveryRequestsScreen({super.key});

  @override
  State<AdminDeliveryRequestsScreen> createState() =>
      _AdminDeliveryRequestsScreenState();
}

class _AdminDeliveryRequestsScreenState
    extends State<AdminDeliveryRequestsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<DeliveryRequestProvider>(
        context,
        listen: false,
      ).fetchPendingRequests();
    });
  }

  void _reviewRequest(String requestId, String status) async {
    final success = await Provider.of<DeliveryRequestProvider>(
      context,
      listen: false,
    ).reviewRequest(requestId, status);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? AppLocalizations.of(context)!.msgRequestApproved
                  : AppLocalizations.of(context)!.msgRequestRejected,
            ),
          ),
        );
        // Refresh counts for badges
        Provider.of<AppSuggestionProvider>(
          context,
          listen: false,
        ).fetchPendingCounts();
      } else {
        final error = Provider.of<DeliveryRequestProvider>(
          context,
          listen: false,
        ).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error ?? AppLocalizations.of(context)!.msgFailedReviewRequest,
            ),
          ),
        );
      }
    }
  }

  void _cleanup() async {
    final success = await Provider.of<DeliveryRequestProvider>(
      context,
      listen: false,
    ).cleanupRequests();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.msgCleanupOldRequests),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.msgCleanupFailed),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.labelAdminDeliveryRequests),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<DeliveryRequestProvider>(
              context,
              listen: false,
            ).fetchPendingRequests(),
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: l10n.labelCleanup,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.labelCleanup),
                  content: Text(l10n.msgConfirmCleanup),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.actionCancel),
                    ),
                    StatefulBuilder(
                      builder: (context, setDialogState) {
                        final p = Provider.of<DeliveryRequestProvider>(context);
                        return TextButton(
                          onPressed: p.isLoading
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  _cleanup();
                                },
                          child: p.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.actionDelete),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<DeliveryRequestProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.pendingRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.pendingRequests.isEmpty) {
            return Center(child: Text(l10n.msgNoPendingDeliveryRequests));
          }

          return RefreshIndicator(
            onRefresh: provider.fetchPendingRequests,
            child: ListView.builder(
              itemCount: provider.pendingRequests.length,
              itemBuilder: (context, index) {
                final request = provider.pendingRequests[index];
                final delivery = request['delivery'];
                final tx = request['transaction'];
                final date = DateTime.parse(request['createdAt']).toLocal();

                final shortagePh =
                    tx['stockShortage']?['shortage']?['pharmacy'];
                final List sources = tx['stockExcessSources'] ?? [];
                final excessPh = sources.isEmpty
                    ? null
                    : sources[0]['stockExcess']?['pharmacy'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              delivery['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, HH:mm').format(date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${l10n.phoneLabel}: ${delivery['phone']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n.labelTransactionHash}${tx['_id'].toString().substring(tx['_id'].toString().length - 6)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (shortagePh != null)
                                InkWell(
                                  onTap: () => UIUtils.showPharmacyInfo(
                                    context,
                                    shortagePh,
                                  ),
                                  child: Text(
                                    '${l10n.labelShortagePharmacy} ${shortagePh['name']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              if (excessPh != null)
                                InkWell(
                                  onTap: () => UIUtils.showPharmacyInfo(
                                    context,
                                    excessPh,
                                  ),
                                  child: Text(
                                    '${l10n.labelExcessPharmacy} ${excessPh['name']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              Text(
                                '${l10n.labelProduct}: ${tx['stockShortage']?['shortage']?['product']?['name'] ?? 'Unknown'}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : () => _reviewRequest(
                                      request['_id'],
                                      'rejected',
                                    ),
                              style: provider.isLoading
                                  ? TextButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                    )
                                  : TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                              child: provider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : Text(l10n.actionReject),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : () => _reviewRequest(
                                      request['_id'],
                                      'approved',
                                    ),
                              style: provider.isLoading
                                  ? ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.grey,
                                      disabledForegroundColor: Colors.white,
                                    )
                                  : ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                              child: provider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(l10n.actionApprove),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
