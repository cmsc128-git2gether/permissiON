// firestore_collections.dart
//
// Central registry of typed Firestore collection references for the app.
// This file contains:
//   - Collections: a static-only class exposing one [CollectionReference]
//     per collection (`users`, `admin_profiles`, `end_user_profiles`).
//
// Each reference uses `withConverter`, so reads return model objects
// (e.g., [UserModel]) instead of raw maps, and writes accept models
// directly. This keeps the JSON conversion logic in the model classes and
// keeps collection names in one place instead of scattered string literals.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_profile_model.dart';
import '../models/end_user_profile_model.dart';
import '../models/user_model.dart';

/// Typed access points to the app's Firestore collections.
///
/// Use these references instead of calling `FirebaseFirestore.instance`
/// directly, e.g. `Collections.users.doc(uid).get()` returns a
/// `DocumentSnapshot<UserModel>`.
class Collections {
  /// Private constructor so the class can't be instantiated; it only
  /// serves as a namespace for the static members below.
  Collections._(); 

  /// Shared Firestore instance used by every collection reference.
  static final _db = FirebaseFirestore.instance;

  /// The `users/{user_id}` collection, typed as [UserModel].
  ///
  /// `fromFirestore` builds a [UserModel] from the document data and its
  /// ID (using an empty map if the document has no data). `toFirestore`
  /// converts a [UserModel] back into a map for saving.
  static final CollectionReference<UserModel> users =
      _db.collection('users').withConverter<UserModel>(
            fromFirestore: (snap, _) =>
                UserModel.fromJson(snap.data() ?? {}, id: snap.id),
            toFirestore: (model, _) => model.toJson(),
          );

  /// The `admin_profiles/{user_id}` collection, typed as
  /// [AdminProfileModel].
  ///
  /// Converters work the same way as for [users].
  static final CollectionReference<AdminProfileModel> adminProfiles =
      _db.collection('admin_profiles').withConverter<AdminProfileModel>(
            fromFirestore: (snap, _) =>
                AdminProfileModel.fromJson(snap.data() ?? {}, id: snap.id),
            toFirestore: (model, _) => model.toJson(),
          );

  /// The `end_user_profiles/{user_id}` collection, typed as
  /// [EndUserProfileModel].
  ///
  /// Converters work the same way as for [users].
  static final CollectionReference<EndUserProfileModel> endUserProfiles =
      _db.collection('end_user_profiles').withConverter<EndUserProfileModel>(
            fromFirestore: (snap, _) =>
                EndUserProfileModel.fromJson(snap.data() ?? {}, id: snap.id),
            toFirestore: (model, _) => model.toJson(),
          );
}
