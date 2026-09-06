import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase configuration for Divine Increase.
///
/// The values below are PLACEHOLDERS. They are filled in automatically by
/// the GitHub Actions workflow (.github/workflows/build-apk.yml) using the
/// repository secrets you configure — see README.md, step 4.
///
/// For local testing on your own machine, you can replace the placeholders
/// yourself with the real values from Firebase Console → Project Settings.
/// Never commit your real values to a public repo — that's what the
/// GitHub Actions secrets are for.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) {
      return android;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions have only been configured for Android so far.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'FIREBASE_API_KEY_PLACEHOLDER',
    appId: 'FIREBASE_APP_ID_PLACEHOLDER',
    messagingSenderId: 'FIREBASE_MESSAGING_SENDER_ID_PLACEHOLDER',
    projectId: 'FIREBASE_PROJECT_ID_PLACEHOLDER',
    storageBucket: 'FIREBASE_STORAGE_BUCKET_PLACEHOLDER',
  );
}
