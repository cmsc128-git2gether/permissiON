import 'package:material_ui/material_ui.dart';
import 'package:permission_app/theme/app_theme.dart';

enum BottomTab {
  home('Home', Icons.home_outlined, Icons.home),
  permits('My Permits', Icons.description_outlined, Icons.description),
  notifications('Notifications', Icons.notifications_outlined, Icons.notifications,
      enabled: false),
  profile('Profile', Icons.person_outline, Icons.person, enabled: false);

  const BottomTab(this.label, this.icon, this.activeIcon, {this.enabled = true});

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool enabled;
}

/// Home, My Permits, "+", Notifications, Profile.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
  });

  final BottomTab selected;
  final ValueChanged<BottomTab> onSelect;
  final VoidCallback onAdd;

  Widget _tab(BottomTab t) => Expanded(
        child: _TabItem(
          key: Key('tab-${t.name}'),
          tab: t,
          selected: t == selected,
          onTap: t.enabled ? () => onSelect(t) : null,
        ),
      );

  @override
  Widget build(BuildContext context) => Material(
        elevation: 8,
        color: AppColors.brandPink,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              _tab(BottomTab.home),
              _tab(BottomTab.permits),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    IconButton.filled(
                      key: const Key('tab-add'),
                      tooltip: 'File new permit',
                      onPressed: onAdd,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'File new permit',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ]),
                ),
              ),
              _tab(BottomTab.notifications),
              _tab(BottomTab.profile),
            ]),
          ),
        ),
      );
}

class _TabItem extends StatelessWidget {
  const _TabItem({super.key, required this.tab, required this.selected, required this.onTap});

  final BottomTab tab;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : tab.enabled
            ? AppColors.ink
            : AppColors.ink.withValues(alpha: 0.38);

    return Semantics(
      button: true,
      selected: selected,
      enabled: tab.enabled,
      label: tab.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(selected ? tab.activeIcon : tab.icon, color: color),
            const SizedBox(height: 2),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}