import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores a 4-digit PIN locally on the device only (hashed, never sent
/// anywhere). This is a quick-unlock convenience for returning users, not
/// a backend-verified credential — your Firebase email/password (or later,
/// Google) sign-in remains the real authentication.
class PinService {
  static const _key = 'divine_increase_pin_hash';

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _hash(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    return stored != null && stored == _hash(pin);
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();
}
