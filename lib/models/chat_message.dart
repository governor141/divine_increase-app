import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message in the shared Community chat (`groupChat` collection).
class ChatMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String text;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.text,
    this.createdAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ChatMessage(
      id: doc.id,
      senderUid: (data['senderUid'] ?? '') as String,
      senderName: (data['senderName'] ?? '') as String,
      text: (data['text'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
