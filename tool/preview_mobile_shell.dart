import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/dormer_dashboard.dart';
import 'package:permission_app/router/app_router.dart'; // only app_router, not router itself
import 'package:permission_app/services/permit_service.dart';
import 'package:permission_app/theme/app_theme.dart';

// Local preview only. No Firebase, no login, no emulator.
// Shows the real StudentHomeScreen inside the bottom-tab shell, filled with
// the same user and permit data that seed_emulator.dart writes to the
// Firestore emulator (permit IDs are random here).
import 'package:permission_app/features/presentation/permits/permit_request.dart';
import 'package:permission_app/features/presentation/permits/permit_wizard_screen.dart';



// Same user as seed_emulator.dart.
const _userId = 'u1';
const _displayName = 'Test Name';

// Same shape as `_permit` in seed_emulator.dart.
Map<String, dynamic> _permit({
  required String status,
  String? reason,
  DateTime? actualTimeIn,
}) =>
    {
      'user_id': _userId,
      'full_name': 'Test Name',
      'room_num': '131',
      'permit_type': 'LATE',
      'destination': 'Bangs',
      'purpose': 'study',
      'emergency_contact_person': 'Contact',
      'emergency_contact_num': '0000000000',
      'expected_time_in': Timestamp.fromDate(DateTime.now()),
      'permit_status': status,
      'disapproval_reason': reason,
      'actual_time_in':
          actualTimeIn == null ? null : Timestamp.fromDate(actualTimeIn),
      'created_at': Timestamp.fromDate(DateTime.now()),
    };
/// Fake database holding the same 4 permits as seed_emulator.dart
/// (pending, active, denied, completed), with auto-generated IDs.
Future<FakeFirebaseFirestore> _seededDb() async {
  final db = FakeFirebaseFirestore();
  final permits = db.collection('permits');
  await permits.add(_permit(status: 'PENDING'));
  await permits.add(_permit(status: 'ACTIVE'));
  await permits.add(_permit(status: 'DENIED', reason: 'Invalid curfew time.'));
  await permits.add(
    _permit(status: 'COMPLETED', actualTimeIn: DateTime.now()));

  return db;
}

Future<void> main() async {
  final db = await _seededDb();


  final router = createRouter(
    homeBuilder: (_) => StudentHomeScreen(
      service: PermitService(firestore: db),
      userId: _userId,
      displayName: _displayName,
    ),
    newPermitBuilder: (_) => PermitWizardScreen(
      userId: _userId,
      loadFiler: () async => const PermitFiler(
        surname: 'Name', givenName: 'Test', roomNum: '131', floor: 1),
    createPermit: (request, {lateReason}) async {
      await db.collection('permits').add({
        'user_id': request.userId,
        'surname': request.filer.surname,
        'given_name': request.filer.givenName,
        'room_num': request.filer.roomNum,
        'permit_type': request.type.name.toUpperCase(),
        'destination': request.destination,
        'purpose': request.purpose,
        'emergency_contact_person': request.contactPerson,
        'emergency_contact_num': request.contactNumber,
        'expected_time_in': Timestamp.fromDate(request.expectedReturnUtc),
        'permit_status': 'PENDING',
        'disapproval_reason': null,
        'actual_time_in': null,
        'created_at': Timestamp.now(),
        });
        },
      ),
    );
  runApp(MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    routerConfig: router,
  ));
}


