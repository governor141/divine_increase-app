import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';

/// Lets a user advertise their business, matching the website's Advertise
/// flow exactly. Reads `settings/advertConfig` (paidAdvertsActive) live, so
/// this screen automatically switches between the free flow and the paid
/// (N5,000/month, deducted from wallet balance) flow whenever the admin
/// toggles it on the website -- no app update needed.
///
/// When paidAdvertsActive is true: the user must have at least N5,000 in
/// their wallet (`wallets/{uid}`). On submit, N5,000 is deducted from the
/// wallet and the request is submitted with requiresPayment: true. If the
/// balance is too low, submission is blocked with a message directing them
/// to fund their wallet first (Wallet screen), matching the website.
///
/// Note: "Require Payment Proof" (a separate advertConfig field) governs
/// the Wallet *funding* flow (bank transfer + screenshot, admin confirms),
/// not this screen -- see lib/screens/wallet_screen.dart.
class AdvertiseScreen extends StatefulWidget {
  const AdvertiseScreen({super.key});

  @override
  State<AdvertiseScreen> createState() => _AdvertiseScreenState();
}

class _AdvertiseScreenState extends State<AdvertiseScreen> {
  static const double _advertCost = 5000;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<File> _photos = [];
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 3 photos.')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit({required bool paidAdvertsActive, required double walletBalance}) async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (paidAdvertsActive && walletBalance < _advertCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your wallet balance is too low. Please fund your wallet first.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final imageUrls = <String>[];
      for (final photo in _photos) {
        final url = await CloudinaryService.uploadImage(photo);
        if (url != null && url.isNotEmpty) {
          imageUrls.add(url);
        }
      }

      final requestData = {
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'location': _locationController.text.trim(),
        'phone': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : '',
        'images': imageUrls,
        'applicantUid': user.uid,
        'applicantEmail': user.email ?? '',
        'requiresPayment': paidAdvertsActive,
        'status': 'pending_confirmation',
        'submittedAt': FieldValue.serverTimestamp(),
        if (paidAdvertsActive) 'amount': _advertCost,
      };

      if (paidAdvertsActive) {
        final walletRef = FirebaseFirestore.instance.collection('wallets').doc(user.uid);
        final requestRef = FirebaseFirestore.instance.collection('advertRequests').doc();
        await FirebaseFirestore.instance.runTransaction((txn) async {
          final walletSnap = await txn.get(walletRef);
          final currentBalance = (walletSnap.data()?['balance'] as num?)?.toDouble() ?? 0;
          if (currentBalance < _advertCost) {
            throw Exception('Your wallet balance is too low. Please fund your wallet first.');
          }
          txn.update(walletRef, {
            'balance': currentBalance - _advertCost,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          txn.set(requestRef, requestData);
        });
      } else {
        await FirebaseFirestore.instance.collection('advertRequests').add(requestData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your business has been submitted for review.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.cream2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.navy)),
      );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Advertise Your Business', style: AppTheme.heading(size: 18)),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('settings').doc('advertConfig').snapshots(),
          builder: (context, configSnap) {
            if (configSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.navy));
            }
            final paidAdvertsActive = configSnap.data?.data()?['paidAdvertsActive'] == true;

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: paidAdvertsActive && user != null
                  ? FirebaseFirestore.instance.collection('wallets').doc(user.uid).snapshots()
                  : const Stream.empty(),
              builder: (context, walletSnap) {
                final walletBalance = (walletSnap.data?.data()?['balance'] as num?)?.toDouble() ?? 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (paidAdvertsActive)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.cream2,
                              border: Border.all(color: AppColors.navy),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Step 1: Pay N5,000 from Your Wallet', style: AppTheme.body(size: 13, weight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(
                                  'Your current wallet balance: N${walletBalance.toStringAsFixed(0)}. '
                                  '${walletBalance < _advertCost ? 'Not enough? Fund your wallet first, then come back and submit.' : 'You have enough to submit below.'}',
                                  style: AppTheme.body(size: 12, color: AppColors.muted),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: Text('Advertise your business here -- Free for now.',
                                style: AppTheme.body(size: 12.5, weight: FontWeight.w600)),
                          ),
                        const SizedBox(height: 18),
                        Text(paidAdvertsActive ? 'Step 2: Submit Your Business Details' : 'Submit Your Business Details',
                            style: AppTheme.body(size: 13, weight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          decoration: _decoration('Business Name'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your business name' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _categoryController,
                          decoration: _decoration('Category'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a category' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _locationController,
                          decoration: _decoration('Location'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a location' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          decoration: _decoration('Phone'),
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a phone number' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _decoration('Description'),
                          maxLines: 4,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a description' : null,
                        ),
                        const SizedBox(height: 18),
                        Text('Photos (up to 3)', style: AppTheme.body(size: 13, weight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (int i = 0; i < _photos.length; i++)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(_photos[i], width: 88, height: 88, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => _removePhoto(i),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (_photos.length < 3)
                              GestureDetector(
                                onTap: _addPhoto,
                                child: Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: AppColors.cream2,
                                    border: Border.all(color: AppColors.line),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.add_a_photo_outlined, color: AppColors.muted),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting
                                ? null
                                : () => _submit(paidAdvertsActive: paidAdvertsActive, walletBalance: walletBalance),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              foregroundColor: AppColors.goldSoft,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _submitting
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldSoft))
                                : Text(paidAdvertsActive ? 'Submit for Confirmation' : 'Submit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
