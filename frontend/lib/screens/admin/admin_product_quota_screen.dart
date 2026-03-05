import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/quota_provider.dart';
import '../../providers/excess_provider.dart';

class AdminProductQuotaScreen extends StatefulWidget {
  const AdminProductQuotaScreen({super.key});

  @override
  State<AdminProductQuotaScreen> createState() =>
      _AdminProductQuotaScreenState();
}

class _AdminProductQuotaScreenState extends State<AdminProductQuotaScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<QuotaProvider>(context, listen: false).fetchQuotas(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quotaProvider = Provider.of<QuotaProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productQuotasTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: () => quotaProvider.fetchQuotas(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddQuotaDialog(context),
        child: const Icon(Icons.add),
      ),
      body: quotaProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : quotaProvider.quotas.isEmpty
          ? Center(child: Text(l10n.noProductsFound))
          : ListView.builder(
              itemCount: quotaProvider.quotas.length,
              itemBuilder: (context, index) {
                final quota = quotaProvider.quotas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(quota['product']['name'] ?? 'Unknown'),
                    subtitle: Text(
                      'Vol: ${quota['volume']['name']} | Price: ${quota['price']} | Exp: ${quota['expiryDate']} | Sale: ${quota['salePercentage']}%',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Max: ${quota['maxQuantity']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditQuotaDialog(context, quota),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, quota),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddQuotaDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddQuotaDialog());
  }

  void _showEditQuotaDialog(BuildContext context, dynamic quota) {
    final controller = TextEditingController(
      text: quota['maxQuantity'].toString(),
    );
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: const Text('Edit Max Quantity'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max Units per Month',
              ),
              onChanged: (val) => setDialogState(() {}),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final newMax = int.tryParse(controller.text);
                        if (newMax != null && newMax > 0) {
                          setDialogState(() => isSubmitting = true);
                          final quotaProvider = Provider.of<QuotaProvider>(
                            context,
                            listen: false,
                          );
                          final success = await quotaProvider.updateQuota(
                            quota['_id'],
                            newMax,
                          );
                          if (success) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.msgQuotaUpdated)),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              setDialogState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    quotaProvider.errorMessage ??
                                        'Update failed',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic quota) {
    final l10n = AppLocalizations.of(context)!;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.dialogDeleteTitle),
            content: Text(l10n.dialogDeleteConfirm),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: Text(l10n.actionCancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        final quotaProvider = Provider.of<QuotaProvider>(
                          context,
                          listen: false,
                        );
                        final success = await quotaProvider.deleteQuota(
                          quota['_id'],
                        );
                        if (success) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.msgQuotaDeleted)),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            setDialogState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  quotaProvider.errorMessage ?? 'Delete failed',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.actionDelete),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AddQuotaDialog extends StatefulWidget {
  const AddQuotaDialog({super.key});

  @override
  State<AddQuotaDialog> createState() => _AddQuotaDialogState();
}

class _AddQuotaDialogState extends State<AddQuotaDialog> {
  final _priceController = TextEditingController();
  final _expiryController = TextEditingController();
  final _saleController = TextEditingController();
  final _maxController = TextEditingController();

  String? _selectedProductId;
  String? _selectedProductName;
  String? _selectedVolumeId;

  bool _useTemplate = true;
  List<dynamic> _excesses = [];
  bool _isLoadingExcesses = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchExcesses();
  }

  Future<void> _fetchExcesses() async {
    setState(() => _isLoadingExcesses = true);
    try {
      final ep = Provider.of<ExcessProvider>(context, listen: false);
      await ep.fetchAvailableExcesses();
      setState(() => _excesses = ep.availableExcesses);
    } catch (e) {
      debugPrint('Error fetching excesses: $e');
    } finally {
      setState(() => _isLoadingExcesses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.actionAdd),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ToggleButtons(
                isSelected: [_useTemplate, !_useTemplate],
                onPressed: (index) {
                  setState(() {
                    _useTemplate = index == 0;
                    _selectedProductId = null;
                    _selectedProductName = null;
                    _selectedVolumeId = null;
                    _priceController.clear();
                    _expiryController.clear();
                    _saleController.clear();
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('From Excess'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Manual'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_useTemplate) ...[
                if (_isLoadingExcesses)
                  const CircularProgressIndicator()
                else if (_excesses.isEmpty)
                  Text(l10n.noResultsFound)
                else
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: _excesses.length,
                      itemBuilder: (context, index) {
                        final ex = _excesses[index];
                        final prod = ex['product'];
                        final vol = ex['volume'];
                        final isSelected =
                            _selectedProductId == prod['_id'] &&
                            _selectedVolumeId == vol['_id'] &&
                            _priceController.text ==
                                ex['selectedPrice'].toString() &&
                            _expiryController.text == ex['expiryDate'];

                        return ListTile(
                          title: Text(prod['name']),
                          subtitle: Text(
                            'Vol: ${vol['name']} | Price: ${ex['selectedPrice']} | Exp: ${ex['expiryDate']} | Sale: ${ex['salePercentage']}%',
                          ),
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedProductId = prod['_id'];
                              _selectedProductName = prod['name'];
                              _selectedVolumeId = vol['_id'];
                              _priceController.text = ex['selectedPrice']
                                  .toString();
                              _expiryController.text = ex['expiryDate'];
                              _saleController.text = ex['salePercentage']
                                  .toString();
                            });
                          },
                        );
                      },
                    ),
                  ),
                if (_selectedProductName != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Selected: $_selectedProductName',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ] else ...[
                // Manual fields (simplified for now as template is primary)
                const Text(
                  'Manual input not fully implemented. Please use "From Excess" template.',
                ),
              ],
              const Divider(),
              TextField(
                controller: _maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Units per Month',
                  hintText: 'e.g., 5',
                ),
                onChanged: (val) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed:
              (_selectedProductId == null ||
                  _maxController.text.isEmpty ||
                  _isSubmitting)
              ? null
              : () async {
                  final max = int.tryParse(_maxController.text);
                  if (max != null) {
                    setState(() => _isSubmitting = true);
                    final quotaProvider = Provider.of<QuotaProvider>(
                      context,
                      listen: false,
                    );
                    final success = await quotaProvider.createQuota(
                      productId: _selectedProductId!,
                      volumeId: _selectedVolumeId!,
                      price: double.parse(_priceController.text),
                      expiryDate: _expiryController.text,
                      salePercentage: double.parse(_saleController.text),
                      maxQuantity: max,
                    );
                    if (success) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.msgQuotaCreated)),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        setState(() => _isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              quotaProvider.errorMessage ?? 'Creation failed',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.actionAdd),
        ),
      ],
    );
  }
}
