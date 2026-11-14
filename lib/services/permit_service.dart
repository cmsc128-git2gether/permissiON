import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clock/clock.dart'; // injects clock
import '../models/data_enums.dart';
import '../models/permit_model.dart';
import '../utils/firestore_utils.dart';
import 'permit_filter.dart';

class PermitService {
 //------------- contract stubs: signatures only --------------------
// this method is placeholder for now, but will be implemented in the future
  
  //admin history of all permits to be implemented in issue #42, for now returns empty list
  Stream<List<PermitModel>> listenToAllPermits() => Stream.value(const []);

  //detail view of a single permit using permit_detail_screen.dart, returns null if the permit does not exist
  Stream<PermitModel?> listenToPermit(String permitId){
    return _permits.doc(permitId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return PermitModel.fromFirestore(snap, null);
    });
  }


  //admin history of all pending permits to be implemented in issue #43
  Stream<List<PermitModel>> listenToPendingPermits({int? limit}) {
    var query = _permits
        .where('permit_status', isEqualTo: PermitStatus.pending.value)
        .orderBy('created_at'); // oldest or first requests first
    if (limit != null) query = query.limit(limit);

    return query.snapshots().map((snap) =>
        snap.docs.map((d) => PermitModel.fromFirestore(d, null)).toList());
  }

  //user cancels a pending permit to be implemented in issue #43
  Future<void> cancelPermit(String userId, String permitId) async {
    final ref = _permits.doc(permitId);

    //----------------- transaction from snapshot --------------------
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

    //failure/guard messages
      if (!snapshot.exists) {
        throw StateError('Permit $permitId does not exist');
      }

      if (snapshot.data()!['user_id'] != userId) {
        throw StateError('Permit $permitId does not belong to user $userId');
      }

      if (snapshot.data()!['permit_status'] != PermitStatus.pending.value 
        && snapshot.data()!['permit_status'] != PermitStatus.active.value) {
        throw StateError('Only PENDING or ACTIVE permits can be cancelled.');
      }

      //write
      transaction.update(ref, {
        'permit_status': PermitStatus.cancelled.value,
      });
    });
  }

  //admin manual override of a permit's status, for now throws unimplemented error
  // issue #44
  Future<void> recordTimeIn(
    String permitId, {
    DateTime? at,
  }) async {
    // validates time is not future
    if (at != null && at.isAfter(clock.now())) {
      throw StateError('Time-in cannot be in the future.');
    }

    final ref = _permits.doc(permitId);
    // final qr = _db.collection(qrId);
    // jic of using the qr

    // transaction
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      // failure messages, StateErrors
      // missing permit
      if (!snapshot.exists) {
        throw StateError('Permit $permitId does not exist');
      }
      // non-ACTIVE permit
      if (snapshot.data()!['permit_status'] != PermitStatus.active.value) {
        throw StateError('Only ACTIVE permits can have a recorded time-in.');
      }
      // already has a time-in
      if (snapshot.data()!['actual_time_in'] != null) {
        throw StateError('Permit $permitId already has a recorded time-in.');
      }

      //write
      transaction.update(ref, {
        //'actual_time_in': at != null ? toTimestamp(at) : FieldValue.serverTimestamp(),
        'actual_time_in': toTimestamp(at ?? clock.now()), // injected clock.now() instead of server timestamp
        'permit_status':PermitStatus.completed.value,
      });
    });

  }

