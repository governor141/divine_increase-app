import 'package:cloud_firestore/cloud_firestore.dart';

/// A daily prayer/declaration audio post, from the `voiceDeclarations`
/// Firestore collection (posted via your Telegram bot).
class Declaration {
  final String id;
  final String title;
  final String audioUrl;
  final DateTime? createdAt;

  const Declaration({
    required this.id,
    required this.title,
    required this.audioUrl,
    this.createdAt,
  });

  factory Declaration.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Declaration(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      audioUrl: (data['audioUrl'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
