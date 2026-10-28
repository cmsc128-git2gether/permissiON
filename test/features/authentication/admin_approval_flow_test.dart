import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:permission_app/features/authentication/data/admin_approval_flow.dart';
import 'package:permission_app/features/authentication/domain/permit_model.dart';
import 'package:permission_app/features/authentication/domain/user_model.dart';

void main() {
  late FakeFirebaseFirestore db;
  late PermitAdminService service;

  final admin = AppUser(uid: 'admin1', email: 'admin@x.com', accessLevel: 'admin');
  final resident = AppUser(uid: 'u1', email: 'u@x.com', accessLevel: 'end_user');

  Future<void> seedPermit({String status = PermitStatus.pending}) {
    return PermitModel.collectionOf(db).doc('p1').set(PermitModel(
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
          permitStatus: status,
          createdAt: DateTime.utc(2026, 10, 30, 12),
        ));
  }

  Future<Map<String, dynamic>> rawPermit() async =>
      (await db.collection('permits').doc('p1').get()).data()!;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = PermitAdminService(firestore: db);
  });

  group('approvePermit', () {
    test('sets ACTIVE, approved_by and approved_at', () async {
      await seedPermit();
      await service.approvePermit(permitId: 'p1', admin: admin);

      final data = await rawPermit();
      expect(data['permit_status'], PermitStatus.active);
      expect(data['approved_by'], 'admin1');
      expect(data['approved_at'], isA<Timestamp>());
    });

    test('rejects a non-admin and leaves the permit untouched', () async {
      await seedPermit();
      await expectLater(
        service.approvePermit(permitId: 'p1', admin: resident),
        throwsA(isA<PermitActionException>()),
      );

      final data = await rawPermit();
      expect(data['permit_status'], PermitStatus.pending);
      expect(data['approved_by'], isNull);
    });

    test('rejects a permit that is not PENDING', () async {
      await seedPermit(status: PermitStatus.cancelled);
      await expectLater(
        service.approvePermit(permitId: 'p1', admin: admin),
        throwsA(isA<PermitActionException>()),
      );
      expect((await rawPermit())['permit_status'], PermitStatus.cancelled);
    });

    test('rejects a second action on an already-approved permit', () async {
      await seedPermit();
      await service.approvePermit(permitId: 'p1', admin: admin);
      await expectLater(
        service.denyPermit(permitId: 'p1', admin: admin),
        throwsA(isA<PermitActionException>()),
      );
      expect((await rawPermit())['permit_status'], PermitStatus.active);
    });

    test('throws when the permit does not exist', () async {
      await expectLater(
        service.approvePermit(permitId: 'missing', admin: admin),
        throwsA(isA<PermitActionException>()),
      );
    });
  });

  group('denyPermit', () {
    test('sets DENIED, approved_by and approved_at', () async {
      await seedPermit();
      await service.denyPermit(permitId: 'p1', admin: admin);

      final data = await rawPermit();
      expect(data['permit_status'], PermitStatus.denied);
      expect(data['approved_by'], 'admin1');
      expect(data['approved_at'], isA<Timestamp>());
    });

    test('rejects a non-admin', () async {
      await seedPermit();
      await expectLater(
        service.denyPermit(permitId: 'p1', admin: resident),
        throwsA(isA<PermitActionException>()),
      );
      expect((await rawPermit())['permit_status'], PermitStatus.pending);
    });
  });
}