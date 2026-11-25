// ../features/auth/presentation/auth_notifier.dart
// This holds the app's current authentication state and exposes it to
// the UI. It also subscribes it to the auth stream from AuthRepository,
// converts each user into a simple AuthStatus value, and calls
// notifyListerners() so routers can react.
//

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../authentication/data/auth_repository.dart';
import '../authentication/domain/auth_state.dart';
import '../authentication/domain/user_model.dart';

// The possible authentication states the app can be in:
// - loading:    haven't received the first auth event yet (e.g. splash screen)
// - signedOut:  no user is logged in
// - user:       a regular user is logged in
// - admin:      a user with admin privileges is logged in
enum AuthStatus { loading, signedOut, notSetUp, user, admin }

// A ChangeNotifier that widgets can listen to for auth changes.
class AuthNotifier extends ChangeNotifier {
  // Constructor: takes the repository and immediately starts listening
  // to its auth state stream.
  AuthNotifier(AuthRepository repo) {
    _sub = repo.authStateStream.listen(
      // Called every time the auth state changes (login, logout, etc.).
      (authState) {
        status = switch (authState) {
          AuthLoading() => AuthStatus.loading,
          AuthSignedOut() => AuthStatus.signedOut,
          AuthNotSetUp() => AuthStatus.notSetUp,
          AuthSignedIn(:final user) when user.isAdmin => AuthStatus.admin,
          AuthSignedIn() => AuthStatus.user,
        };
        currentUser = switch (authState) {
          AuthSignedIn(:final user) => user,
          _ => null,
        };
        // Tell listening widgets to rebuild with the new state.
        notifyListeners();
      },
      // Called if the stream emits an error.
      onError: (_) {
        // Don't leave the app stuck on the splash screen if the stream errors.
        // Fall back to a signed-out state so the user can at least log in.
        currentUser = null;
        status = AuthStatus.signedOut;
        notifyListeners();
      },
    );
  }
  // Current auth status, starts as `loading`.
  AuthStatus status = AuthStatus.loading;
  // The currently logged-in user, or null if signed out / not yet known.
  AppUser? currentUser;
  // Subscription to the auth stream. `late final` because it's assigned
  // in the constructor body, not at declaration. So it can be cancelled.
  late final StreamSubscription<AuthState> _sub;
  // Cleanup: cancel the stream subscription when the notifier is disposed
  // to avoid memory leaks and callbacks firing after disposal.
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
