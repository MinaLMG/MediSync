import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/generated/app_localizations.dart';

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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.msgSettingsUpdated),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).errorMessage ??
                  AppLocalizations.of(context)!.msgFailedUpdateSettings,
            ),
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
        title: Text(l10n.menuSystemSettings),
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
                      Text(
                        l10n.labelCommissionRatios,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _minCommController,
                        decoration: InputDecoration(
                          labelText: l10n.labelMinComm,
                          helperText: l10n.helperMinComm,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.msgPleaseEnterValue;
                          }
                          final n = double.tryParse(value);
                          if (n == null || n < 0 || n > 20) {
                            return l10n.msgEnterNumberBetween0And20;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _shortageCommController,
                        decoration: InputDecoration(
                          labelText: l10n.labelShortageComm,
                          helperText: l10n.helperShortageComm,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.msgPleaseEnterValue;
                          }
                          final n = double.tryParse(value);
                          if (n == null || n < 0) {
                            return l10n.msgEnterPositiveNumber;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _shortageSellerRewardController,
                        decoration: InputDecoration(
                          labelText: l10n.labelShortageSellerRewardField,
                          helperText: l10n.helperShortageSellerReward,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.msgPleaseEnterValue;
                          }
                          final n = double.tryParse(value);
                          if (n == null || n < 0) {
                            return l10n.msgEnterPositiveNumber;
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
                    : Text(
                        l10n.actionSaveSettings,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
