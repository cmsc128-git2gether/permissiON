import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../domain/user_model.dart';
import 'package:permission_app/errors/auth_failure.dart';

// Handles login state and loads the user's role
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;


  //--- sign in and sign up to be implemented in issue #36, for now throws unimplemented error ---
  Future<void> signIn({required String email, required String password}) async {
    throw UnimplementedError('signIn');
  }

  Future<void> signUp({required String email, required String password}) async {
    throw UnimplementedError('signUp');
  }
  // ----------------------------------------------------------------------------------------------

  // Gives an AppUser (with role) when someone logs in, or null when they log out
  Stream<AppUser?> get authStateStream {
    // Runs every time the login state changes
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      // Nobody is logged in
      if (firebaseUser == null) return null;

      try {
        // Get this user's document from the "users" collection
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        // Turn the document into an AppUser (includes the role)
        return AppUser.fromFirestore(
          doc.data(),
          firebaseUser.uid,
          firebaseUser.email ?? '', // Use empty text if there's no email
        );
      } on FirebaseException catch (e) {
        debugPrint('Failed to load user doc: ${e.code} - ${e.message}');

        // Fall back to the safe role 'end_user'
        return AppUser.fromFirestore(
          null,
          firebaseUser.uid,
          firebaseUser.email ?? '',
        );
      }
    });
  }

  Future<void> signOut() => _auth.signOut();
}
