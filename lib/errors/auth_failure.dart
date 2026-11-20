// A sign-in problem with a message that is safe to show to the user.
// Thrown by AuthRepository.signIn. The message text comes from
// friendlyAuthError (login_auth_error_messages.dart), the single place
// where error codes become user-facing text.
class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  // The Firebase error code this came from, e.g. 'wrong-password'
  final String code;

  // Friendly text for the login screen (HCI)
  final String message;

  @override
  String toString() => message;
}