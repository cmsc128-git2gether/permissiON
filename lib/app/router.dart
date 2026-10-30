// Package imports
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// File imports
import '../features/authentication/domain/user_model.dart';
import '../features/authentication/presentation/admin_dashboard.dart';
import '../features/authentication/presentation/dormer_dashboard.dart';
import '../features/authentication/presentation/login_screen.dart';

// Decides where a user should be, given auth status and current location.
// Kept as a pure function so it can be unit tested without Firebase.
String? redirectFor(AuthStatus status, String location) {
  const publicOnly = {'/splash', '/login'};

  switch (status) {
    case AuthStatus.unknown:
      return location == '/splash' ? null : '/splash';

    case AuthStatus.signedOut:
      return location == '/login' ? null : '/login';

    case AuthStatus.user:
      if (publicOnly.contains(location) || location.startsWith('/admin')) {
        return '/home';
      }
      return null;

    case AuthStatus.admin:
      if (publicOnly.contains(location) || location == '/home') {
        return '/admin';
      }
      return null;
  }
}

// Sets up the app's pages and decides who can see which page
GoRouter createRouter(AuthNotifier auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) =>
        redirectFor(auth.status, state.matchedLocation),
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
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

// Shown until the first auth event arrives
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}