import 'package:flutter/material.dart';

class LateFilingForm extends StatefulWidget {
  const LateFilingForm({
    super.key,
    required this.isAfterCutoff,
    required this.now,
    required this.onSubmit,
  });

  final bool Function(DateTime now) isAfterCutoff; //injected rule
  final DateTime Function() now;                   //injected clock
  final void Function(String? lateReason) onSubmit; //null when on time

  @override
  State<LateFilingForm> createState() => _LateFilingFormState();
}

class _LateFilingFormState extends State<LateFilingForm> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final late = widget.isAfterCutoff(widget.now());
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (late) ...[
            const Text('Filing after 6:00 PM will be flagged for admin review.'),
            TextFormField(
              controller: _reason,
              decoration: const InputDecoration(labelText: 'Reason for late filing'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Reason is required' : null,
            ),
          ],
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSubmit(late ? _reason.text.trim() : null);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}