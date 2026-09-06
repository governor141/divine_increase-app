import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Authentication.
///
/// Phase 1 supports email/password only. Google Sign-In is intentionally
/// left out for now — it needs your app's SHA-1 fingerprint registered in
/// Firebase Console first (see README.md, "Phase 2: Google Sign-In").
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(fullName.trim());
    return cred;
  }

  Future<void> signOut() => _auth.signOut();
}
