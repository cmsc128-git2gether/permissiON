// end_user_profile_model.dart
//
// Defines the data model for an end user's (resident's) profile, stored in
// the Firestore `end_user_profiles/{user_id}` collection. This file
// contains:
//   - EndUserProfileModel: an immutable class representing a single
//     resident's profile, with JSON (de)serialization for reading from and
//     writing to Firestore.
//
// Note: account data such as email, role, and timestamps lives in
// UserModel (the `users` collection), not here. Both share the same
// document ID (user_id).

/// An immutable model of an end user's profile.
///
/// Holds the resident's name, an optional display photo, and their contact
/// and room details.
class EndUserProfileModel {
  /// Unique identifier of the user (the Firestore document ID, matching
  /// the `users/{user_id}` record). It is not part of the document body;
  /// it is supplied separately in [fromJson].
  final String userId;
  /// The user's family name.
  final String surname;
  /// The user's first/given name.
  final String givenName;
  /// URL or path of the user's display photo. Null if none is set.
  final String? displayPhoto;
  /// The user's contact phone number. Empty string if none is stored.
  final String phoneNum;
  /// The user's assigned room number. Empty string if none is stored.
  final String roomNum;

  // No delinquency_count, permit_history, or active_permits:
  // those are queried from the delinquency logs and permits collections.

  // No delinquency_count, permit_history, or active_permits:
  // those are queried from the delinquency logs and permits collections.
  // Hardcoding them here would risk stale or duplicated data.

  /// Creates an [EndUserProfileModel].
  ///
  /// [userId], [surname], [givenName], [phoneNum], and [roomNum] are
  /// required; only [displayPhoto] is optional. The constructor is `const`,
  /// so instances can be compile-time constants.
  const EndUserProfileModel({
    required this.userId,
    required this.surname,
    required this.givenName,
    this.displayPhoto,
    required this.phoneNum,
    required this.roomNum,
  });

  /// Builds an [EndUserProfileModel] from a Firestore document map.
  ///
  /// The [id] is passed separately because it lives outside the document
  /// data. Missing or null fields fall back to safe defaults: empty strings
  /// for names, phone number, and room number, and `null` for the photo.
  factory EndUserProfileModel.fromJson(Map<String, dynamic> json,
          {required String id}) =>
      EndUserProfileModel(
        userId: id,
        surname: json['surname'] as String? ?? '',
        givenName: json['given_name'] as String? ?? '',
        displayPhoto: json['display_photo'] as String?,
        phoneNum: json['phone_num'] as String? ?? '',
        roomNum: json['room_num'] as String? ?? '',
      );

  /// Converts this model into a map for saving to Firestore.
  ///
  /// Uses snake_case keys to match the schema. [userId] is excluded since
  /// it identifies the document rather than being part of its data.
  Map<String, dynamic> toJson() => {
        'surname': surname,
        'given_name': givenName,
        'display_photo': displayPhoto,
        'phone_num': phoneNum,
        'room_num': roomNum,
      };
}
