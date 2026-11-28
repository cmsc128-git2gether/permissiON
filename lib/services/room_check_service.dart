import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_check_row.dart';

class RoomCheckService {
  RoomCheckService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ignore: unused_field
  final FirebaseFirestore _db;

  /// Roster for the Manila day containing [day]: every resident, one row per
  /// permit that day, or one "No permit" row. Sorted numerically by room.
  /// "That day's permits" = ACTIVE, OVERDUE or COMPLETED with expected return
  /// on that Manila day (rule to confirm, see BE-8).
  Stream<List<RoomCheckRow>> listenToRoster(DateTime day) {
    // TODO(BE-8)
    return Stream.value(const []);
  }

  /// Writes room_checks/{dayKey}_{userId}. Overwrites, so a mistaken tap can be fixed.
  /// Never changes a permit. present == false on a no-permit row also creates
  /// the no-permit delinquency log in the same batch.
  Future<void> markPresent(
    String adminId,
    String userId,
    DateTime day, {
    required bool present,
    required bool hasPermit,
  }) async {
    // TODO(BE-9)
    throw UnimplementedError('markPresent');
  }
}