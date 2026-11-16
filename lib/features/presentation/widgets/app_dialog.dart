import 'package:material_ui/material_ui.dart';
import 'package:permission_app/theme/app_theme.dart';

///title, X button and divider. Width is capped so it looks right on web and phones.
class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.title, required this.child, this.maxWidth = 560});

  final String title;
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ]),
                const Divider(height: AppSpacing.lg),
                Flexible(child: SingleChildScrollView(child: child)),
              ],
            ),
          ),
        ),
      );
}

Future<T?> showAppDialog<T>(BuildContext context,
        {required String title, required Widget child}) =>
    showDialog<T>(context: context, builder: (_) => AppDialog(title: title, child: child));