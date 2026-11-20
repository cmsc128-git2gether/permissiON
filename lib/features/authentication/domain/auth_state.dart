import 'user_model.dart';

sealed class AuthState {
  const AuthState();

  // Waiting for Firebase (and the users/{uid} lookup) to answer
  static const loading = AuthLoading();

  // No Firebase user
  static const signedOut = AuthSignedOut();

  // Signed in to Firebase, but the account can't be used: users/{uid} is missing
  // has no valid access_level, or could not be read.
  static const notSetUp = AuthNotSetUp();

  // Signed in, with a users/{uid} doc and a valid role
  factory AuthState.signedIn(AppUser user) = AuthSignedIn;
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

class AuthNotSetUp extends AuthState {
  const AuthNotSetUp();
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);

  final AppUser user;
}