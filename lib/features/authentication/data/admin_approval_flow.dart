import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_app/models/data_enums.dart';
import '../../../models/permit_model.dart';
import '../domain/user_model.dart';

// Thrown when an admin action can't be applied to a permit
class PermitActionException implements Exception {
  final String message;
  PermitActionException(this.message);

  @override
  String toString() => message;
}

// Admin-side logic for acting on permits at permits/{permit_id}
class PermitAdminService {
  PermitAdminService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Approves a PENDING permit
  // status -> ACTIVE, stamps approved_by/approved_at
  Future<void> approvePermit({
    required String permitId,
    required AppUser admin,
  }) {
    return _decide(
      permitId: permitId,
      admin: admin,
      newStatus: PermitStatus.active,
    );
  }

  // Denies a PENDING permit
  // status -> DENIED, stamps approved_by/approved_at
  Future<void> denyPermit({
    required String permitId,
    required AppUser admin,
  }) {
    return _decide(
      permitId: permitId,
      admin: admin,
      newStatus: PermitStatus.denied,
    );
  }

  // Shared update; the transaction ensures two admins can't both act on one permit
  Future<void> _decide({
    required String permitId,
    required AppUser admin,
    required PermitStatus newStatus, 
  }) async {
    if (!admin.isAdmin) {
      throw PermitActionException('Only admins can approve or deny permits.');
    }

    final ref = PermitModel.collectionOf(_db).doc(permitId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      final permit = snap.data();

      if (permit == null) {
        throw PermitActionException('Permit not found.');
      }
      if (permit.permitStatus != PermitStatus.pending) {
        throw PermitActionException(
          'Permit is already ${permit.permitStatus.value}; only PENDING permits can be acted on.',
        );
      }

      transaction.update(ref, {
        'permit_status': newStatus.value,
        'approved_by': admin.uid,
        'approved_at': FieldValue.serverTimestamp(),
      });
    });
  }
}