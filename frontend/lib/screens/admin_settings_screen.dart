import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _minCommController;
  late TextEditingController _shortageCommController;
  late TextEditingController _shortageSellerRewardController;

  @override
  void initState() {
    super.initState();
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    _minCommController = TextEditingController(
      text: settingsProvider.minimumCommission.toString(),
    );
    _shortageCommController = TextEditingController(
      text: settingsProvider.shortageCommission.toString(),
    );
    _shortageSellerRewardController = TextEditingController(
      text: settingsProvider.shortageSellerReward.toString(),
    );
  }

  @override
  void dispose() {
    _minCommController.dispose();
    _shortageCommController.dispose();
    _shortageSellerRewardController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final success =
          await Provider.of<SettingsProvider>(
            context,
            listen: false,
          ).updateSettings({
            'minimumCommission': double.parse(_minCommController.text),
            'shortageCommission': double.parse(_shortageCommController.text),
            'shortageSellerReward': double.parse(
              _shortageSellerRewardController.text,
            ),
          });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).errorMessage ??
                  'Failed to update settings',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Commission Ratios (%)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _minCommController,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Commission (%)',
                          helperText:
                              'Default commission for real excess rebalance.',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a value';
                          }
                          final n = double.tryParse(value);
                          if (n == null || n < 0 || n > 20) {
                            return 'Enter a number between 0 and 20';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _shortageCommController,
                        decoration: const InputDecoration(
                          labelText: 'Shortage Commission (%)',
                          helperText:
                              'Default commission for shortage fulfillment.',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a value';
                          }
                          final n = double.tryParse(value);
                          if (n == null || n < 0) {
                            return 'Enter a positive number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _shortageSellerRewardController,
                        decoration: const InputDecoration(
                          labelText: 'Shortage Seller Reward (%)',
                          helperText:
                              'Default reward for shortage fulfillment provider.',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a value';
                          }
                          final n = double.tryParse(value);
                          if (n == null || n < 0) {
                            return 'Enter a positive number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: Provider.of<SettingsProvider>(context).isLoading
                    ? null
                    : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Provider.of<SettingsProvider>(context).isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Settings',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
