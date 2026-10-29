import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:permission_app/features/authentication/domain/qr_model.dart';

QrCodeModel buildQr({
  String status = QrStatus.active,
  DateTime? expiresAt,
  DateTime? scannedAt,
  String? scannedBy,
}) {
  return QrCodeModel(
    id: 'q1',
    permitId: 'p1',
    adminId: 'admin1',
    status: status,
    createdAt: DateTime.utc(2026, 10, 30, 13),
    expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 6)),
    scannedAt: scannedAt,
    scannedBy: scannedBy,
  );
}

void main() {
  group('QrCodeModel.isValid', () {
    test('true when ACTIVE and not expired', () {
      expect(buildQr().isValid, isTrue);
    });

    test('false when expired', () {
      final qr = buildQr(expiresAt: DateTime.now().subtract(const Duration(minutes: 1)));
      expect(qr.isValid, isFalse);
    });

    test('false when SCANNED or CANCELLED', () {
      expect(buildQr(status: QrStatus.scanned).isValid, isFalse);
      expect(buildQr(status: QrStatus.cancelled).isValid, isFalse);
    });
  });

  group('QrCodeModel Firestore mapping', () {
    test('toFirestore uses the schema keys', () {
      final map = buildQr().toFirestore();
      expect(
        map.keys,
        containsAll([
          'permit_id', 'admin_id', 'status', 'created_at',
          'expires_at', 'scanned_at', 'scanned_by',
        ]),
      );
      expect(map['scanned_at'], isNull);
      expect(map['scanned_by'], isNull);
      expect(map['status'], 'ACTIVE');
    });

    test('round-trips through the typed collection', () async {
      final db = FakeFirebaseFirestore();
      final col = QrCodeModel.collectionOf(db);
      final scanned = DateTime.utc(2026, 10, 30, 21, 45);
      await col.doc('q1').set(
            buildQr(status: QrStatus.scanned, scannedAt: scanned, scannedBy: 'guard1'),
          );

      final loaded = (await col.doc('q1').get()).data()!;
      expect(loaded.id, 'q1');
      expect(loaded.permitId, 'p1');
      expect(loaded.adminId, 'admin1');
      expect(loaded.status, QrStatus.scanned);
      expect(loaded.scannedAt!.toUtc(), scanned);
      expect(loaded.scannedBy, 'guard1');
    });
  });
}