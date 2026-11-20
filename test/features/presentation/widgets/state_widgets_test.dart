import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/widgets/confirm_dialog.dart';
import 'package:permission_app/features/presentation/widgets/empty_state.dart';
import 'package:permission_app/features/presentation/widgets/error_state.dart';
import 'package:permission_app/features/presentation/widgets/loading_state.dart';
import 'package:permission_app/theme/app_theme.dart';

Widget wrap(Widget w) =>
    MaterialApp(theme: AppTheme.light(), home: Scaffold(body: w));

void main() {
  group('EmptyState', () {
    testWidgets('shows the message and the default icon', (t) async {
      await t.pumpWidget(wrap(const EmptyState(message: 'No permits yet.')));
      expect(find.text('No permits yet.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('uses a custom icon', (t) async {
      await t.pumpWidget(
          wrap(const EmptyState(message: 'Nothing', icon: Icons.search_off)));
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsNothing);
    });

    testWidgets('action button calls onAction', (t) async {
      var taps = 0;
      await t.pumpWidget(wrap(EmptyState(
        message: 'No permits yet.',
        actionLabel: 'New permit',
        onAction: () => taps++,
      )));
      await t.tap(find.text('New permit'));
      expect(taps, 1);
    });

    testWidgets('no button when only the label is given', (t) async {
      await t.pumpWidget(
          wrap(const EmptyState(message: 'Nothing', actionLabel: 'Go')));
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('ErrorState', () {
    testWidgets('shows the message and the error icon', (t) async {
      await t.pumpWidget(wrap(const ErrorState(message: 'Could not load.')));
      expect(find.text('Could not load.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('no Retry button without onRetry', (t) async {
      await t.pumpWidget(wrap(const ErrorState(message: 'Could not load.')));
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('Retry calls onRetry', (t) async {
      var retries = 0;
      await t.pumpWidget(
          wrap(ErrorState(message: 'Could not load.', onRetry: () => retries++)));
      await t.tap(find.text('Retry'));
      expect(retries, 1);
    });
  });

  testWidgets('LoadingState shows a progress indicator', (t) async {
    await t.pumpWidget(wrap(const LoadingState()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  group('showConfirmDialog', () {
    bool? result;

    Widget host({
      bool destructive = false,
      String confirm = 'Confirm',
      String cancel = 'Cancel',
    }) =>
        wrap(Builder(
          builder: (c) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmDialog(
                c,
                title: 'Cancel permit?',
                message: 'This cannot be undone.',
                confirmLabel: confirm,
                cancelLabel: cancel,
                destructive: destructive,
              );
            },
            child: const Text('Open'),
          ),
        ));

    Future<void> open(WidgetTester t) async {
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
    }

    setUp(() => result = null);

    testWidgets('shows title and message', (t) async {
      await t.pumpWidget(host());
      await open(t);
      expect(find.text('Cancel permit?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
    });

    testWidgets('confirm returns true', (t) async {
      await t.pumpWidget(host());
      await open(t);
      await t.tap(find.text('Confirm'));
      await t.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('cancel returns false', (t) async {
      await t.pumpWidget(host());
      await open(t);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('tapping outside returns false', (t) async {
      await t.pumpWidget(host());
      await open(t);
      await t.tapAt(const Offset(5, 5));
      await t.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('custom labels are used', (t) async {
      await t.pumpWidget(host(confirm: 'Yes, cancel it', cancel: 'Keep it'));
      await open(t);
      expect(find.text('Yes, cancel it'), findsOneWidget);
      expect(find.text('Keep it'), findsOneWidget);
    });

    testWidgets('destructive confirm button uses the error color', (t) async {
      await t.pumpWidget(host(destructive: true, confirm: 'Delete'));
      await open(t);
      final button =
          t.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Delete'));
      expect(button.style?.backgroundColor?.resolve({}),
          AppTheme.light().colorScheme.error);
    });
  });
}