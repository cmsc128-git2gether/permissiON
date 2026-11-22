import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/widgets/range_calendar.dart';
import 'package:permission_app/theme/app_theme.dart';

DateTimeRange? result;

Future<void> open(WidgetTester t, {DateTime? first, DateTime? last}) async {
  result = null;
  await t.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Builder(
        builder: (c) => ElevatedButton(
          onPressed: () async => result = await showRangeCalendar(
              c, first ?? DateTime(2026, 11, 19), last ?? DateTime(2027, 11, 19)),
          child: const Text('Open'),
        ),
      ),
    ),
  ));
  await t.tap(find.text('Open'));
  await t.pumpAndSettle();
}

Future<void> day(WidgetTester t, String iso) async {
  await t.tap(find.byKey(Key('day-$iso')));
  await t.pump();
}

VoidCallback? confirmOnPressed(WidgetTester t) =>
    t.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Confirm')).onPressed;

Future<void> confirm(WidgetTester t) async {
  await t.tap(find.text('Confirm'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('shows the first month', (t) async {
    await open(t);
    expect(find.text('November 2026'), findsOneWidget);
  });

  testWidgets('Confirm is disabled until a day is picked', (t) async {
    await open(t);
    expect(confirmOnPressed(t), isNull);
    await day(t, '2026-11-20');
    expect(confirmOnPressed(t), isNotNull);
  });

  testWidgets('days before the first date cannot be picked', (t) async {
    await open(t);
    await day(t, '2026-11-10');
    expect(confirmOnPressed(t), isNull);
  });

  testWidgets('two taps make a range', (t) async {
    await open(t);
    await day(t, '2026-11-20');
    await day(t, '2026-11-22');
    await confirm(t);
    expect(result, DateTimeRange(start: DateTime(2026, 11, 20), end: DateTime(2026, 11, 22)));
  });

  testWidgets('tapping an earlier day moves the start', (t) async {
    await open(t);
    await day(t, '2026-11-22');
    await day(t, '2026-11-20');
    await confirm(t);
    expect(result, DateTimeRange(start: DateTime(2026, 11, 20), end: DateTime(2026, 11, 20)));
  });

  testWidgets('a third tap starts over', (t) async {
    await open(t);
    await day(t, '2026-11-20');
    await day(t, '2026-11-22');
    await day(t, '2026-11-25');
    await confirm(t);
    expect(result, DateTimeRange(start: DateTime(2026, 11, 25), end: DateTime(2026, 11, 25)));
  });

  testWidgets('month arrows move and stop at the limits', (t) async {
    await open(t, last: DateTime(2026, 12, 20));
    expect(t.widget<IconButton>(find.byKey(const Key('prev-month'))).onPressed, isNull);
    await t.tap(find.byKey(const Key('next-month')));
    await t.pump();
    expect(find.text('December 2026'), findsOneWidget);
    expect(t.widget<IconButton>(find.byKey(const Key('next-month'))).onPressed, isNull);
    await day(t, '2026-12-05');
    await confirm(t);
    expect(result?.start, DateTime(2026, 12, 5));
  });
}