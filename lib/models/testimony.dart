import 'package:cloud_firestore/cloud_firestore.dart';

/// A testimony from the `testimonies` Firestore collection. Only
/// documents with status == "approved" should be shown publicly —
/// anything else is awaiting admin review.
class Testimony {
  final String id;
  final String authorName;
  final String category;
  final String title;
  final String testimony;
  final String status;
  final DateTime? createdAt;

  const Testimony({
    required this.id,
    required this.authorName,
    required this.category,
    required this.title,
    required this.testimony,
    required this.status,
    this.createdAt,
  });

  factory Testimony.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Testimony(
      id: doc.id,
      authorName: (data['authorName'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      testimony: (data['testimony'] ?? '') as String,
      status: (data['status'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
