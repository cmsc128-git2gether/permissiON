import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/widgets/confirm_dialog.dart';
import 'package:permission_app/features/presentation/widgets/empty_state.dart';
import 'package:permission_app/features/presentation/widgets/error_state.dart';
import 'package:permission_app/features/presentation/widgets/status_chip.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/theme/app_theme.dart';

///for now uses shared components. add respective tests for mobile-specific components when they are created.
Future<void> pumpPhone(WidgetTester t, Widget child, {double textScale = 1}) async {
  t.view.physicalSize = const Size(360, 640);
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child)));
}

void main() {
  group('tap targets (at least 44 high)', () {
    testWidgets('EmptyState action button', (t) async {
      await pumpPhone(
          t, EmptyState(message: 'No permits yet.', actionLabel: 'New permit', onAction: () {}));
      expect(t.getSize(find.byType(ElevatedButton)).height, greaterThanOrEqualTo(44));
    });

    testWidgets('ErrorState Retry button', (t) async {
      await pumpPhone(t, ErrorState(message: 'Could not load.', onRetry: () {}));
      expect(t.getSize(find.byType(ElevatedButton)).height, greaterThanOrEqualTo(44));
    });

    testWidgets('confirm dialog buttons', (t) async {
      await pumpPhone(
        t,
        Builder(
          builder: (c) => ElevatedButton(
            onPressed: () => showConfirmDialog(c, title: 'Cancel permit?', message: 'Sure?'),
            child: const Text('Open'),
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      expect(t.getSize(find.widgetWithText(TextButton, 'Cancel')).height,
          greaterThanOrEqualTo(44));
      expect(t.getSize(find.widgetWithText(ElevatedButton, 'Confirm')).height,
          greaterThanOrEqualTo(44));
    });
  });

  group('large text on a small phone (2x), no overflow', () {
    testWidgets('EmptyState with a long message', (t) async {
      await pumpPhone(
        t,
        EmptyState(
          message: 'You have no permits yet. Tap the button below to request your first one.',
          actionLabel: 'New permit',
          onAction: () {},
        ),
        textScale: 2,
      );
      expect(t.takeException(), isNull);
    });

    testWidgets('ErrorState with a long message', (t) async {
      await pumpPhone(
        t,
        ErrorState(
          message: 'We could not load your permits. Check your connection and try again.',
          onRetry: () {},
        ),
        textScale: 2,
      );
      expect(t.takeException(), isNull);
    });

    testWidgets('confirm dialog', (t) async {
      await pumpPhone(
        t,
        Builder(
          builder: (c) => ElevatedButton(
            onPressed: () => showConfirmDialog(
              c,
              title: 'Cancel this permit?',
              message: 'Your guardian will be notified and this cannot be undone.',
              confirmLabel: 'Yes, cancel it',
              cancelLabel: 'Keep it',
            ),
            child: const Text('Open'),
          ),
        ),
        textScale: 2,
      );
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('every StatusChip banner', (t) async {
      await pumpPhone(
        t,
        Column(children: [
          for (final s in PermitStatus.values) StatusChip(s, expanded: true),
        ]),
        textScale: 2,
      );
      expect(t.takeException(), isNull);
    });
  });

  group('StatusChip banner on a phone', () {
    testWidgets('expanded chip spans the screen width', (t) async {
      await pumpPhone(t, const StatusChip(PermitStatus.active, expanded: true));
      expect(t.getSize(find.byType(StatusChip)).width, 360);
    });
  });
}