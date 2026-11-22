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
  );

  runApp(MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    routerConfig: router,
  ));
}