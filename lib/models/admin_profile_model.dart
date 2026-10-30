//admin_profile_model.dart
//
//This file defines the data class AdminProfileModel for the `admin_profiles/{user_id}` collection path. 
//This file contains the following:
// - AdminPosition, an enum of the positions an admin can hold, each with label that is also a string stored in Firestore. 
// - AdminProfileModel, an immutable class representing a single admin's profile, with JSON deserialization, and JSON 
//   serialization for reading from, and writing to Firestore.

/// The positions an admin can hold within the dormitory.
///
/// Each value carries a display [label] that is also the string stored in
/// Firestore under the `position` field.
enum AdminPosition {
  //Each enum value is paired with its label
  dormManager('Dorm Manager'),
  dormStaff('Dorm Staff'),
  residentHallAssistant('Resident Hall Assistant');
  //The name shown in the UI, and saved to Firestore.
  final String label;
  //Constant constructor that assigns the [label] to each enum value. 
  const AdminPosition(this.label);
  ///Converts a stored label string back to an [AdminPosition].
  ///
  ///It loops through every enum value then returns the one whose [label] matches
  ///the [value]. It will return `null` if [value] is null or does not match any known
  ///position, which prevents crashing the app if there is an unknown or missing data. 
  static AdminPosition? fromLabel(String? value) {
    for (final p in AdminPosition.values) {
      if (p.label == value) return p;
    }
    return null;
  }
}
///An immutable model of an admin's profile
///
///This class holds the admin's name, an optional display photo, their position,
///and whether they are currently on duty. 
class AdminProfileModel {
  ///Unique identifier of the admin, it is supplied separately in [fromJson]
  final String userId;
  ///The admin's family name
  final String surname;
  ///The admin's first/given name
  final String givenName;
  ///The URL or path of the admin's display photo. Null if none is set.
  final String? displayPhoto;
  ///The admin's position. Null if not set or unrecognized. 
  final AdminPosition? position;
  ///Whether the admin is currently on duty. This would default to `false`. 
  final bool onDuty;
  ///Creates an [AdminProfileModel]
  ///
  ///[userId], [surname], [givenName] are required while the photo and position are optional, 
  ///as for the [onDuty], it will default to `false`. 
  ///The constructor is `const` so that instances can be compile-time constants. 
  const AdminProfileModel({
    required this.userId,
    required this.surname,
    required this.givenName,
    this.displayPhoto,
    this.position,
    this.onDuty = false,
  });
  ///Builds an [AdminProfileModel] from a Firestore document map.
  ///
  /// The [id] is passed separately because it lives outside the document
  /// data. Missing or null fields fall back to safe defaults, empty strings
  /// for names, `null` for photo/position, and `false` for [onDuty]. The
  /// position string is converted using [AdminPosition.fromLabel].
  factory AdminProfileModel.fromJson(Map<String, dynamic> json,
          {required String id}) =>
      AdminProfileModel(
        userId: id,
        surname: json['surname'] as String? ?? '',
        givenName: json['given_name'] as String? ?? '',
        displayPhoto: json['display_photo'] as String?,
        position: AdminPosition.fromLabel(json['position'] as String?),
        onDuty: json['on_duty'] as bool? ?? false,
      );
  /// Converts this model into a map for saving to Firestore.
  ///
  /// Uses snake_case keys to match the schema. The position is stored as
  /// its [AdminPosition.label] string (or `null` if unset). [userId] is
  /// excluded since it identifies the document rather than being part of
  /// its data.
  Map<String, dynamic> toJson() => {
        'surname': surname,
        'given_name': givenName,
        'display_photo': displayPhoto,
        'position': position?.label,
        'on_duty': onDuty,
      };
}