// ----------------------------------------------------------------------------

  //optional firestore instance for testing, otherwise use default
  PermitService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  //helper shortcut to 'permits/' collection
  CollectionReference<Map<String, dynamic>> get _permits =>
      _db.collection('permits');

  // ===========================================================================
  // Implemented
  // ===========================================================================

  /// 6 PM filing cutoff (AS5). Pure, so the UI can warn before submitting.
  /// Pass the time in Asia/Manila.
  static bool isAfterFilingCutoff(DateTime now) => now.hour >= 18;

  /// New permit is saved as PENDING with empty review fields. Returns the new id.
  /// [lateReason] is accepted for the contract but NOT applied yet.
  /// Issue #5 will require it after the cutoff and write is_late_filing
  /// and late_filing_reason.
  Future<String> createPermit(PermitModel permit, {String? lateReason}) async {
    final data = permit.toFirestore()
      ..['permit_status'] = PermitStatus.pending.value
      ..['actual_time_in'] = null
      ..['disapproval_reason'] = null
      ..['approved_by'] = null
      ..['approved_at'] = null
      ..['qr_id'] = null
      ..['created_at'] = FieldValue.serverTimestamp();
    final ref = await _permits.add(data);
    return ref.id;
  }

  /// Real-time stream of a user's permits, newest first.
  Stream<List<PermitModel>> listenToUserPermits(String userId) {
    return _permits
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PermitModel.fromFirestore(doc, null)).toList());
  }

  /// Detail view: live updates for one permit. Emits null if it does not exist.
  Stream<PermitModel?> listenToPermit(String permitId) {
    return _permits.doc(permitId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return PermitModel.fromFirestore(snap, null);
    });
  }

  /// Admin-only (enforced by security rules). Runs in a transaction.
  Future<void> updatePermitStatus(
    String adminId,
    String permitId,
    String status, {
    String? disapprovalReason,
  }) {
    // fail fast
    if (status != PermitStatus.denied.value && disapprovalReason != null) {
      throw ArgumentError(
          'disapprovalReason should only be provided when denying a permit');
    }
    if (status == PermitStatus.denied.value && disapprovalReason == null) {
      throw ArgumentError(
          'disapprovalReason must be provided when denying a permit');
    }
    if (status == PermitStatus.denied.value && disapprovalReason!.isEmpty) {
      throw ArgumentError('disapprovalReason cannot be empty when denying a permit');
    }
    if (status != PermitStatus.active.value &&
        status != PermitStatus.denied.value) {
      throw ArgumentError(
          'status must be either active or denied when updating a permit');
    }

    final ref = _permits.doc(permitId);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        throw StateError('Permit $permitId does not exist');
      }
      if (snapshot.data()!['permit_status'] != PermitStatus.pending.value) {
        throw StateError('Only PENDING permits can be reviewed');
      }

      transaction.update(ref, {
        'permit_status': status,
        'approved_by': adminId,
        'approved_at': FieldValue.serverTimestamp(),
        'disapproval_reason':
            status == PermitStatus.denied.value ? disapprovalReason : null,
      });
    });
  }

  /// Admin manually records the actual return time: ACTIVE -> COMPLETED.
  /// Uses the injected clock unless [at] is given. Also writes time_in_recorded_by.
  /// Throws ArgumentError if [at] is in the future.
  /// Throws StateError if the permit is missing, not ACTIVE, or already timed in.
  Future<void> recordTimeIn(
    String adminId,
    String permitId, {
    DateTime? at,
  }) async {
    if (at != null && at.isAfter(clock.now())) {
      throw ArgumentError('Time-in cannot be in the future.');
    }

    final ref = _permits.doc(permitId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        throw StateError('Permit $permitId does not exist');
      }
      final data = snapshot.data()!;
      if (data['permit_status'] != PermitStatus.active.value) {
        throw StateError('Only ACTIVE permits can have a recorded time-in.');
      }
      if (data['actual_time_in'] != null) {
        throw StateError('Permit $permitId already has a recorded time-in.');
      }

      transaction.update(ref, {
        'actual_time_in': toTimestamp(at ?? clock.now()),
        'permit_status': PermitStatus.completed.value,
        'time_in_recorded_by': adminId,
      });
    });
  }

  // ===========================================================================
  // Contract stubs: signatures only. Behavior comes from the issue noted.
  // ===========================================================================

  /// Admin master list, newest first. All permits when [filter] is null.
  /// Implemented in issue #42 (filters in the filter issue).
  Stream<List<PermitModel>> listenToAllPermits({PermitFilter? filter}) =>
      Stream.value(const []);

  /// Admin review queue: PENDING only, oldest first. Issue #43.
  Stream<List<PermitModel>> listenToPendingPermits() => Stream.value(const []);

  /// Owner withdraws a PENDING permit: PENDING -> CANCELLED, in a transaction.
  /// Throws StateError if missing, not owned by [userId], or not PENDING. Issue #43.
  Future<void> cancelPermit(String userId, String permitId) async {
    throw UnimplementedError('cancelPermit');
  }

  /// Owner extends an ACTIVE permit's expected return.
  /// Throws StateError if missing, not owned, not ACTIVE, or
  /// [newExpectedTimeIn] is not after the current one.
  Future<void> extendPermit(
    String userId,
    String permitId,
    DateTime newExpectedTimeIn,
  ) async {
    throw UnimplementedError('extendPermit');
  }

  /// Owner changes the type of a PENDING or ACTIVE permit.
  /// An ACTIVE permit goes back to PENDING for re-approval.
  /// Throws StateError if missing, not owned, or in another status.
  Future<void> changePermitType(
    String userId,
    String permitId,
    PermitType type,
  ) async {
    throw UnimplementedError('changePermitType');
  }

  /// The 12 AM rule: denies every PENDING permit created before today's
  /// 12:00 AM (Asia/Manila) with reason "Not reviewed before 12:00 AM".
  /// Returns how many were denied. Called by the admin dashboard on load.
  Future<int> expireStalePending() async {
    throw UnimplementedError('expireStalePending');
  }
}

// ===========================================================================
  // Contract stubs: signatures only. Behavior comes from the issue noted.
  // ===========================================================================

  /// Admin master list, newest first. All permits when [filter] is null.
  /// Implemented in issue #42 (filters in the filter issue).
  Stream<List<PermitModel>> listenToAllPermits({PermitFilter? filter}) =>
      Stream.value(const []);

  /// Admin review queue: PENDING only, oldest first. Issue #43.
  Stream<List<PermitModel>> listenToPendingPermits() => Stream.value(const []);

  /// Owner withdraws a PENDING permit: PENDING -> CANCELLED, in a transaction.
  /// Throws StateError if missing, not owned by [userId], or not PENDING. Issue #43.
  Future<void> cancelPermit(String userId, String permitId) async {
    throw UnimplementedError('cancelPermit');
  }

  /// Owner extends an ACTIVE permit's expected return.
  /// Throws StateError if missing, not owned, not ACTIVE, or
  /// [newExpectedTimeIn] is not after the current one.
  Future<void> extendPermit(
    String userId,
    String permitId,
    DateTime newExpectedTimeIn,
  ) async {
    throw UnimplementedError('extendPermit');
  }

  /// Owner changes the type of a PENDING or ACTIVE permit.
  /// An ACTIVE permit goes back to PENDING for re-approval.
  /// Throws StateError if missing, not owned, or in another status.
  Future<void> changePermitType(
    String userId,
    String permitId,
    PermitType type,
  ) async {
    throw UnimplementedError('changePermitType');
  }

  /// The 12 AM rule: denies every PENDING permit created before today's
  /// 12:00 AM (Asia/Manila) with reason "Not reviewed before 12:00 AM".
  /// Returns how many were denied. Called by the admin dashboard on load.
  Future<int> expireStalePending() async {
    throw UnimplementedError('expireStalePending');
  }