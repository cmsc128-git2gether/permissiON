import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/permits/late_filing_dialog.dart';

void main() => runApp(const MaterialApp(home: _Preview()));

class _Preview extends StatefulWidget {
  const _Preview();
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  bool afterSix = true;
  String log = 'Nothing submitted yet';

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SwitchListTile(
              title: const Text('Pretend it is after 6 PM'),
              value: afterSix,
              onChanged: (v) => setState(() => afterSix = v),
            ),
            ElevatedButton(
              onPressed: () => submitWithLateCheck(
                context: context,
                now: DateTime(2026, 11, 10, afterSix ? 19 : 12),
                isAfterCutoff: (t) => t.hour >= 18,
                onSubmit: (r) async =>
                    setState(() => log = 'Submitted, reason: $r'),
              ),
              child: const Text('File permit'),
            ),
            Text(log),
          ]),
        ),
      );
}