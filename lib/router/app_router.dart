import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/shell/app_shell.dart';
import 'package:permission_app/features/presentation/shell/placeholder_screen.dart';

class AppRoutes {
  static const home = '/home';
  static const permits = '/permits';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const newPermit = '/permits/new';
}

/// The student (dormer) pages: the bottom-tab shell plus the "new permit"
/// page that sits on top of it.
///
/// Shared by the real app router and by [createRouter] below, so the
/// student routes are defined in exactly one place.
///
/// [rootKey] must be the same key given to the parent GoRouter's
/// `navigatorKey`, so "new permit" opens above the bottom bar.
/// Any builder left null falls back to a placeholder screen.
List<RouteBase> studentRoutes(
  GlobalKey<NavigatorState> rootKey, {
  WidgetBuilder? homeBuilder,
  WidgetBuilder? newPermitBuilder,
}) {
  return [
    /// Order must match the order of `BottomTab.values`.
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, _) =>
                homeBuilder?.call(context) ??
                const PlaceholderScreen(
                    key: Key('home-screen'), title: 'Home', showAppBar: true),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.permits,
            builder: (_, _) => const PlaceholderScreen(
                key: Key('permits-screen'),
                title: 'My Permits',
                showAppBar: true),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, _) => const PlaceholderScreen(
                key: Key('notifications-screen'),
                title: 'Notifications',
                showAppBar: true),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) => const PlaceholderScreen(
                key: Key('profile-screen'), title: 'Profile', showAppBar: true),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: AppRoutes.newPermit,
      parentNavigatorKey: rootKey,
      builder: (context, _) =>
          newPermitBuilder?.call(context) ??
          const PlaceholderScreen(
              key: Key('new-permit-screen'),
              title: 'New permit request',
              showAppBar: false),
    ),
  ];
}

/// Standalone student-only router (no login, no admin).
/// Used by preview_mobile_shell.dart and widget tests.
/// The real app uses the auth-aware router instead.
GoRouter createRouter({
  String initialLocation = AppRoutes.home,
  WidgetBuilder? homeBuilder,
  WidgetBuilder? newPermitBuilder,
}) {
  final rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    routes: studentRoutes(
      rootKey,
      homeBuilder: homeBuilder,
      newPermitBuilder: newPermitBuilder,
    ),
  );
}