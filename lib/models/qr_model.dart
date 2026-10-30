import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_app/models/data_enums.dart';


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

  // A QR is valid at [time] only if it is ACTIVE and [time] is before expiry.
  // Time is a parameter so edge cases (e.g. 5:59 PM) can be tested without
  // depending on the real clock.
  bool isValidAt(DateTime time) =>
      status == QrStatus.active && time.isBefore(expiresAt);

  // Convenience for callers that just want "valid right now"
  bool get isValid => isValidAt(DateTime.now());

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
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
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