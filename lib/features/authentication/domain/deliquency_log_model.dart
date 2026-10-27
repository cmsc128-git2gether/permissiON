import 'package:cloud_firestore/cloud_firestore.dart';

// Model for a delinquency record, stored at delinquency_logs/{delinquency_id}
class DelinquencyLogModel {
  final String id; // Firestore doc ID (delinquency_id)
  final String userId; // FK -> users/{user_id} (the delinquent end user)
  final String? permitId; // FK -> permits/{permit_id}; null for NO FILED PERMIT
  final String violationType; // e.g. 'LATE CHECK IN', 'NO FILED PERMIT'
  final String violationDescription;
  final String? reportedBy; // FK -> users/{admin_id}; null if system-generated
  final DateTime? createdAt; // Null until the server timestamp resolves

  DelinquencyLogModel({
    required this.id,
    required this.userId,
    this.permitId,
    required this.violationType,
    required this.violationDescription,
    this.reportedBy,
    this.createdAt,
  });

  // Builds a DelinquencyLogModel from the Firestore doc at delinquency_logs/{id}
  factory DelinquencyLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? {};
    return DelinquencyLogModel(
      id: snapshot.id,
      userId: data['user_id'] ?? '',
      permitId: data['permit_id'],
      violationType: data['violation_type'] ?? '',
      violationDescription: data['violation_description'] ?? '',
      reportedBy: data['reported_by'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'permit_id': permitId,
      'violation_type': violationType,
      'violation_description': violationDescription,
      'reported_by': reportedBy,
      // Let the server stamp new logs when no time is given
      'created_at': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }
}
