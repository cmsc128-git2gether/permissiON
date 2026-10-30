import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/services/metrics_service.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MetricsService metrics;

  Future<void> seedPermit(
    String id, {
    required String userId,
    required PermitStatus status,
    required DateTime createdAt,
  }) =>
      db.collection('permits').doc(id).set({
        'user_id': userId,
        'permit_status': status.value,
        'created_at': Timestamp.fromDate(createdAt),
        'permit_type': PermitType.late.value,
        'full_name': 'Test Name',
        'room_num': '131',
        'destination': 'Bangs',
        'purpose': 'study',
        'emergency_contact_person': 'Contact',
        'emergency_contact_num': '0000000000',
        'expected_time_in': Timestamp.fromDate(createdAt),
      });

  Future<void> seedLog(String id, String userId) =>
      db.collection('delinquency_logs').doc(id).set({'user_id': userId});

  setUp(() {
    db = FakeFirebaseFirestore();
    metrics = MetricsService(firestore: db);
  });

  group('countActivePermits', () {
    test('counts only this user\'s ACTIVE permits', () async {
      final t = DateTime(2026, 10, 1);
      await seedPermit('a1', userId: 'u1', status: PermitStatus.active, createdAt: t);
      await seedPermit('a2', userId: 'u1', status: PermitStatus.active, createdAt: t);
      await seedPermit('p1', userId: 'u1', status: PermitStatus.pending, createdAt: t);
      await seedPermit('d1', userId: 'u1', status: PermitStatus.denied, createdAt: t);
      await seedPermit('a3', userId: 'u2', status: PermitStatus.active, createdAt: t);

      expect(await metrics.countActivePermits('u1'), 2);
    });

    test('returns 0 when the user has no permits', () async {
      expect(await metrics.countActivePermits('nobody'), 0);
    });
  });

  group('listenToPermitHistory', () {
    test('shows only this user\'s permits, newest first', () async {
      final base = DateTime(2026, 10, 25, 12);
      await seedPermit('old', userId: 'u1', status: PermitStatus.completed, createdAt: base);
      await seedPermit('new', userId: 'u1', status: PermitStatus.active,
          createdAt: base.add(const Duration(hours: 1)));
      await seedPermit('other', userId: 'u2', status: PermitStatus.active, createdAt: base);

      final list = await metrics.listenToPermitHistory('u1').first;
      expect(list.map((p) => p.id), ['new', 'old']);
    });

    test('limit', () async {
      final base = DateTime(2026, 10, 25);
      for (var i = 0; i < 5; i++) {
        await seedPermit('p$i', userId: 'u1', status: PermitStatus.completed,
            createdAt: base.add(Duration(hours: i)));
      }
      final list = await metrics.listenToPermitHistory('u1', limit: 3).first;
      expect(list.length, 3);
      expect(list.first.id, 'p4');
    });

    test('shows empty list for a user with no permits', () async {
      expect(await metrics.listenToPermitHistory('nobody').first, isEmpty);
    });
  });

  group('countDelinquencies', () {
    test('counts only this user\'s logs', () async {
      await seedLog('l1', 'u1');
      await seedLog('l2', 'u1');
      await seedLog('l3', 'u2');

      expect(await metrics.countDelinquencies('u1'), 2);
    });

    test('returns 0 when there are none', () async {
      expect(await metrics.countDelinquencies('u1'), 0);
    });
  });
}