// Model for user and their role
class AppUser {
  final String uid; // Firebase Auth user ID
  final String email; // User's email from Firebase Auth
  final String accessLevel; // Role: 'admin' or 'end_user'

  AppUser({required this.uid, required this.email, required this.accessLevel});

  // Returns True if this user's role is admin; use for role-based routing
  bool get isAdmin => accessLevel == 'admin';

  // Builds an AppUser from the Firestore doc at users/{uid}
  factory AppUser.fromFirestore(
    Map<String, dynamic>? data,
    String uid,
    String email,
  ) {
    return AppUser(
      uid: uid,
      email: email,

      // Read the role; defaults to 'end_user'
      accessLevel: data?['access_level'] ?? 'end_user',
    );
  }
}
