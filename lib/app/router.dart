// Package imports
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// File imports
import '../features/authentication/domain/user_model.dart';
import '../features/authentication/presentation/admin_dashboard.dart';
import '../features/authentication/presentation/dormer_dashboard.dart';
import '../features/authentication/presentation/login_screen.dart';

// Sets up the app's pages and decides who can see which page
GoRouter createRouter(Stream<AppUser?> authStream) {
  AppUser? user; // latest known user
  authStream.listen((u) => user = u);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';

      if (user == null) return isLoggingIn ? null : '/login';
      if (isLoggingIn) return user!.isAdmin ? '/admin' : '/home';
      if (state.matchedLocation.startsWith('/admin') && !user!.isAdmin) {
        return '/home';
      }
      return null;
    },

    // The list of pages in the app
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
}

// Lets GoRouter listen to a Stream (GoRouter only accepts a Listenable)
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    // Trigger one refresh right away
    notifyListeners();

    // Trigger a refresh every time the stream emits something
    stream.listen((_) => notifyListeners());
  }
}
