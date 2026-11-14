import 'package:flutter/material.dart';
import 'package:permission_app/models/permit_model.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/services/permit_service.dart';

class PermitDetailScreen extends StatelessWidget {
  const PermitDetailScreen({
    super.key,
    required this.permitId,
    required this.service,   //injected, so tests pass a fake-backed service
  });

  final String permitId;
  final PermitService service;

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permit Details')),
      body: StreamBuilder<PermitModel?>(
        stream: service.listenToPermit(permitId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Could not load permit'));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snap.data;
          if (p == null) return const Center(child: Text('Permit not found'));

          final denied = p.permitStatus == PermitStatus.denied;
          final completed = p.permitStatus == PermitStatus.completed;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(p.permitStatus.value,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text('Type: ${p.permitType.value}'),
              Text('Destination: ${p.destination}'),
              Text('Purpose: ${p.purpose}'),
              Text('Expected back: ${_hhmm(p.expectedTimeIn)}'),
              if (denied && p.disapprovalReason != null)
                Text('Reason: ${p.disapprovalReason}'),
              if (completed && p.actualTimeIn != null)
                Text('Returned at ${_hhmm(p.actualTimeIn!)}'),
            ],
          );
        },
      ),
    );
  }
}
