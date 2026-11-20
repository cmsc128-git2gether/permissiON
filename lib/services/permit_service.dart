import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clock/clock.dart'; // injects clock
import '../models/data_enums.dart';
import '../models/permit_model.dart';
import '../utils/firestore_utils.dart';
import 'permit_filter.dart';

class PermitService {
  //optional firestore instance for testing, otherwise use default
  //optional random for testing (deterministic codes), otherwise Random.secure()
  PermitService({FirebaseFirestore? firestore, Random? random})
      : _db = firestore ?? FirebaseFirestore.instance,
        _random = random ?? Random.secure();

  final FirebaseFirestore _db;
  final Random _random;

  /// How long a generated check-in code stays valid.
  static const checkinCodeLifetime = Duration(minutes: 5);

  //helper shortcut to 'permits/' collection
  CollectionReference<Map<String, dynamic>> get _permits =>
      _db.collection('permits');

  //helper shortcut to 'checkin_codes/' collection (doc id == permit id)
  CollectionReference<Map<String, dynamic>> get _checkinCodes =>
      _db.collection('checkin_codes');

  /// 6 PM filing cutoff (AS5). Pure, so the UI can warn before submitting.
  /// Works on any device timezone: converts to UTC, then adds 8 hours (Manila).
  static bool isAfterFilingCutoff(DateTime now) {
    final manilaTime = now.toUtc().add(const Duration(hours: 8));
    return manilaTime.hour >= 18;
  }

  /// New permit is saved as PENDING with empty review fields. Returns the new id.
  /// After the 6 PM cutoff a [lateReason] is required (trimmed, max 200 chars)
  /// and the permit is flagged with is_late_filing.
  Future<String> createPermit(PermitModel permit, {String? lateReason}) async {
    final now = clock.now();
    final isLate = isAfterFilingCutoff(now);

    bool flag = false;
    String? storedReason;

    if (isLate) {
      final trimmedReason = lateReason?.trim();
      if (trimmedReason == null || trimmedReason.isEmpty) {
        throw ArgumentError('Late filing requires a reason.');
      }
      flag = true;
      // Enforce the 200 character limit
      storedReason = trimmedReason.length > 200
          ? trimmedReason.substring(0, 200)
          : trimmedReason;
    }

    // 1. Get the base map from the model
    final data = permit.toFirestore()
      // 2. Override with the required createPermit defaults
      ..['permit_status'] = PermitStatus.pending.value
      ..['actual_time_in'] = null
      ..['disapproval_reason'] = null
      ..['approved_by'] = null
      ..['approved_at'] = null
      ..['qr_id'] = null
      ..['created_at'] = FieldValue.serverTimestamp()
      // 3. Late filing fields
      ..['is_late_filing'] = flag
      ..['late_filing_reason'] = storedReason;

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
      throw ArgumentError(
          'disapprovalReason cannot be empty when denying a permit');
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
  /// Issue #44.
  Future<void> recordTimeIn(
    String adminId,
    String permitId, {
    DateTime? at,
  }) async {
    // validates time is not future
    if (at != null && at.isAfter(clock.now())) {
      throw ArgumentError('Time-in cannot be in the future.');
    }

    final ref = _permits.doc(permitId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      // missing permit
      if (!snapshot.exists) {
        throw StateError('Permit $permitId does not exist');
      }
      final data = snapshot.data()!;
      // non-ACTIVE permit
      if (data['permit_status'] != PermitStatus.active.value) {
        throw StateError('Only ACTIVE permits can have a recorded time-in.');
      }
      // already has a time-in
      if (data['actual_time_in'] != null) {
        throw StateError('Permit $permitId already has a recorded time-in.');
      }

      transaction.update(ref, {
        // injected clock.now() instead of server timestamp
        'actual_time_in': toTimestamp(at ?? clock.now()),
        'permit_status': PermitStatus.completed.value,
        'time_in_recorded_by': adminId,
      });
    });
  }

