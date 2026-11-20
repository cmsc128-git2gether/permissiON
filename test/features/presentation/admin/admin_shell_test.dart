import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:permission_app/features/presentation/admin/admin_shell.dart';
import 'package:permission_app/features/presentation/auth_notifier.dart';
import 'package:permission_app/app/router.dart';

const _email = 'admin@up.edu.ph';

({Widget app, GoRouter router}) buildApp({VoidCallback? onLogout}) {
  final router = GoRouter(
    initialLocation: '/admin/permit-logs',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AdminShell(
          email: _email,
          onLogout: onLogout ?? () {},
          currentPath: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/admin/permit-logs',
            builder: (_, _) => const Text('permit logs page'),
          ),
          GoRoute(
            path: '/admin/delinquency',
            builder: (_, _) => const Text('delinquency page'),
          ),
          GoRoute(
            path: '/admin/room-check',
            builder: (_, _) => const Text('room check page'),
          ),
        ],
      ),
    ],
  );
  return (app: MaterialApp.router(routerConfig: router), router: router);
}

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('sidebar renders its items', (tester) async {
    setSize(tester, const Size(1200, 800));
    await tester.pumpWidget(buildApp().app);
    await tester.pumpAndSettle();

    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Permit Logs'), findsOneWidget);
    expect(find.text('Delinquency Tracker'), findsOneWidget);
    expect(find.text('Room Check'), findsOneWidget);
  });

  testWidgets('disabled items do not navigate', (tester) async {
    setSize(tester, const Size(1200, 800));
    final built = buildApp();
    await tester.pumpWidget(built.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delinquency Tracker'));
    await tester.tap(find.text('Room Check'));
    await tester.pumpAndSettle();

    final path = built.router.routerDelegate.currentConfiguration.uri.path;
    expect(path, '/admin/permit-logs');
  });

  testWidgets('shows the signed-in email', (tester) async {
    setSize(tester, const Size(1200, 800));
    await tester.pumpWidget(buildApp().app);
    await tester.pumpAndSettle();

    expect(find.text('Signed in as $_email'), findsOneWidget);
  });

  testWidgets('Log out signs out', (tester) async {
    setSize(tester, const Size(1200, 800));
    final auth = MockFirebaseAuth(signedIn: true);
    await tester.pumpWidget(buildApp(onLogout: () => auth.signOut()).app);
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNotNull);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNull);
  });

  testWidgets('drawer appears at a narrow width', (tester) async {
    setSize(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp().app);
    await tester.pumpAndSettle();

    expect(find.text('Permit Logs'), findsNothing); // sidebar hidden

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('Permit Logs'), findsOneWidget);
  });

  test('a student is redirected away from /admin', () {
    expect(redirectFor(AuthStatus.user, '/admin/permit-logs'), '/home');
    expect(redirectFor(AuthStatus.user, '/admin'), '/home');
  });
}
