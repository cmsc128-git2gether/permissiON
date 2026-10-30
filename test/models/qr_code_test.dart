import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_app/models/data_enums.dart';

import 'package:permission_app/models/qr_model.dart';

// Fixed expiry so no test depends on the real clock as of now
final expiry = DateTime.utc(2026, 10, 30, 18); // 6:00 PM

QrCodeModel buildQr({
  QrStatus status = QrStatus.active,
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
    expiresAt: expiresAt ?? expiry,
    scannedAt: scannedAt,
    scannedBy: scannedBy,
  );
}

void main() {
  group('QrCodeModel.isValidAt', () {
    test('true one minute before expiry (5:59 PM)', () {
      expect(buildQr().isValidAt(DateTime.utc(2026, 10, 30, 17, 59)), isTrue);
    });

    test('false exactly at expiry', () {
      expect(buildQr().isValidAt(expiry), isFalse);
    });

    test('false after expiry', () {
      expect(buildQr().isValidAt(DateTime.utc(2026, 10, 30, 18, 1)), isFalse);
    });

    test('false when SCANNED or CANCELLED, even before expiry', () {
      final before = DateTime.utc(2026, 10, 30, 17);
      expect(buildQr(status: QrStatus.scanned).isValidAt(before), isFalse);
      expect(buildQr(status: QrStatus.cancelled).isValidAt(before), isFalse);
    });
  });

  group('QrCodeModel.isValid (uses the current time)', () {
    test('true for an ACTIVE QR that expires far in the future', () {
      expect(buildQr(expiresAt: DateTime.utc(2100)).isValid, isTrue);
    });

    test('false for a QR that expired long ago', () {
      expect(buildQr(expiresAt: DateTime.utc(2000)).isValid, isFalse);
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

    test('createdAt falls back to now when created_at is missing', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('qr').doc('q2').set({
        'permit_id': 'p1',
        'admin_id': 'admin1',
        'status': 'ACTIVE',
        'expires_at': Timestamp.fromDate(expiry),
        // no created_at
      });

      final loaded = (await QrCodeModel.collectionOf(db).doc('q2').get()).data()!;
      expect(
        loaded.createdAt.difference(DateTime.now()).abs(),
        lessThan(const Duration(seconds: 5)),
      );
    });
  });
}