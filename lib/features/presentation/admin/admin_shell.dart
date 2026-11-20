import 'package:material_ui/material_ui.dart';
import 'package:permission_app/theme/app_theme.dart'; // AppTheme, AppColors, Breakpoints
import 'admin_sidebar.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.child,
    required this.email,
    required this.onLogout,
    required this.currentPath,
  });

  final Widget child;
  final String email;
  final VoidCallback onLogout;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.admin(),
      child: Builder(
        builder: (context) {
          final sidebar = AdminSidebar(
            email: email,
            onLogout: onLogout,
            currentPath: currentPath,
          );
          final content = ColoredBox(color: AppColors.pageBg, child: child);

          if (Breakpoints.isWide(context)) {
            return Scaffold(
              body: Row(
                children: [
                  sidebar,
                  Expanded(child: content),
                ],
              ),
            );
          }
          return Scaffold(
            appBar: AppBar(),
            drawer: Drawer(child: sidebar),
            body: content,
          );
        },
      ),
    );
  }
}
