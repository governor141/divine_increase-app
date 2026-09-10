import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/wallet.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';

/// Shows the signed-in user's wallet balance and funding request history,
/// and now also lets them submit a funding request directly from the app:
/// pay via bank transfer using the details shown, then confirm with an
/// amount + payment proof photo. This writes to `walletFundingRequests`
/// with status "pending" (required by the Firestore rules) -- the admin
/// still manually reviews and approves it from the website, same as before.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  File? _proofPhoto;
  bool _submitting = false;

  static const _bankName = 'Moniepoint MFB';
  static const _accountNumber = '9123597543';
  static const _accountName = 'Spiritus Sanctus Ignis Ministry';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied.')),
    );
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _proofPhoto = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_proofPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a screenshot or receipt as payment proof.')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      final proofUrl = await CloudinaryService.uploadImage(_proofPhoto!);
      if (proofUrl == null || proofUrl.isEmpty) {
        throw Exception('Could not upload your payment proof. Please try again.');
      }

      await FirebaseFirestore.instance.collection('walletFundingRequests').add({
        'uid': user.uid,
        'email': user.email ?? '',
        'amount': num.tryParse(_amountController.text.trim()) ?? 0,
        'method': 'bank_transfer',
        'proofUrl': proofUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted. The ministry will confirm your payment shortly.')),
      );
      _amountController.clear();
      setState(() => _proofPhoto = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.sage;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.gold;
    }
  }

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTheme.body(size: 12, color: AppColors.muted)),
          ),
          Expanded(
            child: Text(value, style: AppTheme.body(size: 13, weight: FontWeight.w700)),
          ),
          GestureDetector(
            onTap: () => _copy(label, value),
            child: const Icon(Icons.copy, size: 16, color: AppColors.navy),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Wallet', style: AppTheme.heading(size: 18)),
      ),
      body: uid == null
          ? Center(child: Text('Please sign in again to view your wallet.', style: AppTheme.body(color: AppColors.muted)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fund your wallet, then pay for advert slots straight from your balance.',
                    style: AppTheme.body(size: 12.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('wallets').doc(uid).snapshots(),
                    builder: (context, snapshot) {
                      final wallet = snapshot.hasData && snapshot.data!.exists
                          ? Wallet.fromFirestore(snapshot.data!)
                          : const Wallet(balance: 0);
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: AppColors.cream2,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(children: [
                          Text('Wallet Balance', style: AppTheme.body(size: 11.5, color: AppColors.muted)),
                          const SizedBox(height: 6),
                          Text('\u20A6${wallet.balance}', style: AppTheme.heading(size: 30)),
                        ]),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  Text('Fund Your Wallet', style: AppTheme.heading(size: 15)),
                  const SizedBox(height: 4),
                  Text(
                    'Pay using the account below, then confirm your payment in the form '
                    'underneath -- your balance updates once the ministry confirms it.',
                    style: AppTheme.body(size: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cream2,
                      border: Border.all(color: AppColors.gold),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bank Transfer', style: AppTheme.body(size: 12.5, weight: FontWeight.w700)),
                        _bankRow('Bank', _bankName),
                        _bankRow('Account Number', _accountNumber),
                        _bankRow('Account Name', _accountName),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Already Paid? Confirm It Here', style: AppTheme.body(size: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Amount Paid (\u20A6)',
                            filled: true,
                            fillColor: AppColors.cream2,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.line)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.line)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.navy)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter the amount you paid';
                            if (num.tryParse(v.trim()) == null) return 'Please enter a valid number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Text('Payment Proof (Screenshot/Receipt)', style: AppTheme.body(size: 12.5, weight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickProof,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cream2,
                              border: Border.all(color: AppColors.line),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _proofPhoto == null
                                ? Row(children: [
                                    const Icon(Icons.upload_file, color: AppColors.muted, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Choose a file', style: AppTheme.body(size: 13, color: AppColors.muted)),
                                  ])
                                : Row(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(_proofPhoto!, width: 40, height: 40, fit: BoxFit.cover),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text('Selected', style: AppTheme.body(size: 13))),
                                    const Icon(Icons.check_circle, color: AppColors.sage, size: 18),
                                  ]),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.navy,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: _submitting
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy))
                                : Text('Submit for Confirmation', style: AppTheme.body(size: 13.5, weight: FontWeight.w700, color: AppColors.navy)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text('Your Funding History', style: AppTheme.heading(size: 15)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('walletFundingRequests')
                        .where('uid', isEqualTo: uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.navy)));
                      }
                      if (snapshot.hasError) {
                        return Text('Could not load your funding history.', style: AppTheme.body(color: AppColors.muted));
                      }
                      final requests = (snapshot.data?.docs ?? []).map(FundingRequest.fromFirestore).toList();
                      if (requests.isEmpty) {
                        return Text('No wallet activity yet.', style: AppTheme.body(size: 12.5, color: AppColors.muted));
                      }
                      return Column(
                        children: requests
                            .map((r) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.cream2,
                                    border: Border.all(color: AppColors.line),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('\u20A6${r.amount}', style: AppTheme.body(size: 14, weight: FontWeight.w700)),
                                          Text(_formatDate(r.createdAt), style: AppTheme.body(size: 11, color: AppColors.muted)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(r.status).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        r.status.isNotEmpty ? r.status[0].toUpperCase() + r.status.substring(1) : '',
                                        style: AppTheme.body(size: 11, weight: FontWeight.w700, color: _statusColor(r.status)),
                                      ),
                                    ),
                                  ]),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
