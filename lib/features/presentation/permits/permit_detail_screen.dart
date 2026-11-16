import 'package:material_ui/material_ui.dart';
import 'package:permission_app/models/permit_model.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/services/permit_service.dart';

class PermitDetailScreen extends StatelessWidget {
  const PermitDetailScreen({
    super.key,
    required this.permitId,
    required this.service,   //injected, so tests pass a fake-backed service
    this.isAdmin = false, //only admin see the record time-in option
  });

  final String permitId;
  final PermitService service;
  final bool isAdmin;

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  ///Opens the confirmation dialog, then calls the recordTimeIn if confirmed.
  Future<void> _recordTimeIn(BuildContext context, PermitModel p) async {
    final choice = await showDialog<TimeInChoice>(
      context: context,
      builder: (_) => const RecordTimeInDialog(),
    );
    if (choice == null) return; //canceled

    String? error;
    try {
      await service.recordTimeIn(p.id, at: choice.at);
    } on ArgumentError catch (e) {
      error = '${e.message}'; //ex. time-in in the future
    }on StateError catch (e) {
      error = e.message; //permit not active, or already timed in
    }
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
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
          final canRecordTimeIn = isAdmin && p.permitStatus == PermitStatus.active;


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
              if (canRecordTimeIn) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const Key('record_time_in_button'),
                  onPressed: () => _recordTimeIn(context, p),
                  child: const Text('Record time-in'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
///What the dialog returns when the admin confirms.
///[at] is null when the admin did not adjust the time or use the current time
class TimeInChoice {
  const TimeInChoice(this.at);
  final DateTime? at;
}

///This is the confirmation dialog  for recording a permit's time in
///Pops a [TimeInChoice] on Confirm or null on Cancel
class RecordTimeInDialog extends StatefulWidget {
  const RecordTimeInDialog({super.key});

  @override
  State<RecordTimeInDialog> createState() => _RecordTimeInDialogState();
}

class _RecordTimeInDialogState extends State<RecordTimeInDialog> {
  DateTime ? _adjusted; // null = record as "now"
  //admin sees the problem before confirming, as it mirrors the service rule
  bool get _isFuture => _adjusted != null && _adjusted!.isAfter(clock.now());

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_adjusted ?? clock.now()),
    );
    if (picked == null || !mounted) return;
    // the picker gives only a time, so we combine it with today's date
    final today = clock.now().date;
    setState(() {
      _adjusted = DateTime(today.year, today.month, today.day, picked.hour, picked.minute);
    });
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record time-in'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_adjusted == null
              ? 'Record this permit as returned now?'
              : 'Record this permit as returned at '
                  '${PermitDetailScreen._hhmm(_adjusted!)}?'),
          if (_isFuture)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Time-in cannot be in the future.',
                key: const Key('future_time_error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                key: const Key('adjust_time_button'),
                onPressed: _pickTime,
                child: Text(_adjusted == null ? 'Adjust time' : 'Change time'),
              ),
              if (_adjusted != null)
                TextButton(
                  key: const Key('reset_time_button'),
                  onPressed: () => setState(() => _adjusted = null),
                  child: const Text('Use current time'),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('confirm_time_in_button'),
          onPressed:
              _isFuture ? null : () => Navigator.pop(context, TimeInChoice(_adjusted)),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}