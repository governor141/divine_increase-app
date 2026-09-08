import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';

/// Full business directory — every admin-approved business, searchable
/// by name or category.
class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance.collection('businesses').where('status', isEqualTo: 'approved');

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Business Directory', style: AppTheme.heading(size: 18)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cream2,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                const Icon(Icons.search, size: 18, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                    style: AppTheme.body(size: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by name or category...',
                      hintStyle: AppTheme.body(size: 13, color: AppColors.muted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.navy));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Could not load the directory.', style: AppTheme.body(color: AppColors.muted)));
                }
                var businesses = (snapshot.data?.docs ?? []).map(Business.fromFirestore).toList();
                if (_query.isNotEmpty) {
                  businesses = businesses
                      .where((b) => b.businessName.toLowerCase().contains(_query) || b.businessCategory.toLowerCase().contains(_query))
                      .toList();
                }
                if (businesses.isEmpty) {
                  return Center(child: Text('No businesses found.', style: AppTheme.body(color: AppColors.muted)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: businesses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _BusinessTile(business: businesses[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessTile extends StatelessWidget {
  final Business business;
  const _BusinessTile({required this.business});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: business))),
      child: Container(
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
                    ? Image.network(business.displayImage, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.line, child: const Icon(Icons.storefront_outlined, color: AppColors.muted)))
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
                        child: Text(business.location, style: AppTheme.body(size: 11.5, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full detail view of a single business.
class BusinessDetailScreen extends StatelessWidget {
  final Business business;
  const BusinessDetailScreen({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text(business.businessName, style: AppTheme.heading(size: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (business.displayImage.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(business.displayImage, height: 160, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 160, color: AppColors.line)),
              ),
            const SizedBox(height: 14),
            Text(business.businessName, style: AppTheme.heading(size: 19)),
            Text(business.businessCategory, style: AppTheme.body(size: 13, color: AppColors.muted)),
            const SizedBox(height: 12),
            if (business.description.isNotEmpty) Text(business.description, style: AppTheme.body(size: 13.5)),
            const SizedBox(height: 16),
            if (business.location.isNotEmpty) _InfoRow(icon: Icons.place_outlined, label: business.location),
            if (business.phone.isNotEmpty) _InfoRow(icon: Icons.call_outlined, label: business.phone),
            if (business.email.isNotEmpty) _InfoRow(icon: Icons.mail_outline, label: business.email),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.navy),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTheme.body(size: 13.5))),
      ]),
    );
  }
}
