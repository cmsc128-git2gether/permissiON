import 'package:flutter/material.dart';
import '../data/auth_repository.dart';

// Placeholder homepage for end_user accounts
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthRepository().signOut(),
          ),
        ],
      ),
      body: const Center(child: Text('Student Home')),
    );
  }
}
