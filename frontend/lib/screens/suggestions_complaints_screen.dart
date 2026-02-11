import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_suggestion_provider.dart';
import '../l10n/generated/app_localizations.dart';

class SuggestionsComplaintsScreen extends StatefulWidget {
  const SuggestionsComplaintsScreen({super.key});

  @override
  State<SuggestionsComplaintsScreen> createState() =>
      _SuggestionsComplaintsScreenState();
}

class _SuggestionsComplaintsScreenState
    extends State<SuggestionsComplaintsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final success = await Provider.of<AppSuggestionProvider>(
          context,
          listen: false,
        ).submitSuggestion(_contentController.text.trim());

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.msgFeedbackSuccess),
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  Provider.of<AppSuggestionProvider>(
                        context,
                        listen: false,
                      ).errorMessage ??
                      AppLocalizations.of(context)!.msgGenericError,
                ),
              ),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleSuggestionsComplaints)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.labelFeedbackDescription,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _contentController,
                maxLength: 1000,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: l10n.labelFeedbackTitle,
                  hintText: l10n.labelFeedbackPlaceholder,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v!.isEmpty ? l10n.requiredError : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: _isSubmitting
                    ? ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      )
                    : ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                    : Text(l10n.actionSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
