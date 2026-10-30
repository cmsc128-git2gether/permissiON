import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app/router.dart';
import 'features/authentication/data/auth_repository.dart'; // adjust path
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // One notifier, it listens to the auth stream and feeds the router
  final auth = AuthNotifier(AuthRepository());
  final router = createRouter(auth);

  runApp(MyApp(router: router));
}

class MyApp extends StatelessWidget {

  const MyApp({super.key, required this.router});
  final GoRouter router;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}
