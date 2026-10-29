import 'package:cloud_firestore/cloud_firestore.dart';

// violation types
enum ViolationType {
  lateCheckIn('LATE CHECK IN'),
  noFiledPermit('NO FILED PERMIT');

  // constructor storing the string passed to value
  const ViolationType(this.value);
  final String value; // to firestore

  static ViolationType fromString(String db) => values.firstWhere(
        (e) => e.value == db,
        orElse: () => throw ArgumentError('Invalid ViolationType: $db'),
      );
}

// Model for a delinquency log, stored at delinquency_logs/{delinquency_id}
class DelinquencyLogModel {
  final String id;                    // Firestore doc ID (delinquency_id)
  final String userId;                // FK -> users/{user_id}
  final String? permitId;             // FK -> permits/{permit_id}; null for NO FILED PERMIT
  final ViolationType violationType;
  final String violationDescription;
  final String? reportedBy;           // FK -> users/{admin_id}; null if system-generated
  final DateTime? createdAt;          // null on create -> server timestamp is written

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
      violationType: ViolationType.fromString(
          data['violation_type'] ?? ViolationType.lateCheckIn.value),
      violationDescription: data['violation_description'] ?? '',
      reportedBy: data['reported_by'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  // Converts to a Firestore map; the doc ID is not stored as a field
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'permit_id': permitId,
      'violation_type': violationType.value,
      'violation_description': violationDescription,
      'reported_by': reportedBy,
      'created_at': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  // Typed reference to delinquency_logs/{delinquency_id}
  static CollectionReference<DelinquencyLogModel> collectionOf(
          FirebaseFirestore db) =>
      db.collection('delinquency_logs').withConverter<DelinquencyLogModel>(
            fromFirestore: DelinquencyLogModel.fromFirestore,
            toFirestore: (log, _) => log.toFirestore(),
          );

  // Same reference on the default Firestore instance
  static CollectionReference<DelinquencyLogModel> get collection =>
      collectionOf(FirebaseFirestore.instance);
}