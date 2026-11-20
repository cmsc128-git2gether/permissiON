import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_app/models/data_enums.dart';

import 'package:permission_app/models/permit_model.dart';

// Dorm time is UTC+8 (ph time zone), so 9 PM = 13:00 UTC and 11 PM = 15:00 UTC.
// 9 PM is the curfew for all dormers without permits filed (dorm curfew)
// 11 PM is the curfew for residents who have filed a LATE permit
final curfew9pm = DateTime.utc(2026, 10, 30, 13);
final curfew11pm = DateTime.utc(2026, 10, 30, 15);

// buildPermit builds a LATE permit by default
// so its expected time-in is the 11 PM curfew
final expected = curfew11pm;

PermitModel buildPermit({
  String? adminId,
  String? qrId,
  DateTime? actualTimeIn,
  DateTime? approvedAt,
  DateTime? expectedTimeIn,
  PermitStatus status = PermitStatus.pending,
  String? disapprovalReason,
}) {
  return PermitModel(
    id: 'p1',
    userId: 'u1',
    surname: 'Dela Cruz',
    givenName: 'Juan',
    roomNum: '204',
    permitType: PermitType.late,
    destination: 'Beans and Bubbles',
    purpose: 'Study Out',
    emergencyContactPerson: 'Maria Dela Cruz',
    emergencyContactNum: '09171234567',
    expectedTimeIn: expectedTimeIn ?? expected,
    actualTimeIn: actualTimeIn,
    approvedBy: adminId,
    approvedAt: approvedAt,
    qrId: qrId,
    createdAt: DateTime.utc(2026, 10, 30, 12),
    permitStatus: status,
    disapprovalReason: disapprovalReason,
  );
}

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  group('PermitModel', () {
    test('defaults to PENDING', () {
      expect(buildPermit().permitStatus, PermitStatus.pending);
    });

    test('toFirestore uses the schema keys and omits the doc id', () {
      final map = buildPermit().toFirestore();
      expect(map.containsKey('id'), isFalse);
      expect(
        map.keys,
        containsAll([
          'user_id', 'full_name', 'room_num', 'permit_type', 'destination',
          'purpose', 'emergency_contact_person', 'emergency_contact_num',
          'expected_time_in', 'actual_time_in', 'permit_status',
          'approved_by', 'approved_at', 'qr_id', 'created_at',
        ]),
      );
      expect(map['expected_time_in'], isA<Timestamp>());
    });

    test('nullable fields are written as null', () {
      final map = buildPermit().toFirestore();
      expect(map['actual_time_in'], isNull);
      expect(map['approved_by'], isNull);
      expect(map['approved_at'], isNull);
      expect(map['qr_id'], isNull);
      expect(map['disapproval_reason'], isNull);   
    });

    test('round-trips through the typed collection', () async {
      final original = buildPermit(
        adminId: 'admin1',
        qrId: 'qr1',
        actualTimeIn: DateTime.utc(2026, 10, 30, 21, 30),
        approvedAt: DateTime.utc(2026, 10, 30, 13),
      );
      final col = PermitModel.collectionOf(db);
      await col.doc('p1').set(original);

      final loaded = (await col.doc('p1').get()).data()!;
      expect(loaded.id, 'p1');
      expect(loaded.userId, 'u1');
      expect(loaded.surname, 'Dela Cruz');
      expect(loaded.givenName, 'Juan');
      expect(loaded.fullName, 'Dela Cruz, Juan');
      expect(loaded.displayName, 'Juan Dela Cruz');
      expect(loaded.roomNum, '204');
      expect(loaded.permitType, PermitType.late);
      expect(loaded.expectedTimeIn.toUtc(), original.expectedTimeIn);
      expect(loaded.actualTimeIn!.toUtc(), original.actualTimeIn);
      expect(loaded.approvedBy, 'admin1');
      expect(loaded.approvedAt!.toUtc(), original.approvedAt);
      expect(loaded.qrId, 'qr1');
      expect(loaded.permitStatus, PermitStatus.pending);
    });

    test('denied permit keeps its reason through a round trip', () async {
      final col = PermitModel.collectionOf(db);
      await col.doc('p1').set(buildPermit(
            adminId: 'admin1',
            status: PermitStatus.denied,
            disapprovalReason: 'Missing guardian consent',
          ));

      final loaded = (await col.doc('p1').get()).data()!;
      expect(loaded.permitStatus, PermitStatus.denied);
      expect(loaded.disapprovalReason, 'Missing guardian consent');
    });

    test('unknown permit_status in Firestore throws', () async {
      await db.collection('permits').doc('bad').set({
        'expected_time_in': Timestamp.fromDate(DateTime.utc(2026, 10, 30, 22)),
        'permit_status': 'BOGUS',
      });

      await expectLater(
        () async => (await PermitModel.collectionOf(db).doc('bad').get()).data(),
        throwsArgumentError,
      );
    });

    test('createdAt falls back to now when created_at is missing', () async {
      await db.collection('permits').doc('p2').set({
        'expected_time_in': Timestamp.fromDate(DateTime.utc(2026, 10, 30, 22)),
        // no created_at
      });

      final loaded = (await PermitModel.collectionOf(db).doc('p2').get()).data()!;
      expect(
        loaded.createdAt.difference(DateTime.now()).abs(),
        lessThan(const Duration(seconds: 5)),
      );
    });

    test('null foreign keys survive a round trip', () async {
      final col = PermitModel.collectionOf(db);
      await col.doc('p1').set(buildPermit());

      final loaded = (await col.doc('p1').get()).data()!;
      expect(loaded.approvedBy, isNull);
      expect(loaded.qrId, isNull);
      expect(loaded.actualTimeIn, isNull);
    });
  });

  // AS7 / US5: late and overdue logic
  // "late"    = the resident checked in AFTER the expected time-in
  // "overdue" = an ACTIVE permit with no check-in yet, checked AFTER the expected time-in


  // isLate: compares the recorded time-in against the expected time-in.
  group('PermitModel.isLate', () {
    // Not late: the resident hasn't come back, so there's nothing to compare
    test('false when there is no time-in yet', () {
      expect(buildPermit().isLate, isFalse);
    });

    // Not late: back at 10:30 PM, 30 minutes before the 11 PM curfew
    test('false when the time-in is before the expected time', () {
      final permit = buildPermit(
        actualTimeIn: expected.subtract(const Duration(minutes: 30)),
      );
      expect(permit.isLate, isFalse);
    });

    // Boundary: back at exactly 11:00 PM counts as on time
    test('false when the time-in is exactly the expected time', () {
      expect(buildPermit(actualTimeIn: expected).isLate, isFalse);
    });

    // Boundary: back at 11:01 PM, the first moment that counts as late
    test('true when the time-in is one minute after the expected time', () {
      final permit = buildPermit(
        actualTimeIn: expected.add(const Duration(minutes: 1)),
      );
      expect(permit.isLate, isTrue);
    });

    // Contradicting curfews: 9:30 PM arrival is late against a 9 PM curfew (no permit filed) 
    // but on time against the 11 PM curfew of a LATE permit (filed)
    test('9:30 PM is late for a 9 PM curfew', () {
      final permit = buildPermit(
        expectedTimeIn: curfew9pm,
        actualTimeIn: curfew9pm.add(const Duration(minutes: 30)),
      );
      expect(permit.isLate, isTrue);
    });

    test('9:30 PM is on time for the 11 PM curfew of a LATE permit', () {
      final permit = buildPermit(
        expectedTimeIn: curfew11pm,
        actualTimeIn: curfew9pm.add(const Duration(minutes: 30)),
      );
      expect(permit.isLate, isFalse);
    });
  });

  // isOverdueAt(now): the clock is passed in, so each test picks its own "now" instead of reading the real time
  // buildPermit defaults to PENDING, so these tests ask for ACTIVE themselves.
  group('PermitModel.isOverdueAt', () {
    // Overdue: ACTIVE, nobody has checked in, and now is 11:01 PM
    test('true when ACTIVE, no time-in and now is after the expected time', () {
      final now = expected.add(const Duration(minutes: 1));
      expect(buildPermit(status: PermitStatus.active).isOverdueAt(now), isTrue);
    });

    // Boundary: at exactly 11:00 PM the resident still has time
    test('false exactly at the expected time', () {
      expect(
        buildPermit(status: PermitStatus.active).isOverdueAt(expected),
        isFalse,
      );
    });

    // Not overdue yet: now is 10:55 PM
    test('false before the expected time (5 minutes early)', () {
      final now = expected.subtract(const Duration(minutes: 5));
      expect(buildPermit(status: PermitStatus.active).isOverdueAt(now), isFalse);
    });

    // Not overdue: they checked in at midnight (late, but back). That case is covered by isLate, not by isOverdueAt.
    test('false once a time-in is recorded, even if it was late', () {
      final permit = buildPermit(
        status: PermitStatus.active,
        actualTimeIn: expected.add(const Duration(hours: 1)),
      );
      final now = expected.add(const Duration(hours: 2));
      expect(permit.isOverdueAt(now), isFalse);
    });

    // Only ACTIVE permits can become overdue. Every other status (including
    // one already stored as OVERDUE) returns false, even hours past curfew.
    test('false for any status other than ACTIVE', () {
      final now = expected.add(const Duration(hours: 2));
      for (final status in PermitStatus.values) {
        if (status == PermitStatus.active) continue;
        expect(
          buildPermit(status: status).isOverdueAt(now),
          isFalse,
          reason: '${status.value} must not count as overdue',
        );
      }
    });

    // at 9:30 PM, a dormer with the 11 PM curfew still has time
    test('9:30 PM is not yet overdue for the 11 PM curfew of a LATE permit', () {
      final permit = buildPermit(
        status: PermitStatus.active,
        expectedTimeIn: curfew11pm,
      );
      expect(permit.isOverdueAt(curfew9pm.add(const Duration(minutes: 30))), isFalse);
    });
  });
}