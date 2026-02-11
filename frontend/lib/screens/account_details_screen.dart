import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/generated/app_localizations.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  bool _isEditing = false;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _phNameController;
  late TextEditingController _phPhoneController;
  late TextEditingController _phAddressController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?['name'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _phoneController = TextEditingController(text: user?['phone'] ?? '');

    final pharmacy = user?['pharmacy'];
    _phNameController = TextEditingController(text: pharmacy?['name'] ?? '');
    _phPhoneController = TextEditingController(text: pharmacy?['phone'] ?? '');
    _phAddressController = TextEditingController(
      text: pharmacy?['address'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _phNameController.dispose();
    _phPhoneController.dispose();
    _phAddressController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.requestProfileUpdate({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'pharmacy': {
            'name': _phNameController.text,
            'phone': _phPhoneController.text,
            'address': _phAddressController.text,
          },
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? l10n.msgUpdateRequested
                    : (authProvider.errorMessage ?? l10n.msgUpdateFailed),
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
          if (success) setState(() => _isEditing = false);
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final hasPending = user?['pendingUpdate'] != null;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.menuMyAccount),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              label: Text(
                l10n.actionEdit,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasPending && !_isEditing) _buildPendingBadge(),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildSectionHeader(l10n.labelPersonalInformation),
                  _isEditing
                      ? _buildTextField(
                          _nameController,
                          l10n.labelFullName,
                          Icons.person,
                        )
                      : _buildReadOnlyItem(
                          l10n.labelFullName,
                          user?['name'] ?? 'N/A',
                          Icons.person,
                        ),
                  const SizedBox(height: 12),
                  _isEditing
                      ? _buildTextField(
                          _emailController,
                          l10n.labelEmailAddress,
                          Icons.email,
                        )
                      : _buildReadOnlyItem(
                          l10n.labelEmailAddress,
                          user?['email'] ?? 'N/A',
                          Icons.email,
                        ),
                  const SizedBox(height: 12),
                  _isEditing
                      ? _buildTextField(
                          _phoneController,
                          l10n.labelPhoneNumber,
                          Icons.phone,
                        )
                      : _buildReadOnlyItem(
                          l10n.labelPhoneNumber,
                          user?['phone'] ?? 'N/A',
                          Icons.phone,
                        ),

                  const SizedBox(height: 32),
                  _buildSectionHeader(l10n.labelPharmacyInformation),
                  _isEditing
                      ? _buildTextField(
                          _phNameController,
                          l10n.labelPharmacyName,
                          Icons.local_pharmacy,
                        )
                      : _buildReadOnlyItem(
                          l10n.labelPharmacyName,
                          user?['pharmacy']?['name'] ?? 'N/A',
                          Icons.local_pharmacy,
                        ),
                  const SizedBox(height: 12),
                  _isEditing
                      ? _buildTextField(
                          _phPhoneController,
                          l10n.labelPharmacyPhone,
                          Icons.contact_phone,
                        )
                      : _buildReadOnlyItem(
                          l10n.labelPharmacyPhone,
                          user?['pharmacy']?['phone'] ?? 'N/A',
                          Icons.contact_phone,
                        ),
                  const SizedBox(height: 12),
                  _isEditing
                      ? _buildTextField(
                          _phAddressController,
                          l10n.labelPharmacyAddress,
                          Icons.location_on,
                          maxLines: 2,
                        )
                      : _buildReadOnlyItem(
                          l10n.labelPharmacyAddress,
                          user?['pharmacy']?['address'] ?? 'N/A',
                          Icons.location_on,
                        ),
                ],
              ),
            ),

            if (_isEditing) ...[
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                      child: Text(l10n.actionCancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitUpdate,
                      style: _isSubmitting
                          ? ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey,
                              disabledForegroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            )
                          : ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(l10n.actionSaveChanges),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildReadOnlyItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[800], size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (v) => v == null || v.isEmpty ? l10n.labelRequired : null,
      ),
    );
  }

  Widget _buildPendingBadge() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[800]!),
      ),
      child: Row(
        children: [
          Icon(Icons.pending_actions, color: Colors.amber[900]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.msgPendingUpdateInfo,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
