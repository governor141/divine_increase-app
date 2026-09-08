import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/declaration.dart';
import '../theme/app_theme.dart';

/// Lists daily prayer/declaration audio posts from the `voiceDeclarations`
/// collection. Tapping play opens the audio in the phone's default player
/// (keeps things simple and reliable — an in-app player can come later).
class PrayerScreen extends StatelessWidget {
  const PrayerScreen({super.key});

  Future<void> _play(BuildContext context, String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this audio.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance.collection('voiceDeclarations').orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Daily Prayer', style: AppTheme.heading(size: 18)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.navy));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load declarations.', style: AppTheme.body(color: AppColors.muted)));
          }
          final declarations = (snapshot.data?.docs ?? []).map(Declaration.fromFirestore).toList();
          if (declarations.isEmpty) {
            return Center(child: Text('No prayer declarations yet.', style: AppTheme.body(color: AppColors.muted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: declarations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _DeclarationCard(declaration: declarations[i], onPlay: () => _play(context, declarations[i].audioUrl)),
          );
        },
      ),
    );
  }
}

class _DeclarationCard extends StatelessWidget {
  final Declaration declaration;
  final VoidCallback onPlay;
  const _DeclarationCard({required this.declaration, required this.onPlay});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: onPlay,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.navy),
            child: const Icon(Icons.play_arrow, color: AppColors.goldSoft),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(declaration.title, style: AppTheme.body(size: 14, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(_formatDate(declaration.createdAt), style: AppTheme.body(size: 11.5, color: AppColors.muted)),
            ],
          ),
        ),
      ]),
    );
  }
}
