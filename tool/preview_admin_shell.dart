import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:permission_app/features/presentation/admin/admin_shell.dart';

void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/admin/permit-logs',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AdminShell(
            email: 'admin@up.edu.ph',
            onLogout: () {},
            currentPath: state.matchedLocation,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/admin/permit-logs',
              builder: (_, _) => const Center(child: Text('Permit Logs page')),
            ),
          ],
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }
}
