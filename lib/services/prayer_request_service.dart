import 'dart:convert';
import 'package:http/http.dart' as http;

/// Sends a prayer request to the ministry's Telegram via the same
/// Cloudflare Worker the website uses (NOT Firestore — this feature has
/// no database collection; it is a direct notification pipe to Telegram).
///
/// Website reference: index.html, "Prayer Request -> Cloudflare Worker ->
/// Telegram" section — same URL, same JSON body shape, same success check.
class PrayerRequestService {
  static const String _workerUrl =
      'https://divine-increase-prayer.governoreze24.workers.dev/';

  /// Throws an [Exception] with a human-readable message if the request
  /// fails, so callers can show it directly in a SnackBar.
  static Future<void> submit({
    required String name,
    required String businessName,
    required String prayerRequest,
  }) async {
    final response = await http.post(
      Uri.parse(_workerUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'businessName': businessName,
        'prayerRequest': prayerRequest,
      }),
    );

    Map<String, dynamic> result = {};
    try {
      result = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // Non-JSON or empty body — result stays empty, handled below.
    }

    final success = result['success'] == true;
    if (response.statusCode != 200 || !success) {
      throw Exception(
        (result['message'] as String?) ??
            'Unable to send prayer request. Please try again.',
      );
    }
  }
}
