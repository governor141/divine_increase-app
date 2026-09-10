import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/prayer_request_service.dart';
import '../theme/app_theme.dart';

/// Lets any signed-in user submit a personal prayer request. This does NOT
/// write to Firestore and there is nothing to read back afterward — it
/// matches the website exactly: the request is sent straight to the
/// ministry's Telegram via a Cloudflare Worker. Submit-only, by design.
class SubmitPrayerRequestScreen extends StatefulWidget {
  const SubmitPrayerRequestScreen({super.key});

  @override
  State<SubmitPrayerRequestScreen> createState() =>
      _SubmitPrayerRequestScreenState();
}

class _SubmitPrayerRequestScreenState
    extends State<SubmitPrayerRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _businessController = TextEditingController();
  final _requestController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _requestController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await PrayerRequestService.submit(
        name: _nameController.text.trim(),
        businessName: _businessController.text.trim(),
        prayerRequest: _requestController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your prayer request has been sent to the ministry.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.cream2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Submit Prayer Request', style: AppTheme.heading(size: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share what you would like the ministry to stand in '
                  'prayer with you for. This is sent directly to the pastor.',
                  style: AppTheme.body(size: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: _decoration('Your Name'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _businessController,
                  decoration: _decoration('Business Name (optional)'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _requestController,
                  decoration: _decoration('What would you like prayer for?'),
                  maxLines: 5,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your prayer request'
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.goldSoft,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.goldSoft,
                            ),
                          )
                        : const Text('Submit Prayer Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
