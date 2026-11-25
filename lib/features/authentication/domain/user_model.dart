import 'package:permission_app/models/data_enums.dart';

// Model for user and their role
class AppUser {
  final String uid; // Firebase Auth user ID
  final String email; // User's email from Firebase Auth
  final String accessLevel; // Role: 'admin' or 'end_user'

  AppUser({required this.uid, required this.email, required this.accessLevel});

  // Returns True if this user's role is admin; use for role-based routing
  bool get isAdmin => accessLevel == 'admin';

  // Builds an AppUser from the Firestore doc at users/{uid}
  //
  // Throws if access_level is missing or not a known role. A bad or missing
  // role must never silently become 'end_user'; AuthRepository catches the
  // error and reports AuthState.notSetUp.
  factory AppUser.fromFirestore(
    Map<String, dynamic>? data,
    String uid,
    String email,
  ) {
    // AccessLevel.fromString throws ArgumentError on an unknown value
    final level = AccessLevel.fromString(
      (data?['access_level'] as String?) ?? '',
    );

    return AppUser(uid: uid, email: email, accessLevel: level.value);
  }
}