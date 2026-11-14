import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_app/firebase_options.dart';

Map<String, dynamic> _permit({
  required String status,
  String? reason,
  DateTime? actualTimeIn,
}) =>
    {
      'user_id': 'u1',
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

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance
    ..useFirestoreEmulator('127.0.0.1', 8080);

  await db.collection('permits').doc('pending').set(_permit(status: 'PENDING'));
  await db.collection('permits').doc('active').set(_permit(status: 'ACTIVE'));
  await db.collection('permits').doc('denied').set(
      _permit(status: 'DENIED', reason: 'Invalid curfew time.'));
  await db.collection('permits').doc('completed').set(_permit(
      status: 'COMPLETED', actualTimeIn: DateTime.now()));

  debugPrint('Seeded 4 permits: pending, active, denied, completed');
}
