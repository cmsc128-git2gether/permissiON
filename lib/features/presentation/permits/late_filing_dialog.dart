import 'package:material_ui/material_ui.dart';

const lateReasonFieldKey = Key('lateReasonField');

/// asks for a reason when filing after the cutoff.
/// pops the trimmed reason, or null if the student cancels.
class LateFilingDialog extends StatefulWidget {
  const LateFilingDialog({super.key});

  @override
  State<LateFilingDialog> createState() => _LateFilingDialogState();
}

class _LateFilingDialogState extends State<LateFilingDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _reason.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Reason is required');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Late filing'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filing after 6:00 PM will be flagged for admin review. '
            'Please explain why you are filing late.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: lateReasonFieldKey,
            controller: _reason,
            maxLength: 200,
            maxLines: 3,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              labelText: 'Reason for late filing',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Submit')),
      ],
    );
  }
}

Future<String?> showLateFilingDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      barrierDismissible: false, //student must choose cancel or submit
      builder: (_) => const LateFilingDialog(),
    );

///call this before submitting a permit.
///if after the cutoff, shows a dialog to ask for a reason.
///if not after the cutoff, just calls onSubmit with null.
///returns true if the permit was submitted, false if the user canceled.
Future<bool> submitWithLateCheck({
  required BuildContext context,
  required DateTime now, // pass clock.now(), never DateTime.now()
  required bool Function(DateTime now) isAfterCutoff,
  required Future<void> Function(String? lateReason) onSubmit,
}) async {
  if (!isAfterCutoff(now)) {
    await onSubmit(null);
    return true;
  }
  final reason = await showLateFilingDialog(context);
  if (reason == null) return false;
  await onSubmit(reason);
  return true;
}