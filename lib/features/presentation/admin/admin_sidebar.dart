import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.email,
    required this.onLogout,
    required this.currentPath,
  });

  final String email;
  final VoidCallback onLogout;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFDDDDDD))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/logo_ver1.png',
                height: 80,
                alignment: Alignment.centerLeft,
              ),
              const Text('Admin', style: TextStyle(fontSize: 11)),
              const Divider(height: 24),
              _SidebarItem(
                label: 'Permit Logs',
                selected: currentPath.startsWith('/admin/permit-logs'),
                onTap: () => context.go('/admin/permit-logs'),
              ),
              const _SidebarItem(label: 'Delinquency Tracker', enabled: false),
              const _SidebarItem(label: 'Room Check', enabled: false),
              const Spacer(),
              Text(
                'Signed in as $email',
                style: const TextStyle(
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onLogout,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    this.onTap,
    this.enabled = true,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? scheme.primary : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onTap : null, // disabled items never navigate
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? scheme.onPrimary
                    : scheme.onSurface.withValues(alpha: enabled ? 1 : 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
