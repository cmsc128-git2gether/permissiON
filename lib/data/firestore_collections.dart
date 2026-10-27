import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_profile_model.dart';
import '../models/end_user_profile_model.dart';
import '../models/user_model.dart';

class Collections {
  Collections._(); // not meant to be instantiated

  static final _db = FirebaseFirestore.instance;

  static final CollectionReference<UserModel> users =
      _db.collection('users').withConverter<UserModel>(
            fromFirestore: (snap, _) =>
                UserModel.fromJson(snap.data() ?? {}, id: snap.id),
            toFirestore: (model, _) => model.toJson(),
          );

  static final CollectionReference<AdminProfileModel> adminProfiles =
      _db.collection('admin_profiles').withConverter<AdminProfileModel>(
            fromFirestore: (snap, _) =>
                AdminProfileModel.fromJson(snap.data() ?? {}, id: snap.id),
            toFirestore: (model, _) => model.toJson(),
          );

  static final CollectionReference<EndUserProfileModel> endUserProfiles =
      _db.collection('end_user_profiles').withConverter<EndUserProfileModel>(
            fromFirestore: (snap, _) =>
                EndUserProfileModel.fromJson(snap.data() ?? {}, id: snap.id),
            toFirestore: (model, _) => model.toJson(),
          );
}