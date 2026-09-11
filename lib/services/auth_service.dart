import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps Firebase Authentication -- email/password and Google Sign-In.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // serverClientId is the WEB OAuth client (from Google Cloud Console,
  // auto-created by Firebase alongside the Android client), NOT the Android
  // client ID. Firebase needs this to actually verify the Google sign-in --
  // without it, the account picker shows fine but sign-in fails right after
  // an account is chosen, for every account. This is separate from the
  // Android app's registered SHA-1 fingerprint (both are required).
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '978041285468-8g13nvbtieuiqbfc63pgobujnju3a699.apps.googleusercontent.com',
  );

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

  /// Signs in with Google. Returns null if the user cancels the picker.
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
