import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/business.dart';
import '../services/auth_service.dart';
import '../services/pin_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'pin_screen.dart';

/// The signed-in user's own space: their business profile (if they have
/// one) and account actions (change PIN, sign out).
///
/// Editing business profile details isn't built yet — it needs photo
/// upload support (Cloudinary), which is deliberately deferred until that's
/// configured safely. For now this shows the profile clearly and marks
/// editing as coming soon.
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign out?', style: AppTheme.heading(size: 16)),
        content: Text('You can sign back in anytime with your email and password.', style: AppTheme.body(size: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirm != true) return;
    await PinService().clearPin();
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthScreen()), (route) => false);
    }
  }

  void _changePin(BuildContext context, String email) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PinScreen(mode: PinMode.setup, email: email)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Kingdom Member';
    final email = user?.email ?? '';
    final initials = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Me', style: AppTheme.heading(size: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.navy,
              child: Text(initials.isEmpty ? '?' : initials, style: AppTheme.heading(size: 18, color: AppColors.goldSoft)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTheme.heading(size: 17)),
                  Text(email, style: AppTheme.body(size: 12.5, color: AppColors.muted)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Text('My Business', style: AppTheme.heading(size: 15)),
          const SizedBox(height: 10),
          if (user != null)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('businesses').where('ownerUid', isEqualTo: user.uid).limit(1).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator(color: AppColors.navy));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.cream2, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
                    child: Text('You don\'t have a business listed yet.', style: AppTheme.body(size: 13, color: AppColors.muted)),
                  );
                }
                final business = Business.fromFirestore(docs.first);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.cream2, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(business.businessName, style: AppTheme.body(size: 15, weight: FontWeight.w700))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (business.status == 'approved' ? AppColors.sage : AppColors.gold).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            business.status.isNotEmpty ? business.status[0].toUpperCase() + business.status.substring(1) : '',
                            style: AppTheme.body(size: 10, weight: FontWeight.w700, color: business.status == 'approved' ? AppColors.sage : AppColors.gold),
                          ),
                        ),
                      ]),
                      Text(business.businessCategory, style: AppTheme.body(size: 12, color: AppColors.muted)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Editing your profile from the app is coming in a future update.')),
                          ),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line)),
                          child: Text('Edit Profile', style: AppTheme.body(size: 12.5, weight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
          Text('Account', style: AppTheme.heading(size: 15)),
          const SizedBox(height: 10),
          _ActionTile(icon: Icons.lock_reset, label: 'Change PIN', onTap: () => _changePin(context, email)),
          const SizedBox(height: 10),
          _ActionTile(icon: Icons.logout, label: 'Sign Out', color: AppColors.danger, onTap: () => _signOut(context)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: AppColors.cream2, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, size: 18, color: color ?? AppColors.navy),
          const SizedBox(width: 10),
          Text(label, style: AppTheme.body(size: 14, weight: FontWeight.w600, color: color ?? AppColors.charcoal)),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
        ]),
      ),
    );
  }
}
