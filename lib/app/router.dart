// Package imports
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

// File imports
import '../features/presentation/auth_notifier.dart';
import 'package:flutter/widget_previews.dart';
import '../features/presentation/admin_dashboard.dart';
import '../features/presentation/dormer_dashboard.dart';
import '../features/presentation/login_screen.dart';
import '../features/presentation/admin_permit_history_screen.dart';

import '../features/authentication/data/auth_repository.dart';

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
GoRouter createRouter(AuthNotifier auth, AuthRepository authRepository) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) =>
        redirectFor(auth.status, state.matchedLocation),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(authRepository: authRepository),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/permit-history',
        builder: (context, state) => const AdminPermitHistoryScreen(),
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

//Preview of the Splash Screen
@Preview(name: 'Splash Screen Preview')
Widget splashScreenPreview() {
  return const SplashScreen();
}
