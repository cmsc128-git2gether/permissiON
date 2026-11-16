import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/permits/late_filing_dialog.dart';

/// Host with one button that runs [onTap], so dialogs have a real context.
Widget host(Future<void> Function(BuildContext) onTap) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => onTap(context),
            child: const Text('Open'),
          ),
        ),
      ),
    );

final onTime = DateTime(2026, 11, 10, 17, 59);
final late = DateTime(2026, 11, 10, 18, 0);
bool cutoff(DateTime t) => t.hour >= 18; // stand-in for the real rule

void main() {
  group('LateFilingDialog', () {
    testWidgets('shows the warning and a reason field', (t) async {
      await t.pumpWidget(host((c) async => showLateFilingDialog(c)));
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();

      expect(find.textContaining('flagged for admin review'), findsOneWidget);
      expect(find.byKey(lateReasonFieldKey), findsOneWidget);
    });

    testWidgets('empty reason shows an error and keeps the dialog open',
        (t) async {
      await t.pumpWidget(host((c) async => showLateFilingDialog(c)));
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();

      await t.tap(find.text('Submit'));
      await t.pumpAndSettle();

      expect(find.text('Reason is required'), findsOneWidget);
      expect(find.byKey(lateReasonFieldKey), findsOneWidget);
    });

    testWidgets('whitespace-only reason is rejected', (t) async {
      await t.pumpWidget(host((c) async => showLateFilingDialog(c)));
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();

      await t.enterText(find.byKey(lateReasonFieldKey), '    ');
      await t.tap(find.text('Submit'));
      await t.pumpAndSettle();

      expect(find.text('Reason is required'), findsOneWidget);
    });

    testWidgets('returns the trimmed reason', (t) async {
      String? result;
      await t.pumpWidget(host((c) async => result = await showLateFilingDialog(c)));
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();

      await t.enterText(find.byKey(lateReasonFieldKey), '  Class ran late ');
      await t.tap(find.text('Submit'));
      await t.pumpAndSettle();

      expect(result, 'Class ran late');
      expect(find.byKey(lateReasonFieldKey), findsNothing); // closed
    });

    testWidgets('cancel returns null', (t) async {
      String? result = 'unset';
      await t.pumpWidget(host((c) async => result = await showLateFilingDialog(c)));
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();

      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();

      expect(result, isNull);
    });
  });

  group('submitWithLateCheck', () {
    Widget form(DateTime now, List<String?> submitted, {List<bool>? outcome}) =>
        host((c) async {
          final ok = await submitWithLateCheck(
            context: c,
            now: now,
            isAfterCutoff: cutoff,
            onSubmit: (reason) async => submitted.add(reason),
          );
          outcome?.add(ok);
        });

    testWidgets('before the cutoff: no dialog, submits with null', (t) async {
      final submitted = <String?>[];
      await t.pumpWidget(form(onTime, submitted));
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();

      expect(find.byKey(lateReasonFieldKey), findsNothing);
      expect(submitted, [null]);
    });

    testWidgets('at the cutoff: dialog shows and nothing is submitted yet',
        (t) async {
      final submitted = <String?>[];
      await t.pumpWidget(form(late, submitted));
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();

      expect(find.byKey(lateReasonFieldKey), findsOneWidget);
      expect(submitted, isEmpty);
    });

    testWidgets('after confirming: submits the reason', (t) async {
      final submitted = <String?>[];
      final outcome = <bool>[];
      await t.pumpWidget(form(late, submitted, outcome: outcome));
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();

      await t.enterText(find.byKey(lateReasonFieldKey), 'Lab ran over');
      await t.tap(find.text('Submit'));
      await t.pumpAndSettle();

      expect(submitted, ['Lab ran over']);
      expect(outcome, [true]);
    });

    testWidgets('cancelling the dialog submits nothing', (t) async {
      final submitted = <String?>[];
      final outcome = <bool>[];
      await t.pumpWidget(form(late, submitted, outcome: outcome));
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();

      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();

      expect(submitted, isEmpty);
      expect(outcome, [false]);
    });
  });
}