import 'package:cloud_firestore/cloud_firestore.dart';

/// One attendance mark, stored at room_checks/{dayKey}_{userId}.
class RoomCheckModel {
  const RoomCheckModel({
    required this.id,
    required this.userId,
    required this.date, // Manila 'yyyy-MM-dd'
    required this.present,
    required this.checkedBy,
    this.checkedAt, // null while the server timestamp is pending
  });

  final String id, userId, date, checkedBy;
  final bool present;
  final DateTime? checkedAt;

  // TODO(BE-9): fromFirestore / toFirestore (keys: user_id, date, present,
  // checked_by, checked_at).
}