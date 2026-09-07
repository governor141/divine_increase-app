import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';

/// Full list of admin-approved businesses (`businesses` collection,
/// status == "approved"). Opened from the Home screen's "Featured
/// Business" quick access card.
class ApprovedBusinessesScreen extends StatelessWidget {
  const ApprovedBusinessesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance.collection('businesses').where('status', isEqualTo: 'approved');

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Featured Businesses', style: AppTheme.heading(size: 18)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.navy));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load businesses.', style: AppTheme.body(color: AppColors.muted)));
          }
          final businesses = (snapshot.data?.docs ?? []).map(Business.fromFirestore).toList();
          if (businesses.isEmpty) {
            return Center(child: Text('No approved businesses yet.', style: AppTheme.body(color: AppColors.muted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: businesses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _BusinessTile(business: businesses[i]),
          );
        },
      ),
    );
  }
}

class _BusinessTile extends StatelessWidget {
  final Business business;
  const _BusinessTile({required this.business});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: business.displayImage.isNotEmpty
                  ? Image.network(
                      business.displayImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.line, child: const Icon(Icons.storefront_outlined, color: AppColors.muted)),
                    )
                  : Container(color: AppColors.line, child: const Icon(Icons.storefront_outlined, color: AppColors.muted)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(business.businessName, style: AppTheme.body(size: 14, weight: FontWeight.w700)),
                Text(business.businessCategory, style: AppTheme.body(size: 11.5, color: AppColors.muted)),
                if (business.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 13, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(business.location,
                          style: AppTheme.body(size: 11.5, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
