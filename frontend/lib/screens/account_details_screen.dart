import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  bool _isEditing = false;
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
    if (_formKey.currentState!.validate()) {
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
                  ? 'Update request sent to Admin!'
                  : (authProvider.errorMessage ?? 'Failed to send request'),
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) setState(() => _isEditing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final hasPending = user?['pendingUpdate'] != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              label: const Text('Edit', style: TextStyle(color: Colors.white)),
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
                  _buildSectionHeader('Personal Information'),
                  _isEditing
                      ? _buildTextField(
                          _nameController,
                          'Full Name',
                          Icons.person,
                        )
                      : _buildReadOnlyItem(
                          'Full Name',
                          user?['name'] ?? 'N/A',
                          Icons.person,
                        ),
                  const SizedBox(height: 12),
                  _isEditing
                      ? _buildTextField(
                          _emailController,
                          'Email Address',
                          Icons.email,
                        )
                      : _buildReadOnlyItem(
                          'Email Address',
                          user?['email'] ?? 'N/A',
                          Icons.email,
                        ),
                  const SizedBox(height: 12),
                  _isEditing
                      ? _buildTextField(
                          _phoneController,
                          'Phone Number',
                          Icons.phone,
                        )
                      : _buildReadOnlyItem(
                          'Phone Number',
                          user?['phone'] ?? 'N/A',
                          Icons.phone,
                        ),

                  const SizedBox(height: 32),
                  _buildSectionHeader('Pharmacy Information'),
                  _isEditing
                      ? _buildTextField(
                          _phNameController,
                          'Pharmacy Name',
                          Icons.local_pharmacy,
                        )
                      : _buildReadOnlyItem(
                          'Pharmacy Name',
                          user?['pharmacy']?['name'] ?? 'N/A',
                          Icons.local_pharmacy,
                        ),
                  const SizedBox(height: 12),
                  _isEditing
                      ? _buildTextField(
                          _phPhoneController,
                          'Pharmacy Phone',
                          Icons.contact_phone,
                        )
                      : _buildReadOnlyItem(
                          'Pharmacy Phone',
                          user?['pharmacy']?['phone'] ?? 'N/A',
                          Icons.contact_phone,
                        ),
                  const SizedBox(height: 12),
                  _isEditing
                      ? _buildTextField(
                          _phAddressController,
                          'Pharmacy Address',
                          Icons.location_on,
                          maxLines: 2,
                        )
                      : _buildReadOnlyItem(
                          'Pharmacy Address',
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
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _submitUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Changes'),
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
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildPendingBadge() {
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
          const Expanded(
            child: Text(
              'Awaiting approval for your previous update request. New edits will replace the pending one.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
