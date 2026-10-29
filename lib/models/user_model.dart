// user_model.dart
//
// Defines the data model for a user account record, stored in the Firestore
// `users/{user_id}` collection. This file contains:
//   - UserModel: an immutable class representing a single account's core
//     data (email, role, and audit timestamps), with JSON (de)serialization
//     for reading from and writing to Firestore.
//
// Note: the schema lists a `password` field, but it is intentionally NOT
// modeled here. Passwords are handled by Firebase Authentication and should
// never be stored or read as plaintext in Firestore.
//
// Note: `role` is read-only on the client. It is set server-side through
// the Admin SDK, so it is never written back by [UserModel.toJson].

import 'package:cloud_firestore/cloud_firestore.dart';
/// An immutable model of a user account record.
///
/// Holds the account's email, its server-assigned role, and timestamps
/// that track when it was last updated and when it was soft-deleted.
class UserModel {
  /// Unique identifier of the user (the Firestore document ID).
  /// It is not stored inside the document body, it is supplied separately
  /// in [fromJson].
  final String userId;
  /// The account's email address.
  final String email;
  /// The account's role (e.g., admin or end user).
  /// Set server-side through the Admin SDK and read-only on the client.
  final String role;
  /// When the account record was last updated. Null if the timestamp is
  /// missing or hasn't been resolved yet.
  final DateTime? updatedAt;
  /// When the account was soft-deleted. `null` by default, meaning the
  /// account is active. Set upon deletion.
  final DateTime? deletedAt; 
  
  /// Creates a [UserModel].
  ///
  /// [userId], [email], and [role] are required; the timestamps are
  /// optional. The constructor is `const`, so instances can be
  /// compile-time constants.
  const UserModel({
    required this.userId,
    required this.email,
    required this.role,
    this.updatedAt,
    this.deletedAt,
  });
  /// Whether this account has been soft-deleted.
  ///
  /// Returns `true` when [deletedAt] is set, `false` otherwise.
  bool get isDeleted => deletedAt != null;

  /// Builds a [UserModel] from a Firestore document map.
  ///
  /// The [id] is passed separately because it lives outside the document
  /// data. Missing strings fall back to empty strings. Timestamp fields are
  /// checked with `is Timestamp` before converting to [DateTime], so a
  /// missing, null, or wrongly typed value becomes `null` instead of
  /// throwing an error.
  factory UserModel.fromJson(Map<String, dynamic> json, {required String id}) {
    // Raw values are read first so their types can be checked below.
    final updated = json['updated_at'];
    final deleted = json['deleted_at'];
    return UserModel(
      userId: id,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      // Convert Firestore Timestamps to DateTime; anything else becomes null.
      updatedAt: updated is Timestamp ? updated.toDate() : null,
      deletedAt: deleted is Timestamp ? deleted.toDate() : null,
    );
  }
  /// Converts this model into a map for saving to Firestore.
  ///
  /// Uses snake_case keys to match the schema. [userId] is excluded since
  /// it identifies the document rather than being part of its data.
  ///
  /// - `updated_at` uses [FieldValue.serverTimestamp], so Firestore stamps
  ///   the time on the server and the local [updatedAt] value is ignored.
  /// - `deleted_at` is written as a [Timestamp], or `null` if the account
  ///   is not deleted.
  /// - `role` is intentionally omitted, since only the Admin SDK sets it.
  Map<String, dynamic> toJson() => {
        'email': email,
        'updated_at': FieldValue.serverTimestamp(),
        'deleted_at': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
        // 'role' is intentionally omitted: only the admin SDK sets it.
      };
}
