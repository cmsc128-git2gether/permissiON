import 'package:firebase_auth/firebase_auth.dart';

// Turns errors into readable messages for users
String friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      // Wrong email and password share message so attackers
      // wont be able to tell which emails are registered
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
    }
  }
  // Also covers UnimplementedError until #36 is merged
  return 'Something went wrong. Please try again.';
}
