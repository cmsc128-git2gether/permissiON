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
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_reason.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Late filing'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filing after 6:00 PM will be flagged for admin review. '
              'Please input a reason why you are filing late here.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: lateReasonFieldKey,
              controller: _reason,
              maxLength: 200,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'Reason for late filing'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Reason is required!' : null,
            ),
          ],
        ),
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