import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/permits/permit_request.dart';
import 'package:permission_app/features/presentation/permits/permit_wizard_screen.dart';
import 'package:permission_app/features/presentation/widgets/error_state.dart';
import 'package:permission_app/features/presentation/widgets/loading_state.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/theme/app_theme.dart';

const filer = PermitFiler(
  surname: 'Dela Cruz',
  givenName: 'Juan',
  roomNum: '204',
  floor: 2,
);

// 2026-11-19 10:00 Manila (UTC+8)
final baseNow = DateTime.utc(2026, 11, 19, 2, 0);

class FakeFiling {
  final calls = <NewPermitRequest>[];
  Object? error;
  Completer<void>? gate;

  Future<void> create(NewPermitRequest r, {String? lateReason}) async {
    calls.add(r);
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
  }
}

Future<void> pumpWizard(
  WidgetTester t,
  FakeFiling f, {
  DateTime Function()? now,
  String? userId = 'uid-1',
  Future<PermitFiler> Function()? loadFiler,
  PickTime? pickTime,
  PickDateRange? pickDateRange,
  bool settle = true,
}) async {
  t.view.physicalSize = const Size(800, 1400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);

  final router = GoRouter(
    initialLocation: '/new',
    routes: [
      GoRoute(
        path: '/new',
        builder: (_, _) => PermitWizardScreen(
          userId: userId,
          loadFiler: loadFiler ?? () async => filer,
          createPermit: f.create,
          now: now ?? () => baseNow,
          pickTime:
              pickTime ?? (_, _) async => const TimeOfDay(hour: 20, minute: 0),
          pickDateRange: pickDateRange ??
              (_, _, _) async => DateTimeRange(
                    start: DateTime(2026, 11, 20),
                    end: DateTime(2026, 11, 22),
                  ),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(
          key: Key('home'),
          body: Text('Home'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await t.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
  if (settle) {
    await t.pumpAndSettle();
  } else {
    await t.pump();
  }
}

Future<void> tapText(WidgetTester t, String text) async {
  await t.tap(find.text(text));
  await t.pumpAndSettle();
}

Future<void> chooseType(WidgetTester t, String label) => tapText(t, label);

Future<void> pickReturnTime(WidgetTester t) async {
  await t.tap(find.byKey(const Key('return-time')));
  await t.pumpAndSettle();
}

Future<void> pickDates(WidgetTester t) async {
  await t.tap(find.byKey(const Key('dates')));
  await t.pumpAndSettle();
}

Future<void> fillDetails(
  WidgetTester t, {
  String purpose = 'Dental appointment',
  String destination = 'Iloilo City',
  String person = 'Ana Cruz',
  String number = '09171234567',
  bool setTime = true,
  bool setDates = false,
}) async {
  await t.enterText(find.byKey(const Key('purpose')), purpose);
  await t.enterText(find.byKey(const Key('destination')), destination);
  if (setDates) await pickDates(t);
  if (setTime) await pickReturnTime(t);
  await t.enterText(find.byKey(const Key('contact-person')), person);
  await t.enterText(find.byKey(const Key('contact-number')), number);
}

Future<void> reachConfirm(WidgetTester t, {String type = 'Overnight'}) async {
  await chooseType(t, type);
  await tapText(t, 'Next');
  await fillDetails(t, setDates: type == 'Weekend');
  await tapText(t, 'Next');
}

Finder get submitButton => find.widgetWithText(ElevatedButton, 'Submit');
Finder get dialog => find.byType(AlertDialog);

VoidCallback? onPressedOf(WidgetTester t, String label) =>
    t.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, label)).onPressed;

void main() {
  group('auth and profile loading', () {
    testWidgets('shows error when userId is null', (t) async {
      await pumpWizard(t, FakeFiling(), userId: null);
      expect(find.byType(ErrorState), findsOneWidget);
      expect(
        find.text('You need to be signed in to file a permit.'),
        findsOneWidget,
      );
    });

    testWidgets('shows loading state while filer loads', (t) async {
      final completer = Completer<PermitFiler>();
      await pumpWizard(t, FakeFiling(), loadFiler: () => completer.future, settle: false);
      expect(find.byType(LoadingState), findsOneWidget);

      completer.complete(filer);
      await t.pumpAndSettle();
      expect(find.text('Type of permit'), findsOneWidget);
    });

    testWidgets('shows error and retries when loadFiler fails', (t) async {
      var shouldFail = true;
      await pumpWizard(
        t,
        FakeFiling(),
        loadFiler: () async {
          if (shouldFail) throw Exception('network error');
          return filer;
        },
      );

      expect(find.byType(ErrorState), findsOneWidget);
      shouldFail = false;
      await tapText(t, 'Retry');
      expect(find.text('Type of permit'), findsOneWidget);
    });
  });

  group('step 1: type', () {
    testWidgets('shows the three types and no Prev', (t) async {
      await pumpWizard(t, FakeFiling());
      for (final s in ['Late', 'Overnight', 'Weekend']) {
        expect(find.text(s), findsOneWidget);
      }
      expect(find.text('Prev'), findsNothing);
    });

    testWidgets('Next is disabled until a type is chosen', (t) async {
      await pumpWizard(t, FakeFiling());
      expect(onPressedOf(t, 'Next'), isNull);

      await chooseType(t, 'Weekend');
      expect(onPressedOf(t, 'Next'), isNotNull);
    });
  });

  group('step 2: details', () {
    Future<void> toDetails(
      WidgetTester t,
      FakeFiling f, {
      String type = 'Late',
      DateTime Function()? now,
      PickTime? pickTime,
    }) async {
      await pumpWizard(t, f, now: now, pickTime: pickTime);
      await chooseType(t, type);
      await tapText(t, 'Next');
    }

    testWidgets('every required field shows its own error', (t) async {
      await toDetails(t, FakeFiling());
      await tapText(t, 'Next');

      for (final s in [
        'Purpose is required',
        'Destination is required',
        'Return time is required',
        'Contact person is required',
        'Contact number is required',
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      expect(find.text('Prev'), findsOneWidget);
    });

    testWidgets('weekend type requires Out of Dorm Duration dates', (t) async {
      await toDetails(t, FakeFiling(), type: 'Weekend');
      expect(find.byKey(const Key('dates')), findsOneWidget);

      await fillDetails(t, setDates: false, setTime: true);
      await tapText(t, 'Next');
      expect(find.text('Prev'), findsOneWidget);

      await pickDates(t);
      await tapText(t, 'Next');
      expect(submitButton, findsOneWidget);
    });

    testWidgets('only the empty field shows an error', (t) async {
      await toDetails(t, FakeFiling());
      await fillDetails(t, destination: '');
      await tapText(t, 'Next');

      expect(find.text('Destination is required'), findsOneWidget);
      expect(find.text('Purpose is required'), findsNothing);
      expect(find.text('Contact number is required'), findsNothing);
    });

    testWidgets('a return time that has become past is rejected', (t) async {
      var clock = baseNow; // 10:00 Manila
      await toDetails(
        t,
        FakeFiling(),
        now: () => clock,
        pickTime: (_, _) async => const TimeOfDay(hour: 11, minute: 0),
      );
      await fillDetails(t);

      clock = DateTime.utc(2026, 11, 19, 4, 0); // 12:00 PM Manila
      await tapText(t, 'Next');
      expect(find.text('Return time must be in the future'), findsOneWidget);
    });

    testWidgets('a bad phone number is rejected', (t) async {
      await toDetails(t, FakeFiling());
      for (final bad in ['0917abc4567', '123456', '1234567890123456']) {
        await fillDetails(t, number: bad);
        await tapText(t, 'Next');
        expect(
          find.text('Enter 7 to 15 digits, numbers only'),
          findsOneWidget,
          reason: bad,
        );
        expect(find.text('Prev'), findsOneWidget);
      }
    });

    testWidgets('valid details advance to confirmation step', (t) async {
      await toDetails(t, FakeFiling());
      await fillDetails(t);
      await tapText(t, 'Next');
      expect(submitButton, findsOneWidget);
    });
  });

  group('data persistence and summary', () {
    testWidgets('data persists across Prev and Next', (t) async {
      await pumpWizard(t, FakeFiling());
      await reachConfirm(t);

      await tapText(t, 'Prev');
      String fieldValue(String key) =>
          t.widget<TextFormField>(find.byKey(Key(key))).controller!.text;

      expect(fieldValue('purpose'), 'Dental appointment');
      expect(fieldValue('destination'), 'Iloilo City');
      expect(fieldValue('contact-person'), 'Ana Cruz');
      expect(fieldValue('contact-number'), '09171234567');
      expect(find.text('8:00 PM'), findsOneWidget);
      expect(find.text('8:00 PM'), findsOneWidget);


      await tapText(t, 'Next');
      expect(submitButton, findsOneWidget);

      await tapText(t, 'Prev');
      await tapText(t, 'Prev');
      expect(
        t
            .widget<RadioGroup<PermitType>>(
              find.byType(RadioGroup<PermitType>),
            )
            .groupValue,
        PermitType.overnight,
      );
      expect(onPressedOf(t, 'Next'), isNotNull);
    });

    testWidgets(
      'changing permit type clears previously chosen time and dates',
      (t) async {
        await pumpWizard(t, FakeFiling());
        await chooseType(t, 'Weekend');
        await tapText(t, 'Next');
        await fillDetails(t, setDates: true, setTime: true);
        expect(find.text('8:00 PM'), findsOneWidget);

        await tapText(t, 'Prev');
        await chooseType(t, 'Late');
        await tapText(t, 'Next');

        expect(find.text('Select time'), findsOneWidget);
        expect(find.text('8:00 PM'), findsNothing);
                expect(find.text('Select time'), findsOneWidget);
        expect(find.text('8:00 PM'), findsNothing);
      },
    );

    testWidgets('the summary displays entered details', (t) async {
      await pumpWizard(t, FakeFiling());
      await reachConfirm(t);

      for (final s in [
        'Overnight',
        'Dental appointment',
        'Iloilo City',
        'Ana Cruz',
        '09171234567',
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      expect(find.text('Prev'), findsOneWidget);
    });
  });

  group('submission and navigation', () {
    testWidgets(
      'submits permit, shows success dialog, and navigates home on Okay',
      (t) async {
        final f = FakeFiling();
        await pumpWizard(t, f);
        await reachConfirm(t);

        await tapText(t, 'Submit');
        expect(f.calls, hasLength(1));
        expect(f.calls.single.type, PermitType.overnight);
        expect(f.calls.single.purpose, 'Dental appointment');
        expect(f.calls.single.destination, 'Iloilo City');
        expect(f.calls.single.contactPerson, 'Ana Cruz');
        expect(f.calls.single.contactNumber, '09171234567');

        expect(dialog, findsOneWidget);
        expect(find.text('Permit request submitted'), findsOneWidget);

        await tapText(t, 'Okay');
        expect(find.byKey(const Key('home')), findsOneWidget);
      },
    );

    testWidgets('submits weekend permit with startDate set', (t) async {
      final f = FakeFiling();
      await pumpWizard(t, f);
      await reachConfirm(t, type: 'Weekend');

      await tapText(t, 'Submit');
      expect(f.calls, hasLength(1));
      expect(f.calls.single.type, PermitType.weekend);
      expect(f.calls.single.startDate, DateTime(2026, 11, 20));
    });

    testWidgets('guards against double-tap while submitting', (t) async {
      final f = FakeFiling()..gate = Completer<void>();
      await pumpWizard(t, f);
      await reachConfirm(t);

      await t.tap(submitButton);
      await t.pump();
      expect(onPressedOf(t, 'Submit'), isNull);

      f.gate!.complete();
      await t.pumpAndSettle();
      expect(f.calls, hasLength(1));
    });

    testWidgets('shows snackbar when submission fails', (t) async {
      final f = FakeFiling()..error = Exception('server error');
      await pumpWizard(t, f);
      await reachConfirm(t);

      await tapText(t, 'Submit');
      expect(
        find.text('Could not submit your request. Please try again.'),
        findsOneWidget,
      );
      expect(dialog, findsNothing);
      expect(onPressedOf(t, 'Submit'), isNotNull);
    });

    testWidgets('back to home page link navigates to /home', (t) async {
      await pumpWizard(t, FakeFiling());
      await tapText(t, 'back to home page');
      expect(find.byKey(const Key('home')), findsOneWidget);
    });
  });
}

