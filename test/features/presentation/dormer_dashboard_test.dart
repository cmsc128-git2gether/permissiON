import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/dormer_dashboard.dart';
import 'package:permission_app/features/presentation/widgets/permit_card.dart';
import 'package:permission_app/router/app_router.dart';
import 'package:permission_app/services/permit_service.dart';
import 'package:permission_app/theme/app_theme.dart';
import 'package:permission_app/utils/format.dart';

const _userId = 'u1';
final _filedAt = DateTime(2026, 11, 22, 17, 0);
final _expectedIn = DateTime(2026, 11, 22, 22, 0);

/// Adds one permit for [userId] with the given status ('ACTIVE', 'PENDING'...).
Future<void> addPermit(
  FakeFirebaseFirestore db,
  String id,
  String status, {
  String userId = _userId,
}) {
  return db.collection('permits').doc(id).set({
    'user_id': userId,
    'surname': 'Dela Cruz',
    'given_name': 'Juan',
    'room_num': '20',
    'permit_type': 'OVERNIGHT',
    'destination': 'Puesto, Barangay Sapa, Miagao, Iloilo',
    'purpose': 'Study',
    'emergency_contact_person': 'Maria Dela Cruz',
    'emergency_contact_num': '09191234567',
    'expected_time_in': Timestamp.fromDate(_expectedIn),
    'permit_status': status,
    'disapproval_reason': null,
    'actual_time_in': null,
    'created_at': Timestamp.fromDate(_filedAt),
  });
}

/// Shows the dashboard alone (no shell). A small router is used so the
/// "File a permit" button can call context.push(AppRoutes.newPermit).
Future<void> pumpDashboard(WidgetTester t, FakeFirebaseFirestore db) async {
  // Tall screen so both sections are built and tappable.
  t.view.physicalSize = const Size(800, 1600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: StudentHomeScreen(
            service: PermitService(firestore: db),
            userId: _userId,
            displayName: 'Dormer',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.newPermit,
        builder: (_, _) => const Scaffold(
          body: Text('new permit form', key: Key('new-permit-form')),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await t.pumpWidget(
    MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
  await t.pumpAndSettle();
}

/// PermitCards inside one dashboard section.
Finder cardsIn(String sectionKey) => find.descendant(
      of: find.byKey(Key(sectionKey)),
      matching: find.byType(PermitCard),
    );

Finder heading(String text) => find.text(text, findRichText: true);

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  group('StudentHomeScreen', () {
    testWidgets('shows the greeting with the display name', (t) async {
      await pumpDashboard(t, db);
      // textContaining so it passes with or without the trailing "!".
      expect(
        find.textContaining('Hello, Dormer', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('empty: both empty states and a "File a permit" button',
        (t) async {
      await pumpDashboard(t, db);

      expect(find.byKey(const Key('active_empty_state')), findsOneWidget);
      expect(find.byKey(const Key('pending_empty_state')), findsOneWidget);
      expect(cardsIn('active_permit_card'), findsNothing);
      expect(cardsIn('pending_permit_card'), findsNothing);
      expect(find.text('File a permit'), findsOneWidget);
      expect(heading('Current Active Permit (0/1)'), findsOneWidget);
      expect(heading('Pending / Scheduled (0/1)'), findsOneWidget);
    });

    testWidgets('"File a permit" opens the new permit page', (t) async {
      await pumpDashboard(t, db);
      await t.tap(find.text('File a permit'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('new-permit-form')), findsOneWidget);
    });

    testWidgets('pending only', (t) async {
      await addPermit(db, 'p1', 'PENDING');
      await pumpDashboard(t, db);

      expect(cardsIn('pending_permit_card'), findsOneWidget);
      expect(find.byKey(const Key('pending_empty_state')), findsNothing);
      expect(cardsIn('active_permit_card'), findsNothing);
      expect(find.byKey(const Key('active_empty_state')), findsOneWidget);
      expect(heading('Pending / Scheduled (1/1)'), findsOneWidget);
    });

    testWidgets('active only', (t) async {
      await addPermit(db, 'a1', 'ACTIVE');
      await pumpDashboard(t, db);

      expect(cardsIn('active_permit_card'), findsOneWidget);
      expect(find.byKey(const Key('active_empty_state')), findsNothing);
      expect(cardsIn('pending_permit_card'), findsNothing);
      expect(find.byKey(const Key('pending_empty_state')), findsOneWidget);
      expect(heading('Current Active Permit (1/1)'), findsOneWidget);
    });

    testWidgets('both', (t) async {
      await addPermit(db, 'a1', 'ACTIVE');
      await addPermit(db, 'p1', 'PENDING');
      await pumpDashboard(t, db);

      expect(cardsIn('active_permit_card'), findsOneWidget);
      expect(cardsIn('pending_permit_card'), findsOneWidget);
      expect(find.byKey(const Key('active_empty_state')), findsNothing);
      expect(find.byKey(const Key('pending_empty_state')), findsNothing);
    });

    testWidgets('View/Manage opens the dialog with all fields', (t) async {
      await addPermit(db, 'a1', 'ACTIVE');
      await pumpDashboard(t, db);

      await t.tap(find.text('View/Manage'));
      await t.pumpAndSettle();

      // The card behind the dialog shows some of the same labels, so look
      // only inside the dialog. If showAppDialog does not use a Dialog,
      // change this finder.
      final dialog = find.ancestor(
        of: find.text('Permit details'),
        matching: find.byType(Dialog),
      );
      expect(dialog, findsOneWidget);

      Finder inDialog(String text) =>
          find.descendant(of: dialog, matching: find.text(text));

      for (final label in [
        'Purpose',
        'Destination',
        'Filed at',
        'Expected Return',
        'Contact Person',
        'Contact Number',
      ]) {
        expect(inDialog(label), findsOneWidget, reason: 'label: $label');
      }

      expect(inDialog('Study'), findsOneWidget);
      expect(inDialog('Puesto, Barangay Sapa, Miagao, Iloilo'), findsOneWidget);
      expect(inDialog(formatDateTime(_filedAt)), findsOneWidget);
      expect(inDialog(formatDateTime(_expectedIn)), findsOneWidget);
      expect(inDialog('Maria Dela Cruz'), findsOneWidget);
      expect(inDialog('09191234567'), findsOneWidget);
    });
    testWidgets('a newly filed permit appears without reloading', (t) async {
      await pumpDashboard(t, db); // starts empty

      expect(cardsIn('pending_permit_card'), findsNothing);
      expect(find.byKey(const Key('pending_empty_state')), findsOneWidget);

      // Same thing the permit form does when it submits.
      await addPermit(db, 'p1', 'PENDING');
      await t.pumpAndSettle();

      expect(cardsIn('pending_permit_card'), findsOneWidget);
      expect(find.byKey(const Key('pending_empty_state')), findsNothing);
      expect(heading('Pending / Scheduled (1/1)'), findsOneWidget);
    });
    testWidgets('a status change on the stream moves the permit', (t) async {
      await addPermit(db, 'p1', 'PENDING');
      await pumpDashboard(t, db);

      expect(cardsIn('pending_permit_card'), findsOneWidget);
      expect(cardsIn('active_permit_card'), findsNothing);

      // Same thing an admin approval does.
      await db.collection('permits').doc('p1').update({
        'permit_status': 'ACTIVE',
      });
      
      await t.pumpAndSettle();

      expect(cardsIn('active_permit_card'), findsOneWidget);
      expect(cardsIn('pending_permit_card'), findsNothing);
      expect(find.byKey(const Key('pending_empty_state')), findsOneWidget);
    });
  });
}