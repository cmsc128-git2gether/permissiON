import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/shell/app_bottom_bar.dart';
import 'package:permission_app/router/app_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final currentTab = BottomTab.values[navigationShell.currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text(currentTab.label)),
      body: navigationShell,
      bottomNavigationBar: AppBottomBar(
        selected: currentTab,
        onSelect: (tab) => navigationShell.goBranch(
          tab.index,
          initialLocation: tab.index == navigationShell.currentIndex,
        ),
        onAdd: () => context.push(AppRoutes.newPermit),
      ),
    );
  }
}
