import 'package:cloud_firestore/cloud_firestore.dart';

// Allowed values for qr status
class QrStatus {
  static const active = 'ACTIVE';
  static const scanned = 'SCANNED';
  static const cancelled = 'CANCELLED';
}

// Model for a QR code, stored at qr/{qr_id}
class QrCodeModel {
  final String id; // Firestore doc ID (qr_id)
  final String permitId; // FK -> permits/{permit_id}
  final String adminId; // FK -> users/{admin_id} (admin who issued it)
  final String status; // 'ACTIVE' | 'SCANNED' | 'CANCELLED'
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? scannedAt; // Null on default
  final String? scannedBy; // FK -> users/{user_id}; null until scanned

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

  // Returns True if this QR can still be scanned
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
      status: data['status'] ?? QrStatus.active,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      expiresAt: (data['expires_at'] as Timestamp).toDate(),
      scannedAt: (data['scanned_at'] as Timestamp?)?.toDate(),
      scannedBy: data['scanned_by'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'permit_id': permitId,
      'admin_id': adminId,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'expires_at': Timestamp.fromDate(expiresAt),
      'scanned_at': scannedAt == null ? null : Timestamp.fromDate(scannedAt!),
      'scanned_by': scannedBy,
    };
  }
}