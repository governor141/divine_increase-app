import 'package:cloud_firestore/cloud_firestore.dart';

/// An event from the `events` Firestore collection. eventDate is stored
/// as a plain "YYYY-MM-DD" string (which happens to sort correctly as
/// text), and time is a separate free-text string like "9:00PM -5:00AM".
class Event {
  final String id;
  final String title;
  final String description;
  final String eventDate;
  final String time;
  final String location;
  final DateTime? createdAt;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.time,
    required this.location,
    this.createdAt,
  });

  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Event(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      eventDate: (data['eventDate'] ?? '') as String,
      time: (data['time'] ?? '') as String,
      location: (data['location'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// A friendlier display of eventDate, e.g. "2026-09-01" -> "Sep 1, 2026".
  String get displayDate {
    try {
      final parts = eventDate.split('-');
      if (parts.length != 3) return eventDate;
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[int.parse(parts[1])];
      return '$month ${int.parse(parts[2])}, ${parts[0]}';
    } catch (_) {
      return eventDate;
    }
  }
}
