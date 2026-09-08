import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/wallet.dart';
import '../theme/app_theme.dart';

/// Shows the signed-in user's wallet balance and funding request history.
/// Submitting a new funding request (with payment proof upload) isn't
/// built into the app yet, so "Fund Wallet" opens the website instead,
/// where that flow already works reliably.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  Future<void> _fundOnWebsite(BuildContext context) async {
    final uri = Uri.parse('https://spiritus-sanctus-ignis.web.app/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the website.')),
        );
      }
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
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _fundOnWebsite(context),
                            icon: const Icon(Icons.add, size: 16),
                            label: Text('Fund Wallet', style: AppTheme.body(size: 13, weight: FontWeight.w700, color: AppColors.navy)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.navy,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
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
