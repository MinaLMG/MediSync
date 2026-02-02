import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import 'onboarding_screen.dart';
import '../l10n/generated/app_localizations.dart';

class PharmacyFormScreen extends StatefulWidget {
  const PharmacyFormScreen({super.key});

  @override
  State<PharmacyFormScreen> createState() => _PharmacyFormScreenState();
}

class _PharmacyFormScreenState extends State<PharmacyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressController = TextEditingController();

  String? pharmacistCardPath;
  String? registryPath;
  String? taxPath;
  String? licensePath;

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (type == 'card')
          pharmacistCardPath = image.path;
        else if (type == 'registry')
          registryPath = image.path;
        else if (type == 'tax')
          taxPath = image.path;
        else if (type == 'license')
          licensePath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titlePharmacyDetails)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.labelSubmitDocumentation,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.msgProvideInformation,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                _nameController,
                l10n.labelPharmacyNameWithHint,
                Icons.store,
                l10n.labelRequired,
              ),
              _buildTextField(
                _ownerController,
                l10n.labelOwnerNameWithHint,
                Icons.person_outline,
                l10n.labelRequired,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _nationalIdController,
                  decoration: InputDecoration(
                    labelText: l10n.labelNationalIdWithHint,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: const OutlineInputBorder(),
                    helperText: l10n.msgMustBe14Digits,
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 14,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.errorNationalIdRequired;
                    }
                    if (!RegExp(r'^\d{14}$').hasMatch(value)) {
                      return l10n.errorNationalIdInvalid;
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),
              Text(
                l10n.labelDetailedAddress,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: l10n.labelDetailedAddressWithHint,
                  hintText: l10n.hintDetailedAddress,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: const OutlineInputBorder(),
                  counterText: "",
                ),
                maxLines: 3,
                maxLength: 200,
                validator: (v) => v!.isEmpty ? l10n.labelRequired : null,
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              _buildImagePlaceholder(
                l10n.labelPharmacistCard,
                pharmacistCardPath != null,
                () => _pickImage('card'),
                l10n.actionChange,
                l10n.actionUpload,
              ),
              _buildImagePlaceholder(
                l10n.labelCommercialRegistry,
                registryPath != null,
                () => _pickImage('registry'),
                l10n.actionChange,
                l10n.actionUpload,
              ),
              _buildImagePlaceholder(
                l10n.labelTaxCard,
                taxPath != null,
                () => _pickImage('tax'),
                l10n.actionChange,
                l10n.actionUpload,
              ),
              _buildImagePlaceholder(
                l10n.labelLicense,
                licensePath != null,
                () => _pickImage('license'),
                l10n.actionChange,
                l10n.actionUpload,
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(l10n.actionSubmitForApproval),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String requiredError,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (v) => v!.isEmpty ? requiredError : null,
      ),
    );
  }

  Widget _buildImagePlaceholder(
    String label,
    bool hasImage,
    VoidCallback onTap,
    String changeLabel,
    String uploadLabel,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasImage ? Colors.blue[200]! : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
          color: hasImage ? Colors.blue[50] : null,
        ),
        child: Row(
          children: [
            Icon(
              hasImage ? Icons.check_circle : Icons.image,
              color: hasImage ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            TextButton(
              onPressed: onTap,
              child: Text(hasImage ? changeLabel : uploadLabel),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      if (pharmacistCardPath == null ||
          registryPath == null ||
          taxPath == null ||
          licensePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.msgPleaseUploadAllDocs),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await Provider.of<AuthProvider>(context, listen: false)
          .linkPharmacy(
            {
              'name': _nameController.text,
              'ownerName': _ownerController.text,
              'nationalId': _nationalIdController.text,
              'address': _addressController.text,
            },
            {
              'pharmacistCard': pharmacistCardPath!,
              'commercialRegistry': registryPath!,
              'taxCard': taxPath!,
              'pharmacyLicense': licensePath!,
            },
          );

      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<AuthProvider>(context, listen: false).errorMessage ??
                  l10n.msgSubmissionFailed,
            ),
          ),
        );
      }
    }
  }
}
