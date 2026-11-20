import 'package:material_ui/material_ui.dart';
import 'package:permission_app/models/permit_model.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/services/permit_service.dart';
import 'package:permission_app/features/presentation/widgets/status_chip.dart';
import 'package:permission_app/features/presentation/widgets/late_filing_indicator.dart';
import 'package:permission_app/utils/format.dart';
class PermitDetailScreen extends StatelessWidget {
  const PermitDetailScreen({
    super.key,
    required this.permitId,
    required this.service, //injected, so tests pass a fake-backed service
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Room: ${p.roomNum}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),
                  StatusChip(p.permitStatus),
                ],
              ),

              // Show late filing indicator if applicable
              if (p.isLateFiling) ...[
                const SizedBox(height: 12),
                LateFilingIndicator(
                  isLateFiling: p.isLateFiling,
                  time: formatDateTime(p.createdAt),
                  lateFilingReasonText: p.lateFilingReasonOrDefault,
                ),
              ],

              const SizedBox(height: 12),

              // Other permit details
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
