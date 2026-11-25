// Package imports
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/widget_previews.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_app/features/presentation/admin/pending_permits.page.dart';
import 'package:permission_app/features/presentation/permits/permit_wizard_screen.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/models/permit_model.dart';
import 'package:permission_app/services/permit_service.dart';
// Only the student routes are needed. `show` also avoids a name clash,
// since app_router.dart has its own createRouter.
import 'package:permission_app/router/app_router.dart' show studentRoutes;

// File imports
import '../features/presentation/auth_notifier.dart';
import '../features/presentation/admin_dashboard.dart';
import '../features/presentation/dormer_dashboard.dart';
import '../features/presentation/login_screen.dart';
import '../features/presentation/admin_permit_history_screen.dart';
import '../features/presentation/admin/admin_shell.dart';
import '../features/authentication/data/auth_repository.dart';
// Decides where a user should be, given auth status and current location.
// Kept as a pure function so it can be unit tested without Firebase.
//
// Student pages: /home, /permits, /permits/new, /notifications, /profile.
// Admin pages: everything under /admin.
String? redirectFor(AuthStatus status, String location) {
  const publicOnly = {'/splash', '/login'};
  final isAdminPath = location == '/admin' || location.startsWith('/admin/');

  switch (status) {
    case AuthStatus.loading:
      return location == '/splash' ? null : '/splash';

    case AuthStatus.signedOut:
    case AuthStatus.notSetUp:
      return location == '/login' ? null : '/login';

    case AuthStatus.user:
      // Dormers can't see login/splash again, or any admin page.
      if (publicOnly.contains(location) || isAdminPath) return '/home';
      return null;

    case AuthStatus.admin:
      // Admins can only be on /admin pages. This also keeps them out of
      // every student page (/home, /permits, /notifications, ...).
      if (!isAdminPath) return '/admin';
      return null;
  }
}

// Sets up the app's pages and decides who can see which page
GoRouter createRouter(AuthNotifier auth, AuthRepository authRepository) {
  final rootKey = GlobalKey<NavigatorState>();
  // Created once, not on every page build.
  // Assumes PermitService() defaults to FirebaseFirestore.instance.
  final permitService = PermitService();

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

      // Student shell with bottom tabs, defined once in app_router.dart.
      ...studentRoutes(
        rootKey,
        homeBuilder: (_) {
          final user = FirebaseAuth.instance.currentUser;
          // Can briefly be null while signing out; the redirect fixes it.
          if (user == null) return const SplashScreen();

          final name = user.displayName?.trim();
          return StudentHomeScreen(
            service: permitService,
            userId: user.uid,
            // TODO: use given_name from end_user_profiles/{uid}.
            displayName: (name == null || name.isEmpty) ? 'Dormer' : name,
          );
        },
        newPermitBuilder: (_) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          return PermitWizardScreen(
            userId: uid,
            loadFiler: () => authRepository.loadFiler(uid!),
            createPermit: (req, {lateReason}) => permitService.createPermit(
              PermitModel(
                id: '', // firestore assigns the real id
                userId: req.userId,
                surname: req.filer.surname,
                givenName: req.filer.givenName,
                roomNum: req.filer.roomNum,
                floor: req.filer.floor,
                permitType: req.type,
                destination: req.destination,
                purpose: req.purpose,
                emergencyContactPerson: req.contactPerson,
                emergencyContactNum: req.contactNumber,
                expectedTimeIn: req.expectedReturnUtc,
                createdAt: DateTime.now(), // overwritten by the server timestamp
                isLateFiling: lateReason != null,
                lateFilingReason: lateReason,
              ),
              lateReason: lateReason,
            ),
          );
        },
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
            builder: (_, _) {
              final adminId = FirebaseAuth.instance.currentUser!.uid;
              return PendingPermitsPage(
                listen: () => permitService.listenToPendingPermits(),
                onAccept: (p) =>
                    permitService.updatePermitStatus(adminId, p.id, PermitStatus.active.value),
                onDeny: (p, reason) => permitService.updatePermitStatus(
                    adminId, p.id, PermitStatus.denied.value,
                    disapprovalReason: reason),
              );
            },
          ),
          GoRoute(
            path: '/admin/permit-history',
            builder: (context, state) => const AdminPermitHistoryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/admin/permit-history',
        builder: (context, state) => const AdminPermitHistoryScreen(),
      ),
    ],
  );
}

/// Shown while the auth state is still loading.
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