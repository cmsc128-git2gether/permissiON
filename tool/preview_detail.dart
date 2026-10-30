import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_app/features/presentation/permits/permit_detail_screen.dart';
import 'package:permission_app/services/permit_service.dart';

Future<void> main() async {
  final db = FakeFirebaseFirestore();
  final now = DateTime.now();

  Map<String, dynamic> permit(
    String status, {
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
        'expected_time_in': Timestamp.fromDate(now),
        'permit_status': status,
        'disapproval_reason': reason,
        'actual_time_in':
            actualTimeIn == null ? null : Timestamp.fromDate(actualTimeIn),
        'created_at': Timestamp.fromDate(now),
      };

  await db.collection('permits').doc('pending').set(permit('PENDING'));
  await db.collection('permits').doc('active').set(permit('ACTIVE'));
  await db
      .collection('permits')
      .doc('denied')
      .set(permit('DENIED', reason: 'Invalid curfew time.'));
  await db
      .collection('permits')
      .doc('completed')
      .set(permit('COMPLETED', actualTimeIn: now));

  runApp(MaterialApp(
    home: PreviewHost(service: PermitService(firestore: db)),
  ));
}

class PreviewHost extends StatefulWidget {
  const PreviewHost({super.key, required this.service});
  final PermitService service;

  @override
  State<PreviewHost> createState() => _PreviewHostState();
}

class _PreviewHostState extends State<PreviewHost> {
  String id = 'denied';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // State switcher
        Material(
          child: SafeArea(
            bottom: false,
            child: Wrap(
              spacing: 8,
              children: [
                for (final s in ['pending', 'active', 'denied', 'completed'])
                  ChoiceChip(
                    label: Text(s),
                    selected: id == s,
                    onSelected: (_) => setState(() => id = s),
                  ),
                ChoiceChip(
                  label: const Text('missing'),
                  selected: id == 'missing',
                  onSelected: (_) => setState(() => id = 'missing'),
                ),
              ],
            ),
          ),
        ),
        // The real screen under test
        Expanded(
          child: PermitDetailScreen(
            key: ValueKey(id),
            permitId: id,
            service: widget.service,
          ),
        ),
      ],
    );
  }
}

