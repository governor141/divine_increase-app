import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which notifications this device has already seen/read. This is
/// LOCAL (per-device) tracking, not stored in Firestore -- the
/// `notifications` collection has no read/unread field of its own, which
/// matches how the website appears to behave too (read state resets if you
/// clear browser data, same as this will reset if the app is reinstalled).
class NotificationReadService {
  static const _key = 'read_notification_ids';

  static Future<Set<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  static Future<void> markRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? []).toSet();
    ids.add(id);
    await prefs.setStringList(_key, ids.toList());
  }

  static Future<void> markAllRead(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? []).toSet();
    current.addAll(ids);
    await prefs.setStringList(_key, current.toList());
  }
}
