import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import 'onboarding_screen.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Pharmacy Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Submit Documentation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please provide the following information as written in your official documents.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                _nameController,
                'Pharmacy Name (اسم الصيدلية)',
                Icons.store,
              ),
              _buildTextField(
                _ownerController,
                "Owner's Name (اسم صاحب الصيدلية كما مدون في الرخصه)",
                Icons.person_outline,
              ),
              _buildTextField(
                _nationalIdController,
                'National ID (بطاقة رقم قومي)',
                Icons.badge_outlined,
              ),

              const SizedBox(height: 16),
              const Text(
                'Detailed Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Detailed Address (العنوان بالتفصيل)',
                  hintText: 'e.g. 123 Madinet Nasr, Cairo, Egypt',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
                maxLines: 3,
                maxLength: 200,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              _buildImagePlaceholder(
                'Pharmacist Card',
                pharmacistCardPath != null,
                () => _pickImage('card'),
              ),
              _buildImagePlaceholder(
                'Commercial Registry',
                registryPath != null,
                () => _pickImage('registry'),
              ),
              _buildImagePlaceholder(
                'Tax Card',
                taxPath != null,
                () => _pickImage('tax'),
              ),
              _buildImagePlaceholder(
                'Pharmacy License',
                licensePath != null,
                () => _pickImage('license'),
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
                    : const Text('Submit for Approval'),
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
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildImagePlaceholder(
    String label,
    bool hasImage,
    VoidCallback onTap,
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
              child: Text(hasImage ? 'Change' : 'Upload'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (pharmacistCardPath == null ||
          registryPath == null ||
          taxPath == null ||
          licensePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload all 4 documents'),
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
                  'Submission failed',
            ),
          ),
        );
      }
    }
  }
}
