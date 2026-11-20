import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_app/models/data_enums.dart'; 
import 'package:permission_app/models/permit_model.dart';
import 'package:permission_app/services/permit_service.dart'; 
import 'package:permission_app/utils/firestore_utils.dart';
import 'package:clock/clock.dart';

void main() {
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
      surname: 'Name', 
      givenName: 'Test',
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

  group('PermitService: isAfterFilingCutoff', () {
    test('false before 6 PM, true at and after (Manila Time)', () {
      // 17:59 Manila = 09:59 UTC
      final beforeCutoffUtc = DateTime.utc(2026, 11, 10, 9, 59);
      expect(PermitService.isAfterFilingCutoff(beforeCutoffUtc), isFalse);

      // 18:00 Manila = 10:00 UTC
      final atCutoffUtc = DateTime.utc(2026, 11, 10, 10, 0);
      expect(PermitService.isAfterFilingCutoff(atCutoffUtc), isTrue);
      
      // 18:01 Manila = 10:01 UTC
      final afterCutoffUtc = DateTime.utc(2026, 11, 10, 10, 1);
      expect(PermitService.isAfterFilingCutoff(afterCutoffUtc), isTrue);
    });
  });

  group('PermitService: createPermit', () {
    test('creates a permit document with initialized and defaulted fields for a user', () async {
      // Run before the cutoff (e.g., 17:00 Manila = 09:00 UTC) to avoid late filing rules
      final beforeCutoff = DateTime.utc(2026, 11, 10, 9, 0);
      
      await withClock(Clock.fixed(beforeCutoff), () async {
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
        expect(data['approved_at'], isNull);
        expect(data['created_at'], isNotNull);
        expect(data['qr_id'], isNull);
        // Verify default late filing fields
        expect(data['is_late_filing'], isFalse);
        expect(data['late_filing_reason'], isNull);
      });
    });
  });

  group('PermitService - Late Filing (AS5)', () {
    final beforeCutoff = DateTime.utc(2026, 11, 10, 9, 59, 59); // 17:59:59 Manila
    final atCutoff = DateTime.utc(2026, 11, 10, 10, 0, 0);     // 18:00:00 Manila
    final afterCutoff = DateTime.utc(2026, 11, 10, 11, 0, 0);  // 19:00 Manila

    test('17:59:59 Manila has no flag', () async {
      await withClock(Clock.fixed(beforeCutoff), () async {
        final permit = createMockPermit(id: '', userId: 'u1');
        final id = await permitService.createPermit(permit);
        
        final data = (await db.collection('permits').doc(id).get()).data()!;
        expect(data['is_late_filing'], isFalse);
        expect(data['late_filing_reason'], isNull);
      });
    });

    test('Exactly 18:00:00 Manila is flagged', () async {
      await withClock(Clock.fixed(atCutoff), () async {
        final permit = createMockPermit(id: '', userId: 'u1');
        final id = await permitService.createPermit(permit, lateReason: 'Valid reason');
        
        final data = (await db.collection('permits').doc(id).get()).data()!;
        expect(data['is_late_filing'], isTrue);
        expect(data['late_filing_reason'], 'Valid reason');
      });
    });

    test('After the cutoff with no reason, empty, or whitespace throws ArgumentError and collection stays empty', () async {
      await withClock(Clock.fixed(afterCutoff), () async {
        final permit = createMockPermit(id: '', userId: 'u1');

        // No reason
        expect(
          () => permitService.createPermit(permit),
          throwsArgumentError,
        );

        // Empty string
        expect(
          () => permitService.createPermit(permit, lateReason: ''),
          throwsArgumentError,
        );

        // Whitespace only
        expect(
          () => permitService.createPermit(permit, lateReason: '   '),
          throwsArgumentError,
        );

        // Ensure nothing was saved
        final snapshot = await db.collection('permits').get();
        expect(snapshot.docs, isEmpty);
      });
    });

    test('A valid reason is stored trimmed', () async {
      await withClock(Clock.fixed(afterCutoff), () async {
        final permit = createMockPermit(id: '', userId: 'u1');
        final id = await permitService.createPermit(permit, lateReason: '  Family emergency  ');
        
        final data = (await db.collection('permits').doc(id).get()).data()!;
        expect(data['is_late_filing'], isTrue);
        expect(data['late_filing_reason'], 'Family emergency');
      });
    });

    test('Before the cutoff with a reason supplied stores no reason', () async {
      await withClock(Clock.fixed(beforeCutoff), () async {
        final permit = createMockPermit(id: '', userId: 'u1');
        // Even though a reason is provided, it should be ignored before the cutoff
        final id = await permitService.createPermit(permit, lateReason: 'Early reason');
        
        final data = (await db.collection('permits').doc(id).get()).data()!;
        expect(data['is_late_filing'], isFalse);
        expect(data['late_filing_reason'], isNull);
      });
    });

    test('A reason over 200 characters is truncated', () async {
      await withClock(Clock.fixed(afterCutoff), () async {
        final permit = createMockPermit(id: '', userId: 'u1');
        final longReason = 'A' * 205; // 205 characters
        
        final id = await permitService.createPermit(permit, lateReason: longReason);
        
        final data = (await db.collection('permits').doc(id).get()).data()!;
        expect(data['is_late_filing'], isTrue);
        expect(data['late_filing_reason'].length, 200);
        expect(data['late_filing_reason'], 'A' * 200);
      });
    });
  });

  group('PermitService: listenToPermit', () {
    test('emits null for a missing doc, the mapped permit, and again on a status change', () async {
      const permitId = 'p_stream_1';
      final stream = permitService.listenToPermit(permitId);

      final futureExpectations = expectLater(
        stream,
        emitsInOrder([
          isNull,
          isA<PermitModel>()
              .having((p) => p.id, 'id', permitId)
              .having((p) => p.permitStatus, 'status', PermitStatus.pending),
          isA<PermitModel>()
              .having((p) => p.id, 'id', permitId)
              .having((p) => p.permitStatus, 'status', PermitStatus.active),
        ]),
      );

      await Future.delayed(Duration.zero);

      final mockPermit = createMockPermit(id: permitId, userId: 'user_123', status: PermitStatus.pending);
      await db.collection('permits').doc(permitId).set(mockPermit.toFirestore());

      await Future.delayed(Duration.zero);

      await db.collection('permits').doc(permitId).update({
        'permit_status': PermitStatus.active.value,
      });

      await futureExpectations;
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

  group('PermitService - cancelPermit', () {
    const ownerId = 'user_123';
    const otherId = 'user_999';

    Future<void> seedPermit(
      String id, {
      PermitStatus status = PermitStatus.pending,
      String userId = ownerId,
    }) async {
      final permit = createMockPermit(id: id, userId: userId, status: status);
      await db.collection('permits').doc(id).set(permit.toFirestore());
    }

    Future<Map<String, dynamic>> load(String id) async =>
        (await db.collection('permits').doc(id).get()).data()!;

    //=== success ===
    test('owner cancels a PENDING permit', () async {
      await seedPermit('p1', status: PermitStatus.pending);

      await permitService.cancelPermit(ownerId, 'p1');

      expect((await load('p1'))['permit_status'], 'CANCELLED');
    });

    test('owner cancels an ACTIVE permit', () async {
      await seedPermit('p1', status: PermitStatus.active);

      await permitService.cancelPermit(ownerId, 'p1');

      expect((await load('p1'))['permit_status'], 'CANCELLED');
    });

    test('cancelling changes only the status field', () async {
      await seedPermit('p1', status: PermitStatus.pending);
      final before = await load('p1');

      await permitService.cancelPermit(ownerId, 'p1');

      final after = await load('p1');
      expect(after['user_id'], before['user_id']);
      expect(after['type'], before['type']);
    });

    //=== StateError cases ===
    test('throws StateError for a missing permit', () async {
      await expectLater(
        () => permitService.cancelPermit(ownerId, 'does_not_exist'), 
        throwsStateError,
      );
    });

    test('throws StateError when the permit belongs to another user', () async {
      await seedPermit('p1', status: PermitStatus.pending);

      await expectLater(
        () => permitService.cancelPermit(otherId, 'p1'), 
        throwsStateError,
      );

      // and nothing was changed
      expect((await load('p1'))['permit_status'], 'PENDING');
    });

    for (final status in [
      PermitStatus.completed,
      PermitStatus.cancelled,
      PermitStatus.denied,
      PermitStatus.overdue,
    ]) {
      test('throws StateError for a ${status.value} permit', () async {
        await seedPermit('p1', status: status);

        await expectLater(
          () => permitService.cancelPermit(ownerId, 'p1'), 
          throwsStateError,
        );

        expect((await load('p1'))['permit_status'], status.value); // unchanged
      });
    }
  });

  group('PermitService - listenToPendingPermits', () {
    final base = DateTime(2026, 10, 30, 8, 0);

    Future<void> seed(
      String id,
      PermitStatus status, {
      String userId = 'user_123',
      DateTime? createdAt,
    }) async {
      final permit = createMockPermit(id: id, userId: userId, status: status);
      await db.collection('permits').doc(id).set({
        ...permit.toFirestore(),
        'created_at': Timestamp.fromDate(createdAt ?? base),
      });
    }

    test('emits only PENDING permits', () async {
      await seed('p1', PermitStatus.pending);
      await seed('p2', PermitStatus.active);
      await seed('p3', PermitStatus.pending);
      await seed('p4', PermitStatus.cancelled);

      final list = await permitService.listenToPendingPermits().first;

      expect(list.map((p) => p.id), unorderedEquals(['p1', 'p3']));
    });

    test('emits an empty list when nothing is pending', () async {
      await seed('p1', PermitStatus.completed);

      final list = await permitService.listenToPendingPermits().first;

      expect(list, isEmpty);
    });

    test('includes pending permits from all users', () async {
      await seed('p1', PermitStatus.pending, userId: 'user_1');
      await seed('p2', PermitStatus.pending, userId: 'user_2');

      final list = await permitService.listenToPendingPermits().first;

      expect(list.length, 2);
    });

    test('orders oldest first by created_at', () async {
      await seed('newest', PermitStatus.pending,
          createdAt: base.add(const Duration(hours: 2)));
      await seed('oldest', PermitStatus.pending, createdAt: base);
      await seed('middle', PermitStatus.pending,
          createdAt: base.add(const Duration(hours: 1)));

      final list = await permitService.listenToPendingPermits().first;

      expect(list.map((p) => p.id), ['oldest', 'middle', 'newest']);
    });

    test('limit caps the number of results, keeping the oldest', () async {
      await seed('a', PermitStatus.pending, createdAt: base);
      await seed('b', PermitStatus.pending,
          createdAt: base.add(const Duration(hours: 1)));
      await seed('c', PermitStatus.pending,
          createdAt: base.add(const Duration(hours: 2)));

      final list = await permitService.listenToPendingPermits(limit: 2).first;

      expect(list.map((p) => p.id), ['a', 'b']);
    });

    test('no limit returns everything', () async {
      for (var i = 0; i < 5; i++) {
        await seed('p$i', PermitStatus.pending,
            createdAt: base.add(Duration(minutes: i)));
      }

      final list = await permitService.listenToPendingPermits().first;

      expect(list.length, 5);
    });

    test('emits a new list when a permit stops being pending', () async {
      await seed('p1', PermitStatus.pending);

      final expectation = expectLater(
        permitService.listenToPendingPermits().map((l) => l.length),
        emitsInOrder([1, 0]),
      );

      await db.collection('permits').doc('p1').update({
        'permit_status': PermitStatus.cancelled.value,
      });

      await expectation;
    });

    test('emits a new list when a pending permit is added', () async {
      final expectation = expectLater(
        permitService.listenToPendingPermits().map((l) => l.length),
        emitsInOrder([0, 1]),
      );

      await seed('p1', PermitStatus.pending);

      await expectation;
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
        await permitService.recordTimeIn('admin_1', 'p1', at: timeIn);
      });

      final data = (await db.collection('permits').doc('p1').get()).data()!;

      expect(data['permit_status'], PermitStatus.completed.value);
      expect(parseTimestamp(data['actual_time_in']), timeIn);
    });

    test('ACTIVE permit with no `at` must be COMPLETED', () async {
      final samplePermit =
          createMockPermit(id: 'p1', userId: 'user_123', status: PermitStatus.active);
      await db.collection('permits').doc('p1').set(samplePermit.toFirestore());

      // run the service with the clock frozen at `now`
      await withClock(Clock.fixed(now), () async {
        await permitService.recordTimeIn('admin_1', 'p1');
      });

      final data = (await db.collection('permits').doc('p1').get()).data()!;

      expect(data['permit_status'], PermitStatus.completed.value);
      expect(parseTimestamp(data['actual_time_in']), now);
    });

    test('at == now is allowed', () async {
      final p = createMockPermit(id: 'p1', userId: 'u1', status: PermitStatus.active);
      await db.collection('permits').doc('p1').set(p.toFirestore());

      await withClock(Clock.fixed(now), () async {
        await permitService.recordTimeIn('admin_1', 'p1', at: now);
      });

      final data = (await db.collection('permits').doc('p1').get()).data()!;
      expect(data['permit_status'], PermitStatus.completed.value);
    });

    test('throws ArgumentError if at is in the future', () async {
      final samplePermit = createMockPermit(id: 'p1', userId: 'user_123', status: PermitStatus.active);
      await db.collection('permits').doc('p1').set(samplePermit.toFirestore());

      await withClock(Clock.fixed(now), () async {
        await expectLater(
          () => permitService.recordTimeIn('admin_1', 'p1', at: now.add(const Duration(hours: 1))),
          throwsArgumentError,
        );
      });

      final data = (await db.collection('permits').doc('p1').get()).data()!;
      expect(data['permit_status'], PermitStatus.active.value);
      expect(data['actual_time_in'], isNull);
    });

    test('throws StateError for a missing permit', () async {
      await withClock(Clock.fixed(now), () async {
        await expectLater(
          () => permitService.recordTimeIn('admin_1', 'does_not_exist'),
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
          () => permitService.recordTimeIn('admin_1', 'p2'),
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
          () => permitService.recordTimeIn('admin_1', 'p3'),
          throwsStateError,
        );
      });
    });
  });

  group('listenToAllPermits', () {
    final base = DateTime(2026, 11, 19, 8, 0);

    Future<void> seed(String id, String userId, DateTime createdAt,
        {PermitStatus status = PermitStatus.pending}) async {
      final p = createMockPermit(id: id, userId: userId, status: status);
      await db.collection('permits').doc(id).set({
        ...p.toFirestore(),
        'created_at': Timestamp.fromDate(createdAt),
      });
    }

    test('permits from several users come back newest first', () async {
      await seed('old', 'user_1', base);
      await seed('new', 'user_2', base.add(const Duration(hours: 2)));
      await seed('mid', 'user_3', base.add(const Duration(hours: 1)),
          status: PermitStatus.active);

      final list = await permitService.listenToAllPermits().first;

      expect(list.map((p) => p.id), ['new', 'mid', 'old']);
    });

    test('emits an empty list when there are no permits', () async {
      final list = await permitService.listenToAllPermits().first;

      expect(list, isEmpty);
    });

    test('limit caps the results, keeping the newest', () async {
      await seed('a', 'user_1', base);
      await seed('b', 'user_1', base.add(const Duration(hours: 1)));
      await seed('c', 'user_1', base.add(const Duration(hours: 2)));

      final list = await permitService.listenToAllPermits(limit: 2).first;

      expect(list.map((p) => p.id), ['c', 'b']);
    });
  });
}
