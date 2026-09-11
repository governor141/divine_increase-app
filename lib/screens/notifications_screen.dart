import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/notification_read_service.dart';
import '../theme/app_theme.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String category;
  final DateTime? createdAt;
  final DateTime? expireAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    required this.expireAt,
  });

  factory AppNotification.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AppNotification(
      id: doc.id,
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      category: (data['category'] as String? ?? 'all').toLowerCase(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      expireAt: (data['expireAt'] as Timestamp?)?.toDate(),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _categories = ['All', 'Business', 'Ministry', 'Prayer', 'Events'];
  String _selectedCategory = 'All';
  Set<String> _readIds = {};

  @override
  void initState() {
    super.initState();
    _loadReadIds();
  }

  Future<void> _loadReadIds() async {
    final ids = await NotificationReadService.getReadIds();
    if (mounted) setState(() => _readIds = ids);
  }

  Future<void> _markRead(String id) async {
    await NotificationReadService.markRead(id);
    if (mounted) setState(() => _readIds.add(id));
  }

  Future<void> _markAllRead(List<AppNotification> notifications) async {
    await NotificationReadService.markAllRead(notifications.map((n) => n.id).toList());
    if (mounted) setState(() => _readIds.addAll(notifications.map((n) => n.id)));
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'business':
        return Icons.storefront_outlined;
      case 'ministry':
        return Icons.auto_stories_outlined;
      case 'prayer':
        return Icons.self_improvement;
      case 'events':
        return Icons.event_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Notifications', style: AppTheme.heading(size: 18)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.navy));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load notifications.', style: AppTheme.body(color: AppColors.muted)));
          }
          final now = DateTime.now();
          final all = (snapshot.data?.docs ?? [])
              .map(AppNotification.fromFirestore)
              .where((n) => n.expireAt == null || n.expireAt!.isAfter(now))
              .toList();
          final filtered = _selectedCategory == 'All'
              ? all
              : all.where((n) => n.category == _selectedCategory.toLowerCase()).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((c) {
                            final selected = c == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCategory = c),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected ? AppColors.navy : AppColors.cream2,
                                    border: Border.all(color: selected ? AppColors.navy : AppColors.line),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(c,
                                      style: AppTheme.body(size: 12.5, weight: FontWeight.w600, color: selected ? AppColors.goldSoft : AppColors.charcoal)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    if (all.isNotEmpty)
                      GestureDetector(
                        onTap: () => _markAllRead(all),
                        child: Text('Mark all as read', style: AppTheme.body(size: 12, weight: FontWeight.w600, color: AppColors.navy)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text('No notifications yet.', style: AppTheme.body(color: AppColors.muted)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final n = filtered[i];
                          final isRead = _readIds.contains(n.id);
                          return GestureDetector(
                            onTap: () => _markRead(n.id),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.cream2,
                                border: Border.all(color: AppColors.line),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(_categoryIcon(n.category), size: 20, color: AppColors.navy),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Expanded(child: Text(n.title, style: AppTheme.body(size: 14, weight: FontWeight.w700))),
                                          if (!isRead)
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.danger),
                                            ),
                                        ]),
                                        const SizedBox(height: 4),
                                        Text(n.message, style: AppTheme.body(size: 12.5, color: AppColors.charcoal)),
                                        const SizedBox(height: 6),
                                        Text(_timeAgo(n.createdAt), style: AppTheme.body(size: 11, color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
