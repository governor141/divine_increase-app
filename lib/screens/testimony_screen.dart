import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/testimony.dart';
import '../theme/app_theme.dart';

/// Lists admin-approved testimonies (`testimonies` collection,
/// status == "approved"), with a button to submit a new one.
class TestimonyScreen extends StatelessWidget {
  const TestimonyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance.collection('testimonies').where('status', isEqualTo: 'approved');

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Testimonies', style: AppTheme.heading(size: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.goldSoft,
        icon: const Icon(Icons.add),
        label: Text('Share Yours', style: AppTheme.body(size: 13, weight: FontWeight.w700, color: AppColors.goldSoft)),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubmitTestimonyScreen())),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.navy));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load testimonies.', style: AppTheme.body(color: AppColors.muted)));
          }
          final testimonies = (snapshot.data?.docs ?? []).map(Testimony.fromFirestore).toList();
          if (testimonies.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No testimonies yet — be the first to share what God has done!',
                    textAlign: TextAlign.center, style: AppTheme.body(color: AppColors.muted)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: testimonies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _TestimonyCard(testimony: testimonies[i]),
          );
        },
      ),
    );
  }
}

class _TestimonyCard extends StatelessWidget {
  final Testimony testimony;
  const _TestimonyCard({required this.testimony});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(testimony.title, style: AppTheme.heading(size: 15))),
            if (testimony.category.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.sage.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(testimony.category, style: AppTheme.body(size: 10, weight: FontWeight.w600, color: AppColors.sage)),
              ),
          ]),
          const SizedBox(height: 8),
          Text(testimony.testimony, style: AppTheme.body(size: 13, color: AppColors.charcoal)),
          const SizedBox(height: 10),
          Text('— ${testimony.authorName.isNotEmpty ? testimony.authorName : "Anonymous"}',
              style: AppTheme.body(size: 11.5, weight: FontWeight.w600, color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// Lets a signed-in user submit their own testimony. It's saved with
/// status "pending" and won't appear publicly until an admin approves it —
/// same review pattern as business listings.
class SubmitTestimonyScreen extends StatefulWidget {
  const SubmitTestimonyScreen({super.key});

  @override
  State<SubmitTestimonyScreen> createState() => _SubmitTestimonyScreenState();
}

class _SubmitTestimonyScreenState extends State<SubmitTestimonyScreen> {
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in at least a title and your testimony.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('testimonies').add({
        'authorUid': user?.uid ?? '',
        'authorName': user?.displayName ?? 'Anonymous',
        'authorEmail': user?.email ?? '',
        'category': _categoryCtrl.text.trim(),
        'title': _titleCtrl.text.trim(),
        'testimony': _bodyCtrl.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you! Your testimony has been submitted for review.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Could not submit right now. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Share Your Testimony', style: AppTheme.heading(size: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title', style: AppTheme.body(size: 11.5, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            _Field(controller: _titleCtrl, hint: 'e.g. Breakthrough'),
            const SizedBox(height: 14),
            Text('Category (optional)', style: AppTheme.body(size: 11.5, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            _Field(controller: _categoryCtrl, hint: 'e.g. Business Growth, Healing, Provision'),
            const SizedBox(height: 14),
            Text('Your testimony', style: AppTheme.body(size: 11.5, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            _Field(controller: _bodyCtrl, hint: 'Share what God has done...', maxLines: 6),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: AppTheme.body(size: 12.5, color: AppColors.danger)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Submit for Review', style: AppTheme.body(size: 14, weight: FontWeight.w700, color: AppColors.navy)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _Field({required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: AppTheme.body(size: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.body(size: 14, color: AppColors.muted),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
