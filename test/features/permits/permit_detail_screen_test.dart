import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_app/features/presentation/permits/permit_detail_screen.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/services/permit_service.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  Future<void> seed(
    String id, {
    required PermitStatus status,
    String? reason,
    DateTime? actualTimeIn,
  }) =>
      db.collection('permits').doc(id).set({
        'user_id': 'u1',
        'full_name': 'Test Name',
        'room_num': '131',
        'permit_type': PermitType.late.value,
        'destination': 'Bangs',
        'purpose': 'study',
        'emergency_contact_person': 'Contact',
        'emergency_contact_num': '0000000000',
        'expected_time_in': Timestamp.fromDate(DateTime(2026, 11, 1, 20)),
        'actual_time_in':
            actualTimeIn == null ? null : Timestamp.fromDate(actualTimeIn),
        'permit_status': status.value,
        'disapproval_reason': reason,
        'created_at': Timestamp.fromDate(DateTime(2026, 10, 30)),
      });

  Future<void> show(WidgetTester tester, String id) async {
    await tester.pumpWidget(MaterialApp(
      home: PermitDetailScreen(
        permitId: id,
        service: PermitService(firestore: db),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('pending: shows status, no reason, no return time', (t) async {
    await seed('p1', status: PermitStatus.pending);
    await show(t, 'p1');

    expect(find.text('PENDING'), findsOneWidget);
    expect(find.textContaining('Reason'), findsNothing);
    expect(find.textContaining('Returned at'), findsNothing);
  });

  testWidgets('active: shows status, no reason, no return time', (t) async {
    await seed('p1', status: PermitStatus.active);
    await show(t, 'p1');

    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.textContaining('Reason'), findsNothing);
    expect(find.textContaining('Returned at'), findsNothing);
  });

  testWidgets('denied: shows the reason', (t) async {
    await seed('p1', status: PermitStatus.denied, reason: 'Invalid curfew time.');
    await show(t, 'p1');

    expect(find.text('DENIED'), findsOneWidget);
    expect(find.text('Reason: Invalid curfew time.'), findsOneWidget);
    expect(find.textContaining('Returned at'), findsNothing);
  });

  testWidgets('completed: shows return time, no reason', (t) async {
    await seed('p1',
        status: PermitStatus.completed,
        actualTimeIn: DateTime(2026, 11, 1, 20, 5));
    await show(t, 'p1');

    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('Returned at 20:05'), findsOneWidget);
    expect(find.textContaining('Reason'), findsNothing);
  });

  testWidgets('missing permit shows a not-found message', (t) async {
    await show(t, 'nope');
    expect(find.text('Permit not found'), findsOneWidget);
  });
}
