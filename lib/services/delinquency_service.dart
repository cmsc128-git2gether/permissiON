import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data_enums.dart';
import '../models/delinquency_log_model.dart';

class DelinquencyService {
  DelinquencyService({FirebaseFirestore? firestore});

  ///for admin: every log, newest first.
  Stream<List<DelinquencyLogModel>> listenToDelinquencies() =>
      Stream.value(const []);

  ///singular student's logs, newest first.
  Stream<List<DelinquencyLogModel>> listenToUserDelinquencies(String userId) =>
      Stream.value(const []);

  /// Creates a log, copying user_id from the permit. Idempotent: one log per
  /// (permitId, reason), using the doc id '${permitId}_${reason.value}'.
  /// Throws StateError if the permit does not exist.
  Future<void> flagPermit(String permitId, DelinquencyReason reason) async =>
      throw UnimplementedError('flagPermit');

  /// Marks a log resolved with an optional note, in a transaction.
  /// Throws StateError if the log is missing or already resolved.
  Future<void> resolve(String adminId, String logId, {String? note}) async =>
      throw UnimplementedError('resolve');
}