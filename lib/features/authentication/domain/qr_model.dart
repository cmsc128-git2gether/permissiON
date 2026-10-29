import 'package:cloud_firestore/cloud_firestore.dart';

// qr status
enum QrStatus {
  active('ACTIVE'),
  scanned('SCANNED'),
  cancelled('CANCELLED');

  // constructor storing the string passed to value
  const QrStatus(this.value);
  final String value; // to firestore

  static QrStatus fromString(String db) => values.firstWhere(
        (e) => e.value == db,
        orElse: () => throw ArgumentError('Invalid QrStatus: $db'),
      );
}

// Model for a QR code, stored at qr/{qr_id}
class QrCodeModel {
  final String id;                    // Firestore doc ID (qr_id)
  final String permitId;              // FK -> permits/{permit_id}
  final String adminId;               // FK -> users/{admin_id} (admin who approved)
  final QrStatus status;              // Defaults to QrStatus.active
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? scannedAt;          // null until scanned
  final String? scannedBy;            // FK -> users/{user_id}; null until scanned
  
  QrCodeModel({
    required this.id,
    required this.permitId,
    required this.adminId,
    this.status = QrStatus.active,
    required this.createdAt,
    required this.expiresAt,
    this.scannedAt,
    this.scannedBy,
  });

  // A QR is valid only while ACTIVE and not yet expired
  bool get isValid =>
      status == QrStatus.active && DateTime.now().isBefore(expiresAt);

  // Builds a QrCodeModel from the Firestore doc at qr/{id}
  factory QrCodeModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? {};
    return QrCodeModel(
      id: snapshot.id,
      permitId: data['permit_id'] ?? '',
      adminId: data['admin_id'] ?? '',
      status: QrStatus.fromString(data['status'] ?? QrStatus.active.value),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      expiresAt: (data['expires_at'] as Timestamp).toDate(),
      scannedAt: (data['scanned_at'] as Timestamp?)?.toDate(),
      scannedBy: data['scanned_by'],
    );
  }

  // Converts to a Firestore map; the doc ID is not stored as a field
  Map<String, dynamic> toFirestore() {
    return {
      'permit_id': permitId,
      'admin_id': adminId,
      'status': status.value,
      'created_at': Timestamp.fromDate(createdAt),
      'expires_at': Timestamp.fromDate(expiresAt),
      'scanned_at':
          scannedAt == null ? null : Timestamp.fromDate(scannedAt!),
      'scanned_by': scannedBy,
    };
  }

  // Typed reference to qr/{qr_id}
  static CollectionReference<QrCodeModel> collectionOf(FirebaseFirestore db) =>
      db.collection('qr').withConverter<QrCodeModel>(
            fromFirestore: QrCodeModel.fromFirestore,
            toFirestore: (qr, _) => qr.toFirestore(),
          );

  // Same reference on the default Firestore instance
  static CollectionReference<QrCodeModel> get collection =>
      collectionOf(FirebaseFirestore.instance);
}