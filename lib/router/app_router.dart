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

/// Branch order must match the order of `BottomTab.values`.
GoRouter createRouter({
  String initialLocation = AppRoutes.home,
  WidgetBuilder? newPermitBuilder,
}) {
  final rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) =>
                  const PlaceholderScreen(key: Key('home-screen'), title: 'Home', showAppBar: false)
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.permits,
              builder: (_, _) =>
                  const PlaceholderScreen(key: Key('permits-screen'), title: 'My Permits', showAppBar: false)
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.notifications,
              builder: (_, _) => const PlaceholderScreen(title: 'Notifications'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, _) => const PlaceholderScreen(title: 'Profile'),
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
                key: Key('new-permit-screen'), title: 'New permit request'),
      ),
    ],
  );
}