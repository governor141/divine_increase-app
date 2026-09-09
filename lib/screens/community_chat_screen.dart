import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

/// A single shared community chat room, backed by the `groupChat`
/// Firestore collection. Everyone in the network posts into the same
/// stream — this isn't private messaging.
class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final _textCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final user = FirebaseAuth.instance.currentUser;
    try {
      await FirebaseFirestore.instance.collection('groupChat').add({
        'senderUid': user?.uid ?? '',
        'senderName': user?.displayName ?? 'Kingdom Member',
        'senderEmail': user?.email ?? '',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _textCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final query = FirebaseFirestore.instance.collection('groupChat').orderBy('createdAt', descending: true).limit(200);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Community', style: AppTheme.heading(size: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.navy));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Could not load messages.', style: AppTheme.body(color: AppColors.muted)));
                }
                final messages = (snapshot.data?.docs ?? []).map(ChatMessage.fromFirestore).toList();
                if (messages.isEmpty) {
                  return Center(child: Text('No messages yet — say hello!', style: AppTheme.body(color: AppColors.muted)));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isMe = m.senderUid.isNotEmpty && m.senderUid == myUid;
                    // messages[] is newest-first. The item "above" this one
                    // on screen (i+1) is the next-older message. Show a day
                    // divider right above this message whenever its day
                    // differs from the next-older one (or this is the very
                    // oldest message loaded).
                    final olderNeighbor = (i + 1 < messages.length) ? messages[i + 1].createdAt : null;
                    final showDivider = m.createdAt != null && !_isSameDay(m.createdAt, olderNeighbor);
                    return Column(
                      children: [
                        if (showDivider) _DayDivider(date: m.createdAt!),
                        _MessageBubble(message: m, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cream2,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _textCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTheme.body(size: 14),
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
                        hintStyle: AppTheme.body(size: 14, color: AppColors.muted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.navy),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldSoft),
                          )
                        : const Icon(Icons.send, color: AppColors.goldSoft, size: 18),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// WhatsApp-style label: "Today", "Yesterday", a weekday name for the last
/// week, or a full date for anything older.
String _dayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';

  const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  if (diff > 1 && diff < 7) return weekdays[date.weekday - 1];

  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month]} ${date.day}, ${date.year}';
}

/// 12-hour time like "9:41 AM" — matches WhatsApp's per-message time style.
String _timeLabel(DateTime date) {
  final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

class _DayDivider extends StatelessWidget {
  final DateTime date;
  const _DayDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: AppColors.cream2, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(20)),
          child: Text(_dayLabel(date), style: AppTheme.body(size: 11, weight: FontWeight.w600, color: AppColors.muted)),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.navy : AppColors.cream2,
          border: isMe ? null : Border.all(color: AppColors.line),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(message.senderName, style: AppTheme.body(size: 11, weight: FontWeight.w700, color: AppColors.sage)),
              ),
            Text(message.text, style: AppTheme.body(size: 13.5, color: isMe ? Colors.white : AppColors.charcoal)),
            if (message.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _timeLabel(message.createdAt!),
                  style: AppTheme.body(size: 10, color: isMe ? Colors.white70 : AppColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
