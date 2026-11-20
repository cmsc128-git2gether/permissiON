import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_app/models/end_user_profile_model.dart';

// fetches end user profiles stored in firestore for read-only services
class EndUserProfileService {
  //optional firestore instance for testing, otherwise use default
  EndUserProfileService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _endUserProfile =>
    _db.collection('end_user_profiles');
  
  // fetch prof doc for userId, returns null if nonexistent
  Future<EndUserProfileModel?> getProfile(String userId) async {
    final doc = await _endUserProfile.doc(userId).get();
    
    if (!doc.exists) {
      return null;
    }

    return EndUserProfileModel.fromFirestore(
      doc.data() ?? const <String, dynamic> {},
      id: doc.id
    );
  }
  
  // deals with real-time changes for userId's profile document
  // null out when the document does not exist.
  Stream<EndUserProfileModel?> listenToProfile(String userId) {
    return _endUserProfile.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }

      return EndUserProfileModel.fromFirestore(
        doc.data() ?? const <String, dynamic>{},
        id: doc.id,
      );
    });
  }
}
