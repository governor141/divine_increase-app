import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';

/// Home dashboard.
///
/// The featured businesses and network grid below use placeholder data.
/// Phase 2 will replace the placeholder list with a live Firestore query
/// so that anything you add through your admin backend shows up here
/// automatically — no app update needed.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _placeholderBusinesses = [
    Business(name: 'Amara Catering', category: 'Catering', location: 'Lagos', sponsored: true),
    Business(name: 'Grace Couture', category: 'Fashion & Clothing', location: 'Enugu'),
    Business(name: 'Xero Software Inc.', category: 'Software Dev.', location: 'Enugu', sponsored: true),
    Business(name: 'Titus Builders', category: 'Construction', location: 'Accra'),
  ];

  static const _networkItems = [
    _NetworkItem('Prayer', Icons.self_improvement, AppColors.sage),
    _NetworkItem('Events', Icons.event, AppColors.navy),
    _NetworkItem('Testimony', Icons.description_outlined, AppColors.gold),
    _NetworkItem('Community', Icons.groups_outlined, AppColors.sage),
    _NetworkItem('Wallet', Icons.account_balance_wallet_outlined, AppColors.navy),
    _NetworkItem('Donate', Icons.favorite_outline, AppColors.danger),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Kingdom Member';
    final initials = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 21,
                            backgroundColor: AppColors.navy,
                            child: Text(initials.isEmpty ? '?' : initials,
                                style: AppTheme.heading(size: 15, color: AppColors.goldSoft)),
                          ),
                          const SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Grace to you,', style: AppTheme.body(size: 11.5, color: AppColors.muted)),
                            Text(name, style: AppTheme.heading(size: 16)),
                          ]),
                        ]),
                        Row(children: [
                          _IconBtn(icon: Icons.notifications_outlined, showDot: true, onTap: () {}),
                          const SizedBox(width: 8),
                          _IconBtn(icon: Icons.menu, onTap: () {}),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FeaturedSection(businesses: _placeholderBusinesses),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cream2,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              '"Father, we ask for Your hand upon every business in this network."',
                              style: AppTheme.body(size: 12.5, weight: FontWeight.w500).copyWith(fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 4),
                            Text("This month's prayer focus", style: AppTheme.body(size: 10.5, color: AppColors.muted)),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    Text('Quick Access', style: AppTheme.heading(size: 15)),
                    const SizedBox(height: 10),
                    Row(children: [
                      _PrimaryCard(icon: Icons.apartment_outlined, label: 'Directory'),
                      const SizedBox(width: 10),
                      _PrimaryCard(icon: Icons.star_outline, label: 'Featured Business'),
                      const SizedBox(width: 10),
                      _PrimaryCard(icon: Icons.campaign_outlined, label: 'Advertise'),
                    ]),
                    const SizedBox(height: 18),
                    Text('Network', style: AppTheme.heading(size: 15)),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.1,
                      children: _networkItems.map((item) => _NetworkTile(item: item)).toList(),
                    ),
                  ],
                ),
              ),
            ),
            _BottomNav(),
          ],
        ),
      ),
    );
  }
}

class _FeaturedSection extends StatelessWidget {
  final List<Business> businesses;
  const _FeaturedSection({required this.businesses});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.navy, AppColors.navy2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.star, size: 14, color: AppColors.goldSoft),
                  const SizedBox(width: 6),
                  Text('Featured Businesses', style: AppTheme.body(size: 12, weight: FontWeight.w600, color: AppColors.goldSoft)),
                ]),
                Text('See all  ›', style: AppTheme.body(size: 11, color: const Color(0xFFB9BECF))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: businesses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final b = businesses[i];
                return Container(
                  width: 148,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        alignment: Alignment.center,
                        child: Stack(children: [
                          const Center(child: Icon(Icons.storefront_outlined, color: Colors.white54)),
                          if (b.sponsored)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(6)),
                                child: Text('Sponsored', style: AppTheme.body(size: 8, weight: FontWeight.w700, color: AppColors.navy)),
                              ),
                            ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(size: 12, weight: FontWeight.w600, color: Colors.white)),
                            Text(b.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(size: 10, color: const Color(0xFFB9BECF))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap, this.showDot = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.cream2,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(children: [
          Center(child: Icon(icon, size: 18, color: AppColors.navy)),
          if (showDot)
            Positioned(
              top: 6,
              right: 7,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.danger),
              ),
            ),
        ]),
      ),
    );
  }
}

class _PrimaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PrimaryCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cream2,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Icon(icon, color: AppColors.navy, size: 20),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: AppTheme.body(size: 10.5, weight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _NetworkItem {
  final String label;
  final IconData icon;
  final Color color;
  const _NetworkItem(this.label, this.icon, this.color);
}

class _NetworkTile extends StatelessWidget {
  final _NetworkItem item;
  const _NetworkTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(item.icon, color: item.color, size: 22),
        const SizedBox(height: 6),
        Text(item.label, style: AppTheme.body(size: 11, weight: FontWeight.w600)),
      ]),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, 'Home', true),
      (Icons.apartment_outlined, 'Directory', false),
      (Icons.self_improvement, 'Prayer', false),
      (Icons.chat_bubble_outline, 'Chat', false),
      (Icons.person_outline, 'Me', false),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.cream2,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((it) {
          final (icon, label, active) = it;
          final color = active ? AppColors.navy : AppColors.muted;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.body(size: 10, weight: active ? FontWeight.w700 : FontWeight.w500, color: color)),
          ]);
        }).toList(),
      ),
    );
  }
}
