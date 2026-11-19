import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../authentication/data/auth_repository.dart';

// Homepage for admin accounts
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthRepository().signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              key: const Key('open-permit-history'),
              leading: const Icon(Icons.history),
              title: const Text('Permit history'),
              subtitle: const Text('See every permit residents have filed'),
              trailing: const Icon(Icons.chevron_right),
              // push (not go) keeps the dashboard underneath, so the
              // history screen gets a back arrow
              onTap: () => context.push('/admin/permit-history'),
            ),
          ),
        ],
      ),
    );
  }
}