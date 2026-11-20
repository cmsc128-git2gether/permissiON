import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../../errors/auth_failure.dart';
import '../../../errors/login_auth_error_messages.dart';
import '../domain/auth_state.dart';
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

  static const _secondaryAppName = 'adminCreate';

  /// Signs an existing user in with email and password.
  ///
  /// The email is trimmed and lowercased so that "User@Mail.com " and
  /// "user@mail.com" resolve to the same account.
  ///
  /// Throws an [AuthFailure] with a user-friendly message if authentication
  /// fails.
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.code, friendlyAuthError(e));
    } on FirebaseException catch (e) {
      throw AuthFailure(e.code, friendlyAuthError(e));
    }
  }

  /// Lets a signed-in admin create an account + profile for another admin.
  ///
  /// Uses a temporary secondary Firebase app so the calling admin's own
  /// session is not replaced by the new user's.
  ///
  /// The admin check here is only a UX guard. Real enforcement must be in
  /// Firestore security rules.
  Future<void> createAdminAccount({
    required String email,
    required String password,
  }) async {
    final caller = _auth.currentUser;
    if (caller == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'You must be signed in.',
      );
    }

    try {
      final callerDoc = await _firestore
          .collection('users')
          .doc(caller.uid)
          .get();
      if (callerDoc.data()?['access_level'] != 'admin') {
        throw FirebaseAuthException(
          code: 'permission-denied',
          message: 'Only admins can create admin accounts.',
        );
      }
    } on FirebaseException catch (e) {
      if (e is FirebaseAuthException) rethrow;
      throw FirebaseAuthException(
        code: e.code,
        message: 'Could not verify permissions. Please try again.',
      );
    }

    final normalized = email.trim().toLowerCase();

    // Reuse the secondary app if a previous run left it behind;
    // initializeApp would throw "duplicate-app" otherwise.
    FirebaseApp secondaryApp;
    try {
      secondaryApp = Firebase.app(_secondaryAppName);
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: _secondaryAppName,
        options: Firebase.app().options,
      );
    }
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      // 1. Create the Auth account on the secondary app.
      final User newUser;
      try {
        final cred = await secondaryAuth.createUserWithEmailAndPassword(
          email: normalized,
          password: password,
        );
        newUser = cred.user!;
      } on FirebaseAuthException catch (e) {
        throw _mapError(e);
      } on FirebaseException catch (e) {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Authentication failed. Please try again.',
        );
      }

      // 2. Write the profile using the calling admin's own session.
      try {
        await _firestore.collection('users').doc(newUser.uid).set({
          'email': normalized,
          'access_level': 'admin',
          'created_at': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        await newUser.delete(); // Roll back the orphaned Auth account.
        rethrow;
      }
    } finally {
      await secondaryAuth.signOut();
      await secondaryApp.delete();
    }
  }

  /// Signs the current user out of Firebase Authentication.
  Future<void> signOut() => _auth.signOut();

  // Emits loading before resolving the current Firebase Authentication state.
  Stream<AuthState> get authStateStream async* {
    yield AuthState.loading;

    await for (final firebaseUser in _auth.authStateChanges()) {
      if (firebaseUser == null) {
        yield AuthState.signedOut;
        continue;
      }

      try {
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        final data = doc.data();
        if (!doc.exists || data == null) {
          yield AuthState.notSetUp;
          continue;
        }

        // Throws if access_level is missing or unknown; handled below as
        // notSetUp, so a bad role never silently becomes end_user.
        yield AuthState.signedIn(
          AppUser.fromFirestore(
            data,
            firebaseUser.uid,
            firebaseUser.email ?? '',
          ),
        );
      } catch (e) {
        debugPrint('Failed to load user doc: $e');
        yield AuthState.notSetUp;
      }
    }
  }

  /// Converts a raw [FirebaseAuthException] into one with a user-friendly message.
  ///
  /// The original error code is preserved so callers can still branch on it
  /// such as to highlight a specific form field, while the message is safe to
  /// show directly in the UI.
  FirebaseAuthException _mapError(FirebaseAuthException e) {
    // Sign-in failures share one message on purpose. Telling the user whether
    // the email or the password was wrong would let attackers discover which
    // emails are registered (user enumeration)
    final message = switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Incorrect email or password.',
      // Admin account creation errors.
      'email-already-in-use' => 'That email is already registered.',
      'weak-password' => 'Password is too weak (min 6 characters).',
      // Also applies to admin account creation.
      'invalid-email' => 'Please enter a valid email address.',
      // Catch-all for unexpected codes so raw Firebase never reaches the user
      _ => 'Authentication failed. Please try again.',
    };
    // Rebuild the exception with the friendly message, copying over the
    // original metadata so debugging information isn't lost.
    return FirebaseAuthException(
      code: e.code,
      message: message,
      email: e.email,
    );
  }
}