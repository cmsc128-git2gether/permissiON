// Package imports
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/widget_previews.dart';
import 'package:firebase_auth/firebase_auth.dart';

// File imports
import '../features/presentation/auth_notifier.dart';
import '../features/presentation/admin_dashboard.dart';
import '../features/presentation/dormer_dashboard.dart';
import '../features/presentation/login_screen.dart';
import '../features/presentation/admin_permit_history_screen.dart';
import '../features/presentation/admin/admin_shell.dart';
import '../features/authentication/data/auth_repository.dart';

// Pages that belong to the student shell.

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
  final rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
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
      // student shell: /home, /permits, /permits/new, /notifications, /profile
      GoRoute(
        path: '/home',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(path: '/admin', redirect: (_, _) => '/admin/permit-logs'),

      ShellRoute(
        builder: (context, state, child) => AdminShell(
          email: FirebaseAuth.instance.currentUser?.email ?? '',
          onLogout: authRepository.signOut,
          currentPath: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/admin/permit-logs',
            builder: (_, _) =>
                const AdminDashboardScreen(), // temporary until PermitLogsPage exists
          ),
          GoRoute(
            path: '/admin/permit-history',
            builder: (context, state) => const AdminPermitHistoryScreen(),
          ),
        ],
      ),
    ],
  );
}

/// For tests and the preview only. The app uses createRouter in app/router.dart.
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
