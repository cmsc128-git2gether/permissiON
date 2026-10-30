// ../features/auth/presentation/auth_notifier.dart
// This holds the app's current authentication state and exposes it to
// the UI. It also subscribes it to the auth stream from AuthRepository,
// converts each user into a simple AuthStatus value, and calls
// notifyListerners() so routers can react.
//

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';
// The possible authentication states the app can be in:
// - unknown:    haven't received the first auth event yet (e.g. splash screen)
// - signedOut:  no user is logged in
// - user:       a regular user is logged in
// - admin:      a user with admin privileges is logged in
enum AuthStatus { unknown, signedOut, user, admin }
// A ChangeNotifier that widgets can listen to for auth changes.
class AuthNotifier extends ChangeNotifier {
  // Constructor: takes the repository and immediately starts listening
  // to its auth state stream.
  AuthNotifier(AuthRepository repo) {
    _sub = repo.authStateStream.listen(
      // Called every time the auth state changes (login, logout, etc.).
      (appUser) {
        // Save the latest user (null if signed out).
        currentUser = appUser;
        // Map the user to a status using pattern matching:
        // - null user        -> signedOut
        // - user with admin  -> admin
        // - any other user   -> user
        status = switch (appUser) {
          null => AuthStatus.signedOut,
          AppUser(isAdmin: true) => AuthStatus.admin,
          _ => AuthStatus.user,
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
  // Current auth status, starts as `unknown`
  AuthStatus status = AuthStatus.unknown; // stays here until the FIRST event
  // The currently logged-in user, or null if signed out / not yet known.
  AppUser? currentUser;
  // Subscription to the auth stream. `late final` because it's assigned
  // in the constructor body, not at declaration. So it can be cancelled.
  late final StreamSubscription<AppUser?> _sub;
  // Cleanup: cancel the stream subscription when the notifier is disposed
  // to avoid memory leaks and callbacks firing after disposal.
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}