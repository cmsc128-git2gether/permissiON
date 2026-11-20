import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/shell/app_bottom_bar.dart';
import 'package:permission_app/router/app_router.dart';
import 'package:permission_app/theme/app_theme.dart';

Future<GoRouter> pumpApp(WidgetTester t, {String initial = AppRoutes.home}) async {
  final router = createRouter(initialLocation: initial);
  addTearDown(router.dispose);
  await t.pumpWidget(MaterialApp.router(theme: AppTheme.light(), routerConfig: router));
  await t.pumpAndSettle();
  return router;
}

String pathOf(GoRouter r) => r.routerDelegate.currentConfiguration.uri.path;

Finder tab(String name) => find.byKey(Key('tab-$name'));

Color? iconColor(WidgetTester t, String name) => t
    .widget<Icon>(find.descendant(of: tab(name), matching: find.byType(Icon)))
    .color;

final primary = AppTheme.light().colorScheme.primary;

void main() {
  group('enabled tabs', () {
    testWidgets('starts on Home with the bar visible', (t) async {
      final r = await pumpApp(t);
      expect(find.byKey(const Key('home-screen')), findsOneWidget);
      expect(pathOf(r), AppRoutes.home);
      expect(find.byType(AppBottomBar), findsOneWidget);
    });

    testWidgets('My Permits opens its screen and the bar stays', (t) async {
      final r = await pumpApp(t);
      await t.tap(tab('permits'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('permits-screen')), findsOneWidget);
      expect(pathOf(r), AppRoutes.permits);
      expect(find.byType(AppBottomBar), findsOneWidget);
    });

    testWidgets('Home opens its screen again', (t) async {
      await pumpApp(t);
      await t.tap(tab('permits'));
      await t.pumpAndSettle();
      await t.tap(tab('home'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('home-screen')), findsOneWidget);
    });
  });

  group('disabled tabs', () {
    for (final name in ['notifications', 'profile']) {
      testWidgets('$name does not navigate', (t) async {
        final r = await pumpApp(t);
        await t.tap(tab(name));
        await t.pumpAndSettle();
        expect(pathOf(r), AppRoutes.home);
        expect(find.byKey(const Key('home-screen')), findsOneWidget);
        expect(find.byKey(Key('$name-screen')), findsNothing);
      });

      testWidgets('$name has no tap handler', (t) async {
        await pumpApp(t);
        final ink = t.widget<InkWell>(
            find.descendant(of: tab(name), matching: find.byType(InkWell)));
        expect(ink.onTap, isNull);
      });
    }

    testWidgets('Notifications route shows its placeholder', (t) async {
      await pumpApp(t, initial: AppRoutes.notifications);
      expect(find.byKey(const Key('notifications-screen')), findsOneWidget);
    });

    testWidgets('Profile route shows its placeholder', (t) async {
      await pumpApp(t, initial: AppRoutes.profile);
      expect(find.byKey(const Key('profile-screen')), findsOneWidget);
    });
  });

  group('"+" button', () {
    testWidgets('opens the new permit placeholder without the bar', (t) async {
      await pumpApp(t); // this line was commented out, so nothing was on screen
      await t.tap(find.byKey(const Key('tab-add')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('new-permit-screen')), findsOneWidget);
      expect(find.byType(AppBottomBar), findsNothing);
    });

    testWidgets('going back returns to the tab you were on', (t) async {
      final r = await pumpApp(t);
      await t.tap(tab('permits'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('tab-add')));
      await t.pumpAndSettle();
      r.pop(); // the placeholder has no app bar, so there is no back button to tap
      await t.pumpAndSettle();
      expect(find.byKey(const Key('permits-screen')), findsOneWidget);
      expect(find.byType(AppBottomBar), findsOneWidget);
    });

    testWidgets('has an accessible label', (t) async {
      await pumpApp(t);
      expect(find.byTooltip('File new permit'), findsOneWidget);
      expect(find.text('File new permit'), findsOneWidget);
    });
  });
}