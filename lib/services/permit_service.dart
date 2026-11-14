import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clock/clock.dart'; // injects clock
import '../models/data_enums.dart';
import '../models/permit_model.dart';
import '../utils/firestore_utils.dart';
// import '../models/qr_model.dart';

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


  //admin history of all pending permits to be implemented in issue #43, for now returns empty list
  Stream<List<PermitModel>> listenToPendingPermits() => Stream.value(const []);

  //user cancels a pending permit to be implemented in issue #43, for now throws unimplemented error
  Future<void> cancelPermit(String userId, String permitId) async {
    throw UnimplementedError('cancelPermit');
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

///new permit is created with status PENDING, and other fields are null. returns the new permit's id
  Future<String> createPermit(PermitModel permit) async {
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

  ///real-time stream of all permits for a given user,
  Stream<List<PermitModel>> listenToUserPermits(String userId) {
    return _permits
         //newest first
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        //convert each snapshot to PermitModel obj
        .map((snap) => snap.docs.map((doc) => PermitModel.fromFirestore(doc, null)).toList());
  }

  ///admin-only (enforced by security rules). is run in transactions
  Future<void> updatePermitStatus(
    String adminId,
    String permitId,
    String status, {
    String? disapprovalReason,
  }) {

    //------------- failure messages --------------------
    //fail fast

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
    if (status != PermitStatus.active.value && status != PermitStatus.denied.value) {
      throw ArgumentError(
          'status must be either active or denied when updating a permit');
    }

    final ref = _permits.doc(permitId);

    //----------------- transaction from snapshot --------------------
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

    //failure/guard messages
      if (!snapshot.exists) {
        throw StateError('Permit $permitId does not exist');
      }

      if (snapshot.data()!['permit_status'] != PermitStatus.pending.value) {
        throw StateError('Only PENDING permits can be reviewed');
      }

      //write
      transaction.update(ref, {
        'permit_status': status,
        'approved_by': adminId,
        'approved_at': FieldValue.serverTimestamp(),
        'disapproval_reason':
            status.toUpperCase() == PermitStatus.denied.value.toUpperCase()?
            disapprovalReason : null,
      });
    });
  }
}