  /// Admin generates a 6-digit check-in code for a permit and returns it.
  /// Writes checkin_codes/{permitId}, replacing any older code.
  /// Throws StateError if the permit is missing, not ACTIVE/OVERDUE, or
  /// already has an actual_time_in.
  Future<String> generateCheckinCode(String adminId, String permitId) async {
    final permitRef = _permits.doc(permitId);
    final codeRef = _checkinCodes.doc(permitId);
    final code = _random.nextInt(1000000).toString().padLeft(6, '0');

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(permitRef);

      if (!snapshot.exists) {
        throw StateError('Permit $permitId does not exist');
      }
      final data = snapshot.data()!;
      final status = data['permit_status'];
      if (status != PermitStatus.active.value &&
          status != PermitStatus.overdue.value) {
        throw StateError(
            'A check-in code can only be generated for ACTIVE or OVERDUE permits.');
      }
      if (data['actual_time_in'] != null) {
        throw StateError('Permit $permitId already has a recorded time-in.');
      }

      transaction.set(codeRef, {
        'code': code,
        'expires_at': Timestamp.fromDate(clock.now().add(checkinCodeLifetime)),
        'created_by': adminId,
      });
    });

    return code;
  }

  /// Student submits the code shown on the admin's screen. Marks the permit
  /// COMPLETED and stores the submitted code. The security rules check the
  /// code, expiry, ownership and status.
  ///
  /// Any permission-denied error becomes StateError('Wrong or expired code'),
  /// since Firestore does not say why a write was refused.
  ///
  /// Risk: a script could guess the 6 digits within the 5-minute window.
  Future<void> submitCheckinCode(
    String userId,
    String permitId,
    String code,
  ) async {
    try {
      await _permits.doc(permitId).update({
        'permit_status': PermitStatus.completed.value,
        'actual_time_in': FieldValue.serverTimestamp(),
        'checkin_code_submitted': code,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw StateError('Wrong or expired code');
      }
      rethrow;
    }
  }

  /// Admin master list, newest first. All permits when [filter] is null.
  /// Implemented in issue #42 (filters in the filter issue).
  Stream<List<PermitModel>> listenToAllPermits({PermitFilter? filter, int limit = 200}) {
    // issue #79: apply filter (status, type, date created, etc.)
    var query = _permits
        .orderBy('created_at', descending: true)
        .limit(limit);

    return query.snapshots().map((snap) =>
      snap.docs.map((d) => PermitModel.fromFirestore(d, null)).toList());
  }

  /// Admin review queue: PENDING only, oldest first. Issue #43.
  Stream<List<PermitModel>> listenToPendingPermits({int? limit}) {
    var query = _permits
        .where('permit_status', isEqualTo: PermitStatus.pending.value)
        .orderBy('created_at'); // oldest requests first
    if (limit != null) query = query.limit(limit);

    return query.snapshots().map((snap) =>
        snap.docs.map((d) => PermitModel.fromFirestore(d, null)).toList());
  }

  /// Owner withdraws a PENDING or ACTIVE permit -> CANCELLED, in a transaction.
  /// Throws StateError if missing, not owned by [userId], or not PENDING/ACTIVE.
  /// Issue #43.
  Future<void> cancelPermit(String userId, String permitId) async {
    final ref = _permits.doc(permitId);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        throw StateError('Permit $permitId does not exist');
      }

      final data = snapshot.data()!;
      if (data['user_id'] != userId) {
        throw StateError('Permit $permitId does not belong to user $userId');
      }

      final status = data['permit_status'];
      if (status != PermitStatus.pending.value &&
          status != PermitStatus.active.value) {
        throw StateError('Only PENDING or ACTIVE permits can be cancelled.');
      }

      transaction.update(ref, {
        'permit_status': PermitStatus.cancelled.value,
      });
    });
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
