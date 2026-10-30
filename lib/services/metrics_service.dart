import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data_enums.dart';
import '../models/permit_model.dart';

//reads metrics about permits and delinquency logs. Does not write anything.
class MetricsService {
  MetricsService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _permits =>
      _db.collection('permits');
  CollectionReference<Map<String, dynamic>> get _delinquencyLogs =>
      _db.collection('delinquency_logs');

  //number of active permits for this user: only counts permits with status ACTIVE.
  Future<int> countActivePermits(String userId) async {
    final snap = await _permits
        .where('user_id', isEqualTo: userId)
        .where('permit_status', isEqualTo: PermitStatus.active.value)
        .count()
        .get();
    return snap.count ?? 0;
  }

  //deliniquencies are logged in a separate collection, 
  //so we can count them without reading all the permits.
  Future<int> countDelinquencies(String userId) async {
    final snap = await _delinquencyLogs
        .where('user_id', isEqualTo: userId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  //lists of a user's permits, newest first. Can limit the number of results.
  Stream<List<PermitModel>> listenToPermitHistory(String userId, {int? limit}) {
    var query = _permits
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true);
    if (limit != null) query = query.limit(limit);

    return query.snapshots().map((snap) =>
        snap.docs.map((d) => PermitModel.fromFirestore(d, null)).toList());
  }
}