import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data_enums.dart';
import '../models/permit_model.dart';

class PermitService {


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