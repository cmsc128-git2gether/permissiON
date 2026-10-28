import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/permit_model.dart';
import '../domain/user_model.dart';

// When an admin action can't be applied to a permit
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

  // Approves a PENDING permit: 
  //status -> ACTIVE, stamps approved_by/approved_at
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

  // Disapproves a PENDING permit: 
  //status -> DISAPPROVED, stamps approved_by/approved_at
  Future<void> disapprovePermit({
    required String permitId,
    required AppUser admin,
  }) {
    return _decide(
      permitId: permitId,
      admin: admin,
      newStatus: PermitStatus.disapproved,
    );
  }

  // Shared update for permit status
  Future<void> _decide({ required String permitId, required AppUser admin, required String newStatus }) async {

    // User restriction
    if (!admin.isAdmin) {
      throw PermitActionException('Only admins can approve or disapprove permits.');
    }

    final ref = PermitModel.collection.doc(permitId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      final permit = snap.data();

      if (permit == null) {
        throw PermitActionException('Permit not found.');
      }
      if (permit.permitStatus != PermitStatus.pending) {
        throw PermitActionException(
          'Permit is already ${permit.permitStatus}; only PENDING permits can be modified.',
        );
      }

      transaction.update(ref, {
        'permit_status': newStatus,
        'approved_by': admin.uid,
        'approved_at': FieldValue.serverTimestamp(),
      });
    });
  }
}