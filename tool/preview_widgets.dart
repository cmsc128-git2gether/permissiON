import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/permits/late_filing_dialog.dart';
import 'package:permission_app/features/presentation/widgets/app_dialog.dart';
import 'package:permission_app/features/presentation/widgets/confirm_dialog.dart';
import 'package:permission_app/features/presentation/widgets/detail_row.dart';
import 'package:permission_app/features/presentation/widgets/loading_state.dart';
import 'package:permission_app/features/presentation/widgets/search_field.dart';
import 'package:permission_app/theme/app_theme.dart';

// Local preview only. No Firebase, no login.
void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  bool admin = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: admin ? AppTheme.admin() : AppTheme.light(),
        home: _Gallery(
          admin: admin,
          onThemeChanged: (v) => setState(() => admin = v),
        ),
      );
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.admin, required this.onThemeChanged});

  final bool admin;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  bool afterSix = true;
  String lateLog = 'Nothing submitted yet';
  String confirmLog = 'No answer yet';
  String searchLog = 'Nothing typed yet';

  Widget section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.sectionHeading),
            const Divider(),
            ...children,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget preview'),
        actions: [
          const Text('Admin'),
          Switch(value: widget.admin, onChanged: widget.onThemeChanged),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ---------------------------------------------------------- DetailRow
          section('DetailRow', const [
            DetailRow('Purpose', 'Study'),
            DetailRow('Destination', 'Puesto, Barangay Sapa, Miagao, Iloilo, lorem ipsum dolor sit amet'),
            DetailRow('Expected Return', '11/11/2026 12:07 PM'),
          ]),

          // --------------------------------------------------------- LoadingState
          section('LoadingState', const [
            SizedBox(height: 100, child: LoadingState()),
          ]),

          // ---------------------------------------------------------- SearchField
          section('SearchField', [
            SearchField(
              hint: 'Type a name or room number to search..',
              onChanged: (v) => setState(() => searchLog = 'Typed: "$v"'),
              onSubmitted: (v) => setState(() => searchLog = 'Submitted: "$v"'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(searchLog),
          ]),

          // ---------------------------------------------------------- AppDialog
          section('AppDialog', [
            ElevatedButton(
              onPressed: () => showAppDialog(
                context,
                title: 'Permit Details',
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailRow('Purpose', 'Study'),
                    DetailRow('Destination', 'SM City'),
                    DetailRow('Expected Return', '11/11/2026 12:07 PM'),
                  ],
                ),
              ),
              child: const Text('Open dialog'),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => showAppDialog(
                context,
                title: 'Long content (scroll check)',
                child: Column(
                  children: [for (var i = 1; i <= 30; i++) DetailRow('Row $i', 'Value $i')],
                ),
              ),
              child: const Text('Open dialog with long content'),
            ),
          ]),

          // ------------------------------------------------------ ConfirmDialog
          section('showConfirmDialog', [
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
              ElevatedButton(
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Submit permit?',
                    message: 'Check your details before sending.',
                    confirmLabel: 'Submit',
                  );
                  setState(() => confirmLog = 'Normal returned: $ok');
                },
                child: const Text('Normal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Cancel permit?',
                    message: 'This cannot be undone.',
                    confirmLabel: 'Yes, cancel',
                    destructive: true,
                  );
                  setState(() => confirmLog = 'Destructive returned: $ok');
                },
                child: const Text('Destructive'),
              ),
            ]),
            const SizedBox(height: AppSpacing.sm),
            const Text('Also try tapping outside the dialog (should return false).'),
            Text(confirmLog),
          ]),

          // ------------------------------------------------- Late filing dialog
          section('Late filing dialog', [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pretend it is after 6 PM'),
              value: afterSix,
              onChanged: (v) => setState(() => afterSix = v),
            ),
            ElevatedButton(
              onPressed: () => submitWithLateCheck(
                context: context,
                now: DateTime(2026, 11, 10, afterSix ? 19 : 12),
                isAfterCutoff: (t) => t.hour >= 18,
                onSubmit: (reason) async => setState(
                  () => lateLog = reason == null
                      ? 'Submitted on time (no reason)'
                      : 'Submitted late, reason: "$reason"',
                ),
              ),
              child: const Text('File permit'),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('Try: empty reason, spaces only, Cancel, then a real reason.'),
            Text(lateLog),
          ]),
        ],
      ),
    );
  }
}