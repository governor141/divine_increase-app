import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';

/// Lists upcoming events from the `events` Firestore collection —
/// whatever the admin posts on the website shows up here too.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final query = FirebaseFirestore.instance
        .collection('events')
        .where('eventDate', isGreaterThanOrEqualTo: todayStr)
        .orderBy('eventDate');

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Events', style: AppTheme.heading(size: 18)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.navy));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load events.', style: AppTheme.body(color: AppColors.muted)));
          }
          final events = (snapshot.data?.docs ?? []).map(Event.fromFirestore).toList();
          if (events.isEmpty) {
            return Center(child: Text('No upcoming events right now.', style: AppTheme.body(color: AppColors.muted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _EventCard(event: events[i]),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Text(event.displayDate.split(' ').isNotEmpty ? event.displayDate.split(' ')[0] : '',
                  style: AppTheme.body(size: 11, weight: FontWeight.w700, color: AppColors.goldSoft)),
              Text(event.displayDate.split(' ').length > 1 ? event.displayDate.split(' ')[1].replaceAll(',', '') : '',
                  style: AppTheme.heading(size: 18, color: Colors.white)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: AppTheme.heading(size: 15)),
                const SizedBox(height: 4),
                if (event.description.isNotEmpty) Text(event.description, style: AppTheme.body(size: 12.5, color: AppColors.charcoal)),
                const SizedBox(height: 6),
                if (event.time.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.schedule, size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(event.time, style: AppTheme.body(size: 11.5, color: AppColors.muted)),
                  ]),
                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(event.location, style: AppTheme.body(size: 11.5, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
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
