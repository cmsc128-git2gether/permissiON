import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app/router.dart';
import 'features/authentication/data/auth_repository.dart'; // adjust path
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Create instance of AuthRepository
  final authRepository = AuthRepository();

  // Broadcast so both the router and the refresh listener can listen
  final authStream = AuthRepository().authStateStream.asBroadcastStream();

  runApp(MyApp(router: createRouter(authStream, authRepository)));
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}
