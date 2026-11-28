import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data_enums.dart';
import '../models/delinquency_log_model.dart';

class DelinquencyService {
  DelinquencyService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ignore: unused_field
  final FirebaseFirestore _db; // remove the ignore once the bodies use it

  /// Admin: every log, newest first.
  Stream<List<DelinquencyLogModel>> listenToDelinquencies() {
    // TODO(BE-3): orderBy created_at desc.
    return Stream.value(const []);
  }

  /// One student's logs, newest first. Needs index user_id + created_at.
  Stream<List<DelinquencyLogModel>> listenToUserDelinquencies(String userId) {
    // TODO(BE-3)
    return Stream.value(const []);
  }

  /// Overdue permit. Throws StateError if the permit is missing or not OVERDUE.
  /// Idempotent: doc id '${permitId}_overdue'.
  Future<void> flagOverdue(String permitId) async {
    // TODO(BE-3)
    throw UnimplementedError('flagOverdue');
  }

  /// "No" on a no-permit Room Check row. [day] is the Manila day.
  /// Idempotent: doc id '${userId}_${dayKey}_nopermit'. permitId is null.
  Future<void> flagNoPermit(String userId, DateTime day, String adminId) async {
    // TODO(BE-3)
    throw UnimplementedError('flagNoPermit');
  }

  /// Marks ACTIVE permits past their expected time as OVERDUE and flags each.
  /// Returns how many it flagged. Called by the admin dashboard on load.
  Future<int> sweep() async {
    // TODO(BE-4)
    throw UnimplementedError('sweep');
  }
}