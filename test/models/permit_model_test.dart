import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_app/models/data_enums.dart';

import 'package:permission_app/models/permit_model.dart';

PermitModel buildPermit({
  String? adminId,
  String? qrId,
  DateTime? actualTimeIn,
  DateTime? approvedAt,
  PermitStatus status = PermitStatus.pending,
  String? disapprovalReason,
}) {
  return PermitModel(
    id: 'p1',
    userId: 'u1',
    fullName: 'Juan Dela Cruz',
    roomNum: '204',
    permitType: PermitType.late,
    destination: 'Iloilo City',
    purpose: 'Family dinner',
    emergencyContactPerson: 'Maria Dela Cruz',
    emergencyContactNum: '09171234567',
    expectedTimeIn: DateTime.utc(2026, 10, 30, 22),
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
      expect(loaded.fullName, 'Juan Dela Cruz');
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
}