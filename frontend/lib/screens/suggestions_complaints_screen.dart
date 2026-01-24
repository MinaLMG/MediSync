import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_suggestion_provider.dart';

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

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await Provider.of<AppSuggestionProvider>(
        context,
        listen: false,
      ).submitSuggestion(_contentController.text.trim());

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you for your feedback!')),
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
                    'Error submitting feedback',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AppSuggestionProvider>(context).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Suggestions & Complaints')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'We value your feedback. Please let us know if you have any suggestions for improvement or any complaints regarding the system.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _contentController,
                maxLength: 1000,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Your Feedback',
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Please enter some content' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
