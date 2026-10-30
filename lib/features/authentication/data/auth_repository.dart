import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../domain/user_model.dart';

// Handles login state and loads the user's role
class AuthRepository {
    //Constructor declaration
    AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
        : _auth = auth ?? FirebaseAuth.instance,
          _firestore = firestore ?? FirebaseFirestore.instance;
    //Instance variable declarations
    final FirebaseAuth _auth;
    final FirebaseFirestore _firestore;

    Future<void> signIn({required String email, required String password}) async{
        try {
            await _auth.signInWithEmailAndPassword(
                email: email.trim().toLowerCase(),
                password: password,
            );
        } on FirebaseAuthException catch (e) {
          throw _mapError(e);
        } on FirebaseException catch (e) {
          throw FirebaseAuthException(
            code: e.code,
            message: 'Authentication failed. Please try again.',
          );
        }
    }
    Future<void> signUp({required String email, required String password}) async {
        final normalized = email.trim().toLowerCase();
        User? user;
        try {
            final cred = await _auth.createUserWithEmailAndPassword(
                email: normalized,
                password: password,
            );
            user = cred.user!;
        } on FirebaseAuthException catch (e) {
          throw _mapError(e);
        } on FirebaseException catch (e) {
          throw FirebaseAuthException(
            code: e.code,
            message: 'Authentication failed. Please try again.',
          );
        }
        try {
            await _firestore.collection('users').doc(user.id).set({
                'email': normalized,
                'access_level': 'end_user',
                'created_at': FieldValue.serverTimestamp(),
            });
        } catch (_){
            //Roll back, so the email is not stranded in an unusable state.
            await user.delete();
            rethrow;
        }
    }
    Future<void> signOut() => _auth.signOut();







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
  FirebaseAuthException _mapError(FirebaseAuthException e){
    final message = switch (e.code){
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found'=> 'Incorrect email or password.',
        'email-already-in-use' => 'That email is already registered.',
        'weak-password' => 'Password is too weak (min 6 characters).',
        'invalid-email' => 'Please enter a valid email address.',
        _ => 'Authentication failed. Please try again.',
    };
    return FirebaseAuthException(
        code: e.code,
        message: message,
        email: e.mail,
        plugin: e.plugin,
        stackTrace: e.stackTrace,
    );
  }
}
