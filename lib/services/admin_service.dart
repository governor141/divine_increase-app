import 'package:firebase_auth/firebase_auth.dart';

/// Mirrors the isAdmin() email allowlist from the Firestore security rules
/// — this is ONLY for showing/hiding admin buttons in the app UI. It grants
/// no extra access by itself; Firestore's own rules are what actually
/// enforce who can write admin-only data. Keep this list in sync with the
/// Firestore rules if admins are ever added/removed.
const List<String> kAdminEmails = [
  'governoreze24@gmail.com',
  'prophettitusministry@gmail.com',
  'chinonyeokoro16@gmail.com',
  'okoro.chinenye2015@gmail.com',
  'okoroblessing846@gmail.com',
  'amychidd@gmail.com',
  'ifeanyieze873@gmail.com',
];

bool get isCurrentUserAdmin {
  final email = FirebaseAuth.instance.currentUser?.email;
  return email != null && kAdminEmails.contains(email);
}
