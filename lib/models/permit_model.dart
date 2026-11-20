import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_app/models/data_enums.dart';


// Model for a permit, stored at permits/{permit_id}
class PermitModel {
  final String id;                    // Firestore doc ID (permit_id)
  final String userId;                // FK -> users/{user_id} (the end user who filed it)
  final String surname;               // Copied from end_user_profiles at filing time
  final String givenName;             // Copied from end_user_profiles at filing time
  final String roomNum;
  final PermitType permitType;
  final String destination;
  final String purpose;
  final String emergencyContactPerson;
  final String emergencyContactNum;
  final DateTime expectedTimeIn;
  final DateTime? actualTimeIn;       // Set from qr.scanned_at; null on default
  final PermitStatus permitStatus;    // Defaults to PermitStatus.pending
  final String? disapprovalReason;     // Set when denied
  final String? approvedBy;           // FK -> users/{admin_id}; null until acted on
  final DateTime? approvedAt;
  final String? qrId;                 // FK -> qr/{qr_id}; null on default
  final DateTime createdAt;
  final int? floor;                // null on permits filed before this field existed
  final bool isLateFiling;         // filed after the 6 PM cutoff
  final String? lateFilingReason;  // required when isLateFiling


  PermitModel({
    required this.id,
    required this.userId,
    required this.surname,
    required this.givenName,
    required this.roomNum,
    required this.permitType,
    required this.destination,
    required this.purpose,
    required this.emergencyContactPerson,
    required this.emergencyContactNum,
    required this.expectedTimeIn,
    this.actualTimeIn,
    this.permitStatus = PermitStatus.pending,
    this.disapprovalReason,
    this.approvedBy,
    this.approvedAt,
    this.qrId,
    required this.createdAt,
    this.floor,
    this.isLateFiling = false,
    this.lateFilingReason,
  });

  //--------  helpers  ---------

  /// "Surname, Given", or just the surname if the given name is empty.
  String get fullName =>
      givenName.isEmpty ? surname : '$surname, $givenName';

  /// "Given Surname", or just the surname if the given name is empty.
  String get displayName =>
      givenName.isEmpty ? surname : '$givenName $surname';

  /// Last 4 characters of the id (no permit-number counter for the prototype).
  String get displayNumber =>
      id.length <= 4 ? id : id.substring(id.length - 4);
  
  /// Trimmed late-filing reason, or 'No reason given' if missing or blank.
  String get lateFilingReasonOrDefault {
    final r = lateFilingReason?.trim();
    return (r == null || r.isEmpty) ? 'No reason given' : r;
  }

  /// returned after the expected time.
  bool get isLate =>
      actualTimeIn != null && actualTimeIn!.isAfter(expectedTimeIn);

  /// ACTIVE, past the expected time, and not yet timed in.
  bool isOverdueAt(DateTime now) =>
      permitStatus == PermitStatus.active &&
      actualTimeIn == null &&
      now.isAfter(expectedTimeIn);

  /// PENDING and created before the start of [now]'s day (the 12 AM rule).
  /// Pass [now] in the dorm's time zone
  bool isStalePendingAt(DateTime now) =>
      permitStatus == PermitStatus.pending &&
      createdAt.isBefore(DateTime(now.year, now.month, now.day));

  // Builds a PermitModel from the Firestore doc at permits/{id}
  factory PermitModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? {};

    // Legacy docs only have full_name: put the whole name in surname.
    final String? rawSurname = data['surname'] as String?;
    final String surname = rawSurname ?? (data['full_name'] ?? '') as String;
    final String givenName =
        rawSurname == null ? '' : (data['given_name'] ?? '') as String;

    return PermitModel(
      id: snapshot.id,
      userId: data['user_id'] ?? '',
      surname: surname,
      givenName: givenName,
      roomNum: data['room_num'] ?? '',
      permitType:
          PermitType.fromString(data['permit_type'] ?? PermitType.late.value),
      destination: data['destination'] ?? '',
      purpose: data['purpose'] ?? '',
      emergencyContactPerson: data['emergency_contact_person'] ?? '',
      emergencyContactNum: data['emergency_contact_num'] ?? '',
      expectedTimeIn: (data['expected_time_in'] as Timestamp).toDate(),
      actualTimeIn: (data['actual_time_in'] as Timestamp?)?.toDate(),
      permitStatus: PermitStatus.fromString(
          data['permit_status'] ?? PermitStatus.pending.value),
      disapprovalReason: data['disapproval_reason'],
      approvedBy: data['approved_by'],
      approvedAt: (data['approved_at'] as Timestamp?)?.toDate(),
      qrId: data['qr_id'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      floor: data['floor'] as int?,
      isLateFiling: data['is_late_filing'] ?? false,
      lateFilingReason: data['late_filing_reason'],
    );
  }

  // Converts to a Firestore map; the doc ID is not stored as a field
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'surname': surname,
      'given_name': givenName,
      'full_name': fullName, // derived, for search and older readers
      'room_num': roomNum,
      'permit_type': permitType.value,
      'destination': destination,
      'purpose': purpose,
      'emergency_contact_person': emergencyContactPerson,
      'emergency_contact_num': emergencyContactNum,
      'expected_time_in': Timestamp.fromDate(expectedTimeIn),
      'actual_time_in':
          actualTimeIn == null ? null : Timestamp.fromDate(actualTimeIn!),
      'permit_status': permitStatus.value,
      'disapproval_reason': disapprovalReason,
      'approved_by': approvedBy,
      'approved_at': approvedAt == null ? null : Timestamp.fromDate(approvedAt!),
      'qr_id': qrId,
      'created_at': Timestamp.fromDate(createdAt),
      'floor': floor,
      'is_late_filing': isLateFiling,
      'late_filing_reason': lateFilingReason,
    };
  }

  // Typed reference to permits/{permit_id}
  static CollectionReference<PermitModel> collectionOf(FirebaseFirestore db) =>
      db.collection('permits').withConverter<PermitModel>(
            fromFirestore: PermitModel.fromFirestore,
            toFirestore: (permit, _) => permit.toFirestore(),
          );

  // Same reference on the default Firestore instance
  static CollectionReference<PermitModel> get collection =>
      collectionOf(FirebaseFirestore.instance);
}