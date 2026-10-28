import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId; // document ID, not stored inside the doc
  final String email;
  final String role; // set server-side (admin SDK), read-only here
  final DateTime? updatedAt;
  final DateTime? deletedAt; // null by default, set on deletion

  const UserModel({
    required this.userId,
    required this.email,
    required this.role,
    this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  factory UserModel.fromJson(Map<String, dynamic> json, {required String id}) {
    final updated = json['updated_at'];
    final deleted = json['deleted_at'];
    return UserModel(
      userId: id,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      updatedAt: updated is Timestamp ? updated.toDate() : null,
      deletedAt: deleted is Timestamp ? deleted.toDate() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'updated_at': FieldValue.serverTimestamp(),
        'deleted_at': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
        // 'role' is intentionally omitted: only the admin SDK sets it.
      };
}