import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:permission_app/features/authentication/domain/deliquency_log_model.dart';


void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  group('DelinquencyLogModel', () {
    test('toFirestore uses the schema keys', () {
      final map = DelinquencyLogModel(
        id: 'd1',
        userId: 'u1',
        permitId: 'p1',
        violationType: 'LATE CHECK IN',
        violationDescription: 'Returned 2 hours late',
        reportedBy: 'admin1',
        createdAt: DateTime.utc(2026, 10, 31),
      ).toFirestore();

      expect(
        map.keys,
        containsAll([
          'user_id', 'permit_id', 'violation_type',
          'violation_description', 'reported_by', 'created_at',
        ]),
      );
      expect(map['created_at'], isA<Timestamp>());
    });

    test('round-trips with all fields set', () async {
      final col = DelinquencyLogModel.collectionOf(db);
      final created = DateTime.utc(2026, 10, 31, 1);
      await col.doc('d1').set(DelinquencyLogModel(
            id: 'd1',
            userId: 'u1',
            permitId: 'p1',
            violationType: 'LATE CHECK IN',
            violationDescription: 'Returned 2 hours late',
            reportedBy: 'admin1',
            createdAt: created,
          ));

      final loaded = (await col.doc('d1').get()).data()!;
      expect(loaded.id, 'd1');
      expect(loaded.userId, 'u1');
      expect(loaded.permitId, 'p1');
      expect(loaded.violationType, 'LATE CHECK IN');
      expect(loaded.violationDescription, 'Returned 2 hours late');
      expect(loaded.reportedBy, 'admin1');
      expect(loaded.createdAt!.toUtc(), created);
    });

    test('NO FILED PERMIT log keeps permit_id and reported_by null', () async {
      final col = DelinquencyLogModel.collectionOf(db);
      await col.doc('d2').set(DelinquencyLogModel(
            id: 'd2',
            userId: 'u1',
            violationType: 'NO FILED PERMIT',
            violationDescription: 'Not in room during check',
          ));

      final loaded = (await col.doc('d2').get()).data()!;
      expect(loaded.permitId, isNull);
      expect(loaded.reportedBy, isNull);
    });

    test('server timestamp is applied when createdAt is null', () async {
      final col = DelinquencyLogModel.collectionOf(db);
      await col.doc('d3').set(DelinquencyLogModel(
            id: 'd3',
            userId: 'u1',
            violationType: 'LATE CHECK IN',
            violationDescription: '',
          ));

      final loaded = (await col.doc('d3').get()).data()!;
      expect(loaded.createdAt, isNotNull);
    });
  });
}