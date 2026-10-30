class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  final String code;
  final String message;  //show to user, e.g. 'The email address is already in use by another account.'

  @override
  String toString() => 'AuthFailure($code): $message';
}