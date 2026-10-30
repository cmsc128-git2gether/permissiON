import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_app/models/data_enums.dart'; 
import 'package:permission_app/models/permit_model.dart';
import 'package:permission_app/services/permit_service.dart'; 
import 'package:permission_app/utils/firestore_utils.dart';
import 'package:clock/clock.dart';

void main(){
  late FakeFirebaseFirestore db;
  late PermitService permitService;

  PermitModel createMockPermit({
    required String id,
    required String userId,
    PermitStatus status = PermitStatus.pending,
    PermitType type = PermitType.late,
  }) {
    return PermitModel(
      id: id,
      userId: userId,
      fullName: 'Test Name',
      roomNum: '131',
      permitType: type,
      destination: 'Bangs',
      purpose: 'study',
      emergencyContactPerson: 'Test Contact',
      emergencyContactNum: '0000000000',
      expectedTimeIn: DateTime.now().add(const Duration(hours:3)),
      permitStatus: status,
      createdAt: DateTime.now(),
    );
  }

  setUp(() {
    db = FakeFirebaseFirestore();
    permitService = PermitService(firestore: db);
  });

group('PermitService: createPermit', () {
    test('creates a permit document with initialized and defaulted fields for a user', () async {
      final inputPermit = createMockPermit(id: '', userId: 'user_123', status: PermitStatus.active);

      final generatedId = await permitService.createPermit(inputPermit);

      expect(generatedId, isNotEmpty);

      final docSnap = await db.collection('permits').doc(generatedId).get();
      final data = docSnap.data()!;

      expect(data['user_id'], 'user_123');
      expect(data['permit_status'], PermitStatus.pending.value);
      expect(data['actual_time_in'], isNull);
      expect(data['disapproval_reason'], isNull);
      expect(data['permit_type'], PermitType.late.value);
      expect(data['approved_by'], isNull);
      expect(data['approved_at'], isNull); //
      expect(data['created_at'], isNotNull);
      expect(data['qr_id'], isNull);
    });
  });

  group('PermitService: listenToUserPermits function', () {
    test('streams lists matching the target userId sorted descending by created_at', () async {
      const targetUser = 'user_abc';
      final baseTime = DateTime(2026, 10, 25, 12, 0);
      
      final olderPermit = createMockPermit(id: 'p1', userId: targetUser);
      final newerPermit = createMockPermit(id: 'p2', userId: targetUser);
      final separateUserPermit = createMockPermit(id: 'p3', userId: 'user_xyz');

      await db.collection('permits').doc('p1').set(olderPermit.toFirestore()..['created_at'] = Timestamp.fromDate(baseTime));
      await db.collection('permits').doc('p2').set(newerPermit.toFirestore()..['created_at'] = Timestamp.fromDate(baseTime.add(const Duration(hours: 1))));
      await db.collection('permits').doc('p3').set(separateUserPermit.toFirestore()..['created_at'] = Timestamp.fromDate(baseTime));

      final stream = permitService.listenToUserPermits(targetUser);

      await expectLater(
        stream,
        emits([
          isA<PermitModel>().having((p) => p.id, 'id', 'p2'), 
          isA<PermitModel>().having((p) => p.id, 'id', 'p1'), 
        ]),
      );
    });
  });

  group('PermitService: updatePermitStatus (fail-fast checks)', () {
    test('throws ArgumentError if disapproval reason is provided when status is not denied', () {
      expect(
        () => permitService.updatePermitStatus('admin_1', 'p1', PermitStatus.active.value, disapprovalReason: 'Looks good'),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError if disapproval reason is completely omitted when status is denied', () {
      expect(
        () => permitService.updatePermitStatus('admin_1', 'p1', PermitStatus.denied.value, disapprovalReason: null),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError if disapproval reason is empty string when status is denied', () {
      expect(
        () => permitService.updatePermitStatus('admin_1', 'p1', PermitStatus.denied.value, disapprovalReason: ''),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError if passing status literals that are not strictly active or denied values', () {
      expect(
        () => permitService.updatePermitStatus('admin_1', 'p1', PermitStatus.pending.value),
        throwsArgumentError,
      );
    });
  });

  group('PermitService - updatePermitStatus (Database Transaction Rules)', () {
    test('throws StateError when attempting to update a non-existent permit ID token', () async {
      expect(
        () => permitService.updatePermitStatus('admin_1', 'missing_id', PermitStatus.active.value),
        throwsStateError,
      );
    });

    test('throws StateError when the permit existing state is already reviewed (not pending)', () async {
      final activePermit = createMockPermit(id: 'p_active', userId: 'u1', status: PermitStatus.active);
      await db.collection('permits').doc('p_active').set(activePermit.toFirestore());

      expect(
        () => permitService.updatePermitStatus('admin_1', 'p_active', PermitStatus.active.value),
        throwsStateError,
      );
    });

    test('successfully marks pending permit to active within active transaction constraints', () async {
      final pendingPermit = createMockPermit(id: 'p_ok', userId: 'u1', status: PermitStatus.pending);
      await db.collection('permits').doc('p_ok').set(pendingPermit.toFirestore());

      await permitService.updatePermitStatus('admin_1', 'p_ok', PermitStatus.active.value);

      final snapshot = await db.collection('permits').doc('p_ok').get();
      final data = snapshot.data()!;

      expect(data['permit_status'], PermitStatus.active.value);
      expect(data['approved_by'], 'admin_1');
      expect(data['approved_at'], isNotNull);
      expect(data['disapproval_reason'], isNull);
    });

    test('successfully stamps denial state accompanied by reason string to firestore', () async {
      final pendingPermit = createMockPermit(id: 'p_bad', userId: 'u1', status: PermitStatus.pending);
      await db.collection('permits').doc('p_bad').set(pendingPermit.toFirestore());

      await permitService.updatePermitStatus(
        'admin_1',
        'p_bad',
        PermitStatus.denied.value, 
        disapprovalReason: 'Invalid curfew time.',
      );

      final snapshot = await db.collection('permits').doc('p_bad').get();
      final data = snapshot.data()!;

      expect(data['permit_status'], PermitStatus.denied.value);
      expect(data['approved_by'], 'admin_1');
      expect(data['approved_at'], isNotNull);
      expect(data['disapproval_reason'], 'Invalid curfew time.');
    });
  });

  group('PermitService - recordTimeIn', () {
    final now = DateTime(2026, 10, 30, 16, 0);
    final timeIn = DateTime(2026, 10, 30, 15, 0);

    test('ACTIVE permit gets actual_time_in and becomes COMPLETED', () async {
      final samplePermit =
          createMockPermit(id: 'p1', userId: 'user_123', status: PermitStatus.active);
      await db.collection('permits').doc('p1').set(samplePermit.toFirestore());

      // run the service with the clock frozen at `now`
      await withClock(Clock.fixed(now), () async {
        await permitService.recordTimeIn('p1', at: timeIn);
      });

      final data = (await db.collection('permits').doc('p1').get()).data()!;

      expect(data['permit_status'], 'COMPLETED');
      expect(parseTimestamp(data['actual_time_in']), timeIn);
    });

    test('ACTIVE permit with no `at` must be COMPLETED', () async {
      final samplePermit =
          createMockPermit(id: 'p1', userId: 'user_123', status: PermitStatus.active);
      await db.collection('permits').doc('p1').set(samplePermit.toFirestore());

      // run the service with the clock frozen at `now`
      await withClock(Clock.fixed(now), () async {
        await permitService.recordTimeIn('p1');
      });

      final data = (await db.collection('permits').doc('p1').get()).data()!;

      expect(data['permit_status'], 'COMPLETED');
      expect(parseTimestamp(data['actual_time_in']), now);
    });

    test('throws StateError when `at` is in the future, writes nothing on the field', () async {
      final samplePermit =
          createMockPermit(id: 'p1', userId: 'user_123', status: PermitStatus.active);
      await db.collection('permits').doc('p1').set(samplePermit.toFirestore());

      await withClock(Clock.fixed(now), () async {
        await expectLater(
          () => permitService.recordTimeIn('p1', at: now.add(const Duration(hours: 1))),
          throwsStateError,
        );
      });

      final data = (await db.collection('permits').doc('p1').get()).data()!;
      expect(data['permit_status'], 'ACTIVE');       // unchanged
      expect(data['actual_time_in'], isNull);
    });

    test('throws StateError for a missing permit', () async {
      await withClock(Clock.fixed(now), () async {
        await expectLater(
          permitService.recordTimeIn('does_not_exist'),
          throwsStateError,
        );
      });
    });

    test('throws StateError for a non-ACTIVE permit', () async {
      final pending =
          createMockPermit(id: 'p2', userId: 'user_123', status: PermitStatus.pending);
      await db.collection('permits').doc('p2').set(pending.toFirestore());

      await withClock(Clock.fixed(now), () async {
        await expectLater(
          permitService.recordTimeIn('p2'),
          throwsStateError,
        );
      });
    });

    test('throws StateError if a time-in already exists', () async {
      final permit =
          createMockPermit(id: 'p3', userId: 'user_123', status: PermitStatus.active);
      await db.collection('permits').doc('p3').set({
        ...permit.toFirestore(),
        'actual_time_in': Timestamp.fromDate(timeIn),
      });

      await withClock(Clock.fixed(now), () async {
        await expectLater(
          permitService.recordTimeIn('p3'),
          throwsStateError,
        );
      });
    });
  });
}